"""Milestone 1: prove the fetch/decode/execute loop and bit-addressable SFR
access work, using a tiny hand-encoded program (no assembler involved) that
blinks P1.0 - the "one virtual LED" milestone.

Program (see emulator/milestones/m1_blink_led.py for the annotated bytes):
    0x00  SETB P1.0
    0x02  MOV  R0,#0xFF
    0x04  DJNZ R0,0x04
    0x06  CLR  P1.0
    0x08  MOV  R0,#0xFF
    0x0A  DJNZ R0,0x0A
    0x0C  SJMP 0x00
"""

from emulator.cpu8051 import CPU8051, P1
from emulator.memory import MemoryBus
from emulator.milestones.m1_blink_led import PROGRAM


def make_cpu() -> CPU8051:
    bus = MemoryBus()
    bus.load_code(PROGRAM)
    return CPU8051(bus)


def led_on(cpu: CPU8051) -> bool:
    return bool(cpu.mem[P1] & 0x01)


def test_led_starts_off_and_turns_on_after_first_instruction():
    cpu = make_cpu()
    assert not led_on(cpu)
    cpu.step()  # SETB P1.0
    assert led_on(cpu)


def test_led_stays_on_through_the_delay_loop():
    cpu = make_cpu()
    for _ in range(257):  # SETB + MOV R0,#0xFF + 255 DJNZ iterations
        cpu.step()
    assert led_on(cpu)
    assert cpu.pc == 0x06  # about to execute CLR P1.0


def test_led_turns_off_then_back_on_over_a_full_cycle():
    cpu = make_cpu()
    for _ in range(258):
        cpu.step()
    assert not led_on(cpu)

    for _ in range(257):  # MOV R0,#0xFF + 255 DJNZ + SJMP
        cpu.step()
    assert cpu.pc == 0x00

    cpu.step()  # SETB P1.0 again
    assert led_on(cpu)
