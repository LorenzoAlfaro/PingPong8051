"""Chunk 3 (display half): decode the real ROM's column-scan writes into a
framebuffer, without pygame. LUT_PAD[1] = 0xF0 (rows 0-3 lit, PAD_SIZE=4) and
LUT_BALL[Y] has row_index = Y-1, both from 2018_PingPong.asm.
"""

from pathlib import Path

import pytest

from emulator.cpu8051 import CPU8051
from emulator.hardware_config import DIRECT_8x8
from emulator.hex_loader import load_program
from emulator.led_matrix import LedMatrixDisplay
from emulator.memory import MemoryBus

ROM_PATH = Path(__file__).resolve().parent.parent / "2018_PingPong.hex"
READ_PUERTO = 0x0046


def make_cpu() -> CPU8051:
    if not ROM_PATH.exists():
        pytest.skip(f"{ROM_PATH.name} not present (it's a local MCU8051IDE build artifact, not checked in)")
    bus = MemoryBus()
    bus.load_code(load_program(ROM_PATH))
    return CPU8051(bus)


def advance_one_frame(cpu: CPU8051, display: LedMatrixDisplay, max_steps: int = 200_000) -> None:
    cpu.step()
    display.sample(cpu)
    for _ in range(max_steps):
        if cpu.pc == READ_PUERTO:
            return
        cpu.step()
        display.sample(cpu)
    raise AssertionError(f"never got back to READ_PUERTO within {max_steps} steps")


def test_first_rendered_frame_shows_both_paddles_and_the_ball():
    cpu = make_cpu()
    display = LedMatrixDisplay(DIRECT_8x8)

    advance_one_frame(cpu, display)  # runs START's init, no GRAFICO yet
    advance_one_frame(cpu, display)  # first full loop body: ball ends at X=2,Y=2

    fb = display.framebuffer

    # Left paddle (PAD1=1) in column 0, rows 0-3 lit (LUT_PAD[1] = 0xF0).
    assert [fb[r][0] for r in range(8)] == [True, True, True, True, False, False, False, False]
    # Right paddle (PAD2=1) in the last column, same shape (LUT_PAD2[1]=0x00
    # for the low half, LUT_PAD[1] for the high half - PAD2 also starts at 1).
    assert [fb[r][7] for r in range(8)] == [True, True, True, True, False, False, False, False]
    # Ball at X=2, Y=2 -> column 2, row_index = Y-1 = 1.
    assert fb[1][2] is True
    assert sum(1 for r in range(8) if fb[r][2]) == 1
