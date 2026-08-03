"""Decodes the column/row SFR writes the game does every scan pass into a
live framebuffer. No frame-boundary or blanking logic: the game already
redraws every column each game-loop iteration (CLEAR_VIDEO_MEMORY +
WRITE_VIDEO_MEMORY + WRITE_TO_PPI run once per pass), so the framebuffer is
simply whatever the last full scan wrote - accurate enough without needing
to model the real multiplexed/persistence-of-vision timing.

`sample()` must be called after *every* CPU instruction (not just once per
frame) because the column and row SFRs are briefly set correctly together
many times during a single scan, once per column, and are cleared in
between - polling only at frame boundaries would only ever see the last
column.
"""

from __future__ import annotations

from .hardware_config import HardwareConfig


class LedMatrixDisplay:
    def __init__(self, config: HardwareConfig):
        self.config = config
        self.framebuffer = [[False] * config.cols for _ in range(config.rows)]

    def sample(self, cpu) -> None:
        mask = cpu.mem[self.config.column_port]
        if mask == 0xFF:
            return  # no column selected right now (mid-clear between writes)

        zero_bit = None
        for p in range(8):
            if not (mask >> p) & 1:
                zero_bit = p
                break
        if zero_bit is None:
            return

        col = 7 - zero_bit
        if not (0 <= col < self.config.cols):
            return

        row_byte = cpu.mem[self.config.row_port]
        rows = self.config.rows
        fb = self.framebuffer
        for row_index in range(rows):
            bit_pos = rows - 1 - row_index
            fb[row_index][col] = bool((row_byte >> bit_pos) & 1)
