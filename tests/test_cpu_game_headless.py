"""Chunk 2: run the real compiled game ROM (2018_PingPong.hex, produced by
MCU8051IDE from 2018_PingPong.asm - not by anything in this repo) through
the CPU core with no display attached, and check known RAM state from the
source to prove the ISA subset this program actually uses is implemented
correctly.

Address map, from 2018_PingPong.asm / 2018_PingPong.lst:
    PAD1 = 0x20, PAD2 = 0x21, X = 0x22, Y = 0x23 (direct RAM)
    UL = 0x49 (a *bit* address -> lives in byte 0x29, bit 1)
    P1  = 0x90 (SFR) is the switch input port (SW)
    READ_PUERTO (top of the main loop) starts at code address 0x0046
"""

from pathlib import Path

import pytest

from emulator.cpu8051 import CPU8051
from emulator.hex_loader import load_program
from emulator.memory import MemoryBus

ROM_PATH = Path(__file__).resolve().parent.parent / "2018_PingPong.hex"

PAD1, PAD2, X, Y = 0x20, 0x21, 0x22, 0x23
READ_PUERTO = 0x0046
DOWN_1_BIT = 0x91  # P1.1


def make_cpu() -> CPU8051:
    if not ROM_PATH.exists():
        pytest.skip(f"{ROM_PATH.name} not present (it's a local MCU8051IDE build artifact, not checked in)")
    bus = MemoryBus()
    bus.load_code(load_program(ROM_PATH))
    return CPU8051(bus)


def advance_one_frame(cpu: CPU8051, max_steps: int = 200_000) -> None:
    """Step forward until the *next* time the main loop reaches READ_PUERTO,
    guaranteeing at least one instruction executes even if the CPU is
    already sitting on READ_PUERTO (so repeated calls each advance exactly
    one full game-loop iteration, regardless of where they're called from).
    """
    cpu.step()
    for _ in range(max_steps):
        if cpu.pc == READ_PUERTO:
            return
        cpu.step()
    raise AssertionError(f"never got back to READ_PUERTO within {max_steps} steps")


def test_initial_state_matches_the_source():
    cpu = make_cpu()
    advance_one_frame(cpu)  # runs START's init code, stops at the first loop top
    assert cpu.mem[PAD1] == 1
    assert cpu.mem[PAD2] == 1
    assert cpu.mem[X] == 3
    assert cpu.mem[Y] == 3
    assert cpu.get_bit(0x49) == 1  # UL (ball heading up-left) set by START


def test_ball_moves_up_left_each_frame_with_no_input():
    cpu = make_cpu()
    advance_one_frame(cpu)
    advance_one_frame(cpu)
    assert (cpu.mem[X], cpu.mem[Y]) == (2, 2)
    advance_one_frame(cpu)
    assert (cpu.mem[X], cpu.mem[Y]) == (1, 1)


def test_down_input_moves_pad1():
    cpu = make_cpu()
    advance_one_frame(cpu)
    assert cpu.mem[PAD1] == 1

    cpu.set_bit(DOWN_1_BIT, 1)  # hold "down" for player 1
    advance_one_frame(cpu)
    assert cpu.mem[PAD1] == 2
    # Note: holding DOWN from a cold start does *not* organically climb all
    # the way to PAD_DN_LIMIT here - with PAD1 starting at 1 the paddle
    # can't outrun the ball to X=1 before it exits at the left border and
    # LOST resets the game (this is real behavior of the compiled program,
    # not an emulator quirk - see test_pad1_stays_at_its_down_limit below
    # for a direct check of the clamp itself).


def test_pad1_stays_at_its_down_limit():
    # PAD_DN_LIMIT = TAM_Y - PAD_SIZE = 9 - 4 = 5. Poke a mid-life, no-danger
    # ball state (matches START's own X=3,Y=3,UL=1) alongside PAD1 sitting
    # one below the limit, so a single frame's PAD1_UP_DOWN update can be
    # checked in isolation from ball-collision/reset side effects.
    cpu = make_cpu()
    advance_one_frame(cpu)
    cpu.set_bit(DOWN_1_BIT, 1)

    cpu.mem[PAD1], cpu.mem[X], cpu.mem[Y] = 4, 3, 3
    advance_one_frame(cpu)
    assert cpu.mem[PAD1] == 5

    cpu.mem[PAD1], cpu.mem[X], cpu.mem[Y] = 5, 3, 3
    advance_one_frame(cpu)
    assert cpu.mem[PAD1] == 5  # PAD_P only skips the increment when already == LIMIT
