"""External memory bus for the emulated 8051: code space and xdata space.

Internal RAM/SFRs live on the CPU itself (emulator.cpu8051.CPU8051); this
module only models what the 8051 reaches through MOVX (xdata, 64K) and code
fetches/MOVC (code, 64K). Peripherals (e.g. an 8255 PPI) attach to xdata by
claiming an address range with a read/write hook.
"""

from __future__ import annotations

from typing import Callable, Optional


class MemoryBus:
    def __init__(self, code_size: int = 0x10000, xdata_size: int = 0x10000):
        self.code = bytearray(code_size)
        self.xdata = bytearray(xdata_size)
        # Each hook: (start, end_inclusive, read_fn(addr)->int, write_fn(addr,val))
        self._hooks: list[tuple[int, int, Optional[Callable[[int], int]], Optional[Callable[[int, int], None]]]] = []

    def load_code(self, data: bytes, origin: int = 0) -> None:
        end = origin + len(data)
        if end > len(self.code):
            raise ValueError(f"program (origin=0x{origin:X}, len={len(data)}) does not fit in code space")
        self.code[origin:end] = data

    def read_code(self, addr: int) -> int:
        return self.code[addr & 0xFFFF]

    def add_xdata_hook(
        self,
        start: int,
        end_inclusive: int,
        read_fn: Optional[Callable[[int], int]],
        write_fn: Optional[Callable[[int, int], None]],
    ) -> None:
        self._hooks.append((start, end_inclusive, read_fn, write_fn))

    def read_xdata(self, addr: int) -> int:
        addr &= 0xFFFF
        for start, end, read_fn, _ in self._hooks:
            if start <= addr <= end and read_fn is not None:
                return read_fn(addr) & 0xFF
        return self.xdata[addr]

    def write_xdata(self, addr: int, value: int) -> None:
        addr &= 0xFFFF
        value &= 0xFF
        for start, end, _, write_fn in self._hooks:
            if start <= addr <= end and write_fn is not None:
                write_fn(addr, value)
                return
        self.xdata[addr] = value
