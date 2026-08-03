"""A pragmatic 8051 CPU core: enough of the real instruction set and register
model to run compiled 8051 assembly, without timer/interrupt hardware that
this project's game code never uses.

Internal RAM (0x00-0xFF) and the SFRs this program touches (P0-P3, SP, DPTR,
PSW, ACC, B) live in one flat byte array, `mem`, matching how direct
addressing already treats them in real 8051 hardware. Indirect (@Ri) and
stack (PUSH/POP via SP) access reuse the same array; this is a simplification
real 8052-class parts also make for the low 128 bytes, and nothing in this
program pushes/pops or indirects into SFR space, so it's harmless here.
"""

from __future__ import annotations

from .memory import MemoryBus

P0 = 0x80
SP = 0x81
DPL = 0x82
DPH = 0x83
P1 = 0x90
PSW = 0xD0
ACC = 0xE0
B = 0xF0
P2 = 0xA0
P3 = 0xB0

CY = 0x80
AC = 0x40
F0 = 0x20
OV = 0x04


def _signed8(value: int) -> int:
    return value - 256 if value >= 128 else value


class CPU8051:
    def __init__(self, bus: MemoryBus):
        self.bus = bus
        self.mem = bytearray(256)
        self.mem[SP] = 0x07
        self.pc = 0

    # -- register bank / addressing helpers -------------------------------

    def _bank_base(self) -> int:
        return ((self.mem[PSW] >> 3) & 0x03) * 8

    def get_r(self, n: int) -> int:
        return self.mem[self._bank_base() + n]

    def set_r(self, n: int, value: int) -> None:
        self.mem[self._bank_base() + n] = value & 0xFF

    def read_indirect(self, ri: int) -> int:
        return self.mem[self.get_r(ri)]

    def write_indirect(self, ri: int, value: int) -> None:
        self.mem[self.get_r(ri)] = value & 0xFF

    @staticmethod
    def _bit_addr(bitnum: int) -> tuple[int, int]:
        if bitnum >= 0x80:
            return bitnum & 0xF8, bitnum & 0x07
        return 0x20 + (bitnum // 8), bitnum % 8

    def get_bit(self, bitnum: int) -> int:
        byte_addr, bit = self._bit_addr(bitnum)
        return (self.mem[byte_addr] >> bit) & 1

    def set_bit(self, bitnum: int, value: int) -> None:
        byte_addr, bit = self._bit_addr(bitnum)
        if value:
            self.mem[byte_addr] |= 1 << bit
        else:
            self.mem[byte_addr] &= ~(1 << bit) & 0xFF

    def get_flag(self, mask: int) -> int:
        return 1 if self.mem[PSW] & mask else 0

    def set_flag(self, mask: int, value: int) -> None:
        if value:
            self.mem[PSW] |= mask
        else:
            self.mem[PSW] &= ~mask & 0xFF

    def get_dptr(self) -> int:
        return (self.mem[DPH] << 8) | self.mem[DPL]

    def set_dptr(self, value: int) -> None:
        value &= 0xFFFF
        self.mem[DPH] = value >> 8
        self.mem[DPL] = value & 0xFF

    # -- stack --------------------------------------------------------------

    def push(self, value: int) -> None:
        sp = (self.mem[SP] + 1) & 0xFF
        self.mem[SP] = sp
        self.mem[sp] = value & 0xFF

    def pop(self) -> int:
        sp = self.mem[SP]
        value = self.mem[sp]
        self.mem[SP] = (sp - 1) & 0xFF
        return value

    # -- fetch / jump helpers ------------------------------------------------

    def _fetch(self) -> int:
        b = self.bus.read_code(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return b

    def _rel_jump(self, rel: int) -> None:
        self.pc = (self.pc + _signed8(rel)) & 0xFFFF

    def _ajmp_acall_addr11(self, opcode: int, low_byte: int) -> int:
        return ((opcode & 0xE0) << 3) | low_byte

    def _call(self, target: int) -> None:
        ret = self.pc
        self.push(ret & 0xFF)
        self.push((ret >> 8) & 0xFF)
        self.pc = target & 0xFFFF

    def _ret(self) -> None:
        hi = self.pop()
        lo = self.pop()
        self.pc = ((hi << 8) | lo) & 0xFFFF

    # -- arithmetic -----------------------------------------------------------

    def _add(self, operand: int, carry_in: int = 0) -> None:
        a = self.mem[ACC]
        total = a + operand + carry_in
        result = total & 0xFF
        cy = 1 if total > 0xFF else 0
        ac = 1 if (a & 0x0F) + (operand & 0x0F) + carry_in > 0x0F else 0
        ov = 1 if (((a ^ operand) & 0x80) == 0) and (((a ^ result) & 0x80) != 0) else 0
        self.mem[ACC] = result
        self.set_flag(CY, cy)
        self.set_flag(AC, ac)
        self.set_flag(OV, ov)

    def _subb(self, operand: int) -> None:
        a = self.mem[ACC]
        cy = self.get_flag(CY)
        total = a - operand - cy
        result = total & 0xFF
        borrow = 1 if total < 0 else 0
        ac = 1 if (a & 0x0F) - (operand & 0x0F) - cy < 0 else 0
        ov = 1 if (((a ^ operand) & 0x80) != 0) and (((a ^ result) & 0x80) != 0) else 0
        self.mem[ACC] = result
        self.set_flag(CY, borrow)
        self.set_flag(AC, ac)
        self.set_flag(OV, ov)

    # -- main loop ------------------------------------------------------------

    def step(self) -> None:
        op = self._fetch()

        # Fixed single-purpose opcodes handled first.
        if op == 0x00:  # NOP
            return
        if op == 0x02:  # LJMP addr16
            hi, lo = self._fetch(), self._fetch()
            self.pc = (hi << 8) | lo
            return
        if op == 0x03:  # RR A
            a = self.mem[ACC]
            self.mem[ACC] = ((a >> 1) | ((a & 1) << 7)) & 0xFF
            return
        if op == 0x04:  # INC A
            self.mem[ACC] = (self.mem[ACC] + 1) & 0xFF
            return
        if op == 0x05:  # INC direct
            addr = self._fetch()
            self.mem[addr] = (self.mem[addr] + 1) & 0xFF
            return
        if op == 0x10:  # JBC bit, rel
            bit, rel = self._fetch(), self._fetch()
            if self.get_bit(bit):
                self.set_bit(bit, 0)
                self._rel_jump(rel)
            return
        if op == 0x12:  # LCALL addr16
            hi, lo = self._fetch(), self._fetch()
            self._call((hi << 8) | lo)
            return
        if op == 0x13:  # RRC A
            a = self.mem[ACC]
            old_cy = self.get_flag(CY)
            self.set_flag(CY, a & 1)
            self.mem[ACC] = ((a >> 1) | (old_cy << 7)) & 0xFF
            return
        if op == 0x14:  # DEC A
            self.mem[ACC] = (self.mem[ACC] - 1) & 0xFF
            return
        if op == 0x15:  # DEC direct
            addr = self._fetch()
            self.mem[addr] = (self.mem[addr] - 1) & 0xFF
            return
        if op == 0x20:  # JB bit, rel
            bit, rel = self._fetch(), self._fetch()
            if self.get_bit(bit):
                self._rel_jump(rel)
            return
        if op == 0x22 or op == 0x32:  # RET / RETI
            self._ret()
            return
        if op == 0x23:  # RL A
            a = self.mem[ACC]
            self.mem[ACC] = ((a << 1) | (a >> 7)) & 0xFF
            return
        if op == 0x24:  # ADD A,#data
            self._add(self._fetch())
            return
        if op == 0x25:  # ADD A,direct
            self._add(self.mem[self._fetch()])
            return
        if op == 0x30:  # JNB bit, rel
            bit, rel = self._fetch(), self._fetch()
            if not self.get_bit(bit):
                self._rel_jump(rel)
            return
        if op == 0x33:  # RLC A
            a = self.mem[ACC]
            old_cy = self.get_flag(CY)
            self.set_flag(CY, (a >> 7) & 1)
            self.mem[ACC] = ((a << 1) | old_cy) & 0xFF
            return
        if op == 0x34:  # ADDC A,#data
            self._add(self._fetch(), self.get_flag(CY))
            return
        if op == 0x35:  # ADDC A,direct
            self._add(self.mem[self._fetch()], self.get_flag(CY))
            return
        if op == 0x40:  # JC rel
            rel = self._fetch()
            if self.get_flag(CY):
                self._rel_jump(rel)
            return
        if op == 0x42:  # ORL direct,A
            addr = self._fetch()
            self.mem[addr] |= self.mem[ACC]
            return
        if op == 0x43:  # ORL direct,#data
            addr = self._fetch()
            data = self._fetch()
            self.mem[addr] |= data
            return
        if op == 0x44:  # ORL A,#data
            self.mem[ACC] |= self._fetch()
            return
        if op == 0x45:  # ORL A,direct
            self.mem[ACC] |= self.mem[self._fetch()]
            return
        if op == 0x50:  # JNC rel
            rel = self._fetch()
            if not self.get_flag(CY):
                self._rel_jump(rel)
            return
        if op == 0x52:  # ANL direct,A
            addr = self._fetch()
            self.mem[addr] &= self.mem[ACC]
            return
        if op == 0x53:  # ANL direct,#data
            addr = self._fetch()
            data = self._fetch()
            self.mem[addr] &= data
            return
        if op == 0x54:  # ANL A,#data
            self.mem[ACC] &= self._fetch()
            return
        if op == 0x55:  # ANL A,direct
            self.mem[ACC] &= self.mem[self._fetch()]
            return
        if op == 0x60:  # JZ rel
            rel = self._fetch()
            if self.mem[ACC] == 0:
                self._rel_jump(rel)
            return
        if op == 0x62:  # XRL direct,A
            addr = self._fetch()
            self.mem[addr] ^= self.mem[ACC]
            return
        if op == 0x63:  # XRL direct,#data
            addr = self._fetch()
            data = self._fetch()
            self.mem[addr] ^= data
            return
        if op == 0x64:  # XRL A,#data
            self.mem[ACC] ^= self._fetch()
            return
        if op == 0x65:  # XRL A,direct
            self.mem[ACC] ^= self.mem[self._fetch()]
            return
        if op == 0x70:  # JNZ rel
            rel = self._fetch()
            if self.mem[ACC] != 0:
                self._rel_jump(rel)
            return
        if op == 0x72:  # ORL C,bit
            bit = self._fetch()
            self.set_flag(CY, self.get_flag(CY) | self.get_bit(bit))
            return
        if op == 0x73:  # JMP @A+DPTR
            self.pc = (self.get_dptr() + self.mem[ACC]) & 0xFFFF
            return
        if op == 0x74:  # MOV A,#data
            self.mem[ACC] = self._fetch()
            return
        if op == 0x75:  # MOV direct,#data
            addr = self._fetch()
            data = self._fetch()
            self.mem[addr] = data
            return
        if op == 0x80:  # SJMP rel
            rel = self._fetch()
            self._rel_jump(rel)
            return
        if op == 0x82:  # ANL C,bit
            bit = self._fetch()
            self.set_flag(CY, self.get_flag(CY) & self.get_bit(bit))
            return
        if op == 0x83:  # MOVC A,@A+PC
            addr = (self.pc + self.mem[ACC]) & 0xFFFF
            self.mem[ACC] = self.bus.read_code(addr)
            return
        if op == 0x84:  # DIV AB
            a, b_val = self.mem[ACC], self.mem[B]
            if b_val == 0:
                self.set_flag(OV, 1)
            else:
                self.mem[ACC] = (a // b_val) & 0xFF
                self.mem[B] = (a % b_val) & 0xFF
                self.set_flag(OV, 0)
            self.set_flag(CY, 0)
            return
        if op == 0x85:  # MOV direct,direct (src byte fetched first, then dest)
            src_addr = self._fetch()
            dest_addr = self._fetch()
            self.mem[dest_addr] = self.mem[src_addr]
            return
        if op == 0x90:  # MOV DPTR,#data16
            hi, lo = self._fetch(), self._fetch()
            self.set_dptr((hi << 8) | lo)
            return
        if op == 0x92:  # MOV bit,C
            bit = self._fetch()
            self.set_bit(bit, self.get_flag(CY))
            return
        if op == 0x93:  # MOVC A,@A+DPTR
            addr = (self.get_dptr() + self.mem[ACC]) & 0xFFFF
            self.mem[ACC] = self.bus.read_code(addr)
            return
        if op == 0x94:  # SUBB A,#data
            self._subb(self._fetch())
            return
        if op == 0x95:  # SUBB A,direct
            self._subb(self.mem[self._fetch()])
            return
        if op == 0xA0:  # ORL C,/bit
            bit = self._fetch()
            self.set_flag(CY, self.get_flag(CY) | (0 if self.get_bit(bit) else 1))
            return
        if op == 0xA2:  # MOV C,bit
            bit = self._fetch()
            self.set_flag(CY, self.get_bit(bit))
            return
        if op == 0xA3:  # INC DPTR
            self.set_dptr((self.get_dptr() + 1) & 0xFFFF)
            return
        if op == 0xA4:  # MUL AB
            a, b_val = self.mem[ACC], self.mem[B]
            product = a * b_val
            self.mem[ACC] = product & 0xFF
            self.mem[B] = (product >> 8) & 0xFF
            self.set_flag(OV, 1 if product > 0xFF else 0)
            self.set_flag(CY, 0)
            return
        if op == 0xB0:  # ANL C,/bit
            bit = self._fetch()
            self.set_flag(CY, self.get_flag(CY) & (0 if self.get_bit(bit) else 1))
            return
        if op == 0xB2:  # CPL bit
            bit = self._fetch()
            self.set_bit(bit, 0 if self.get_bit(bit) else 1)
            return
        if op == 0xB3:  # CPL C
            self.set_flag(CY, 0 if self.get_flag(CY) else 1)
            return
        if op == 0xB4:  # CJNE A,#data,rel
            data, rel = self._fetch(), self._fetch()
            a = self.mem[ACC]
            self.set_flag(CY, 1 if a < data else 0)
            if a != data:
                self._rel_jump(rel)
            return
        if op == 0xB5:  # CJNE A,direct,rel
            addr, rel = self._fetch(), self._fetch()
            a, val = self.mem[ACC], self.mem[addr]
            self.set_flag(CY, 1 if a < val else 0)
            if a != val:
                self._rel_jump(rel)
            return
        if op == 0xC0:  # PUSH direct
            self.push(self.mem[self._fetch()])
            return
        if op == 0xC2:  # CLR bit
            self.set_bit(self._fetch(), 0)
            return
        if op == 0xC3:  # CLR C
            self.set_flag(CY, 0)
            return
        if op == 0xC4:  # SWAP A
            a = self.mem[ACC]
            self.mem[ACC] = ((a << 4) | (a >> 4)) & 0xFF
            return
        if op == 0xC5:  # XCH A,direct
            addr = self._fetch()
            self.mem[ACC], self.mem[addr] = self.mem[addr], self.mem[ACC]
            return
        if op == 0xD0:  # POP direct
            self.mem[self._fetch()] = self.pop()
            return
        if op == 0xD2:  # SETB bit
            self.set_bit(self._fetch(), 1)
            return
        if op == 0xD3:  # SETB C
            self.set_flag(CY, 1)
            return
        if op == 0xD4:  # DA A (decimal adjust; unused by this game, best-effort)
            a = self.mem[ACC]
            cy = self.get_flag(CY)
            if (a & 0x0F) > 9 or self.get_flag(AC):
                a += 0x06
            if a > 0xFF:
                cy = 1
                a &= 0xFF
            if (a >> 4) > 9 or cy:
                a += 0x60
                cy = 1
            self.mem[ACC] = a & 0xFF
            self.set_flag(CY, cy)
            return
        if op == 0xD5:  # DJNZ direct,rel
            addr, rel = self._fetch(), self._fetch()
            self.mem[addr] = (self.mem[addr] - 1) & 0xFF
            if self.mem[addr] != 0:
                self._rel_jump(rel)
            return
        if op == 0xE0:  # MOVX A,@DPTR
            self.mem[ACC] = self.bus.read_xdata(self.get_dptr())
            return
        if op == 0xE4:  # CLR A
            self.mem[ACC] = 0
            return
        if op == 0xE5:  # MOV A,direct
            self.mem[ACC] = self.mem[self._fetch()]
            return
        if op == 0xF0:  # MOVX @DPTR,A
            self.bus.write_xdata(self.get_dptr(), self.mem[ACC])
            return
        if op == 0xF4:  # CPL A
            self.mem[ACC] = (~self.mem[ACC]) & 0xFF
            return
        if op == 0xF5:  # MOV direct,A
            self.mem[self._fetch()] = self.mem[ACC]
            return

        # Register/page-encoded families: opcode's low bits select Rn, @Ri or
        # an AJMP/ACALL page number.
        low3 = op & 0x07
        low1 = op & 0x01

        if (op & 0x1F) == 0x01:  # AJMP page0-7 (a10a9a8 00001)
            low_byte = self._fetch()
            self.pc = self._ajmp_acall_addr11(op, low_byte)
            return
        if (op & 0x1F) == 0x11:  # ACALL page0-7 (a10a9a8 10001)
            low_byte = self._fetch()
            target = self._ajmp_acall_addr11(op, low_byte)
            self._call(target)
            return

        if 0x06 <= op <= 0x07:  # INC @Ri
            self.write_indirect(low1, (self.read_indirect(low1) + 1) & 0xFF)
            return
        if 0x08 <= op <= 0x0F:  # INC Rn
            self.set_r(low3, (self.get_r(low3) + 1) & 0xFF)
            return
        if 0x16 <= op <= 0x17:  # DEC @Ri
            self.write_indirect(low1, (self.read_indirect(low1) - 1) & 0xFF)
            return
        if 0x18 <= op <= 0x1F:  # DEC Rn
            self.set_r(low3, (self.get_r(low3) - 1) & 0xFF)
            return
        if 0x26 <= op <= 0x27:  # ADD A,@Ri
            self._add(self.read_indirect(low1))
            return
        if 0x28 <= op <= 0x2F:  # ADD A,Rn
            self._add(self.get_r(low3))
            return
        if 0x36 <= op <= 0x37:  # ADDC A,@Ri
            self._add(self.read_indirect(low1), self.get_flag(CY))
            return
        if 0x38 <= op <= 0x3F:  # ADDC A,Rn
            self._add(self.get_r(low3), self.get_flag(CY))
            return
        if 0x46 <= op <= 0x47:  # ORL A,@Ri
            self.mem[ACC] |= self.read_indirect(low1)
            return
        if 0x48 <= op <= 0x4F:  # ORL A,Rn
            self.mem[ACC] |= self.get_r(low3)
            return
        if 0x56 <= op <= 0x57:  # ANL A,@Ri
            self.mem[ACC] &= self.read_indirect(low1)
            return
        if 0x58 <= op <= 0x5F:  # ANL A,Rn
            self.mem[ACC] &= self.get_r(low3)
            return
        if 0x66 <= op <= 0x67:  # XRL A,@Ri
            self.mem[ACC] ^= self.read_indirect(low1)
            return
        if 0x68 <= op <= 0x6F:  # XRL A,Rn
            self.mem[ACC] ^= self.get_r(low3)
            return
        if 0x76 <= op <= 0x77:  # MOV @Ri,#data
            self.write_indirect(low1, self._fetch())
            return
        if 0x78 <= op <= 0x7F:  # MOV Rn,#data
            self.set_r(low3, self._fetch())
            return
        if 0x86 <= op <= 0x87:  # MOV direct,@Ri
            addr = self._fetch()
            self.mem[addr] = self.read_indirect(low1)
            return
        if 0x88 <= op <= 0x8F:  # MOV direct,Rn
            addr = self._fetch()
            self.mem[addr] = self.get_r(low3)
            return
        if 0x96 <= op <= 0x97:  # SUBB A,@Ri
            self._subb(self.read_indirect(low1))
            return
        if 0x98 <= op <= 0x9F:  # SUBB A,Rn
            self._subb(self.get_r(low3))
            return
        if 0xA6 <= op <= 0xA7:  # MOV @Ri,direct
            addr = self._fetch()
            self.write_indirect(low1, self.mem[addr])
            return
        if 0xA8 <= op <= 0xAF:  # MOV Rn,direct
            addr = self._fetch()
            self.set_r(low3, self.mem[addr])
            return
        if 0xB6 <= op <= 0xB7:  # CJNE @Ri,#data,rel
            data, rel = self._fetch(), self._fetch()
            val = self.read_indirect(low1)
            self.set_flag(CY, 1 if val < data else 0)
            if val != data:
                self._rel_jump(rel)
            return
        if 0xB8 <= op <= 0xBF:  # CJNE Rn,#data,rel
            data, rel = self._fetch(), self._fetch()
            val = self.get_r(low3)
            self.set_flag(CY, 1 if val < data else 0)
            if val != data:
                self._rel_jump(rel)
            return
        if 0xC6 <= op <= 0xC7:  # XCH A,@Ri
            addr = self.get_r(low1)
            self.mem[ACC], self.mem[addr] = self.mem[addr], self.mem[ACC]
            return
        if 0xC8 <= op <= 0xCF:  # XCH A,Rn
            val = self.get_r(low3)
            self.set_r(low3, self.mem[ACC])
            self.mem[ACC] = val
            return
        if 0xD6 <= op <= 0xD7:  # XCHD A,@Ri
            addr = self.get_r(low1)
            a, m = self.mem[ACC], self.mem[addr]
            self.mem[ACC] = (a & 0xF0) | (m & 0x0F)
            self.mem[addr] = (m & 0xF0) | (a & 0x0F)
            return
        if 0xD8 <= op <= 0xDF:  # DJNZ Rn,rel
            val = (self.get_r(low3) - 1) & 0xFF
            self.set_r(low3, val)
            rel = self._fetch()
            if val != 0:
                self._rel_jump(rel)
            return
        if 0xE2 <= op <= 0xE3:  # MOVX A,@Ri
            self.mem[ACC] = self.bus.read_xdata(self.get_r(low1))
            return
        if 0xE6 <= op <= 0xE7:  # MOV A,@Ri
            self.mem[ACC] = self.read_indirect(low1)
            return
        if 0xE8 <= op <= 0xEF:  # MOV A,Rn
            self.mem[ACC] = self.get_r(low3)
            return
        if 0xF2 <= op <= 0xF3:  # MOVX @Ri,A
            self.bus.write_xdata(self.get_r(low1), self.mem[ACC])
            return
        if 0xF6 <= op <= 0xF7:  # MOV @Ri,A
            self.write_indirect(low1, self.mem[ACC])
            return
        if 0xF8 <= op <= 0xFF:  # MOV Rn,A
            self.set_r(low3, self.mem[ACC])
            return

        raise NotImplementedError(f"Unimplemented opcode 0x{op:02X} at 0x{(self.pc - 1) & 0xFFFF:04X}")
