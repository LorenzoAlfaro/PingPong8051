"""Wiring description for a hardware variant: which SFRs the column/row/input
lines land on and how keyboard keys map to the switch-input bits. Kept
pygame-free so it (and anything that only needs to know the wiring, like
led_matrix.py) can be used from headless tests.

DIRECT_8x8 matches the current 2018_PingPong.asm / 2018_PingPong.hex: it was
rewritten to talk to MCU8051IDE's built-in 8x8 "LED Matrix" and "Simple
Keypad" virtual components straight through 8051 ports instead of through
the original PPI (see LED Matrix.vhc / PAD_Controls.vhc). Column select on
P0 is an active-low one-hot mask that starts at 0111_1111 and rotates right
once per column (see WRITE_TO_PPI in graphfunctions.asm), so column index i
(0-based, matching the MEMORIAVIDEO offset order) is the column whose P0
value has its zero bit at position (7 - i). The row byte on P2 packs row
index r (0-based) at bit position (rows - 1 - r), matching LUT_BALL/LUT_PAD
(e.g. Y=1 -> bit 7).
"""

from __future__ import annotations

from dataclasses import dataclass

from .cpu8051 import P0, P1, P2


@dataclass(frozen=True)
class KeyBindings:
    p1_up: str
    p1_down: str
    p2_up: str
    p2_down: str


@dataclass(frozen=True)
class HardwareConfig:
    name: str
    cols: int
    rows: int
    column_port: int
    row_port: int
    input_port: int
    up1_bit: int
    down1_bit: int
    up2_bit: int
    down2_bit: int
    key_bindings: KeyBindings


DIRECT_8x8 = HardwareConfig(
    name="direct_8x8",
    cols=8,
    rows=8,
    column_port=P0,
    row_port=P2,
    input_port=P1,
    up1_bit=0,
    down1_bit=1,
    up2_bit=2,
    down2_bit=3,
    key_bindings=KeyBindings(p1_up="w", p1_down="s", p2_up="up", p2_down="down"),
)
