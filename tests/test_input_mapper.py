"""Chunk 3 (input half): a button held only briefly must still read back as
pressed for a few frames afterward, or the CPU (which only samples the
switch-input port once per game-loop iteration) can miss a quick tap
entirely if it lands between two of its reads. See input_mapper.py.
"""

from collections import defaultdict

import pygame

from emulator.cpu8051 import CPU8051
from emulator.hardware_config import DIRECT_8x8
from emulator.input_mapper import InputMapper
from emulator.memory import MemoryBus

UP_1_BIT_MASK = 1 << DIRECT_8x8.up1_bit
DOWN_2_BIT_MASK = 1 << DIRECT_8x8.down2_bit


def make_cpu() -> CPU8051:
    return CPU8051(MemoryBus())


def no_keys_down() -> defaultdict:
    return defaultdict(bool)


def test_a_single_frame_tap_stays_latched_for_min_hold_frames():
    cpu = make_cpu()
    mapper = InputMapper(DIRECT_8x8, min_hold_frames=4)

    pressed = no_keys_down()
    pressed[pygame.K_w] = True  # p1_up
    mapper.apply(cpu, pressed)
    assert cpu.mem[DIRECT_8x8.input_port] & UP_1_BIT_MASK

    pressed = no_keys_down()  # key released on every subsequent frame
    for _ in range(3):
        mapper.apply(cpu, pressed)
        assert cpu.mem[DIRECT_8x8.input_port] & UP_1_BIT_MASK, "should still be latched"

    mapper.apply(cpu, pressed)
    assert not (cpu.mem[DIRECT_8x8.input_port] & UP_1_BIT_MASK), "latch should have expired"


def test_holding_the_key_keeps_it_pressed_indefinitely():
    cpu = make_cpu()
    mapper = InputMapper(DIRECT_8x8, min_hold_frames=4)

    pressed = no_keys_down()
    pressed[pygame.K_w] = True
    for _ in range(20):
        mapper.apply(cpu, pressed)
        assert cpu.mem[DIRECT_8x8.input_port] & UP_1_BIT_MASK


def test_buttons_are_tracked_independently():
    cpu = make_cpu()
    mapper = InputMapper(DIRECT_8x8, min_hold_frames=4)

    pressed = no_keys_down()
    pressed[pygame.K_w] = True  # p1_up only
    mapper.apply(cpu, pressed)

    value = cpu.mem[DIRECT_8x8.input_port]
    assert value & UP_1_BIT_MASK
    assert not (value & DOWN_2_BIT_MASK)
