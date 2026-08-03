"""Keyboard -> switch-input SFR, active-high (idle=0, pressed=1). Traced from
PAD1_UP_DOWN in 2018_PingPong.asm: the jb/jnb logic there only makes sense
(up decrements the pad, down increments it) if a press reads back as 1.

The game only reads this port once per game-loop iteration ("mov A,SW" at
the top of READ_PUERTO), and at low --speed settings that's many rendered
frames apart. A plain per-frame poll of pygame.key.get_pressed() can
therefore miss a quick tap entirely if it happens to fall between two of the
CPU's actual reads. To avoid that, each button is stretched to stay
"pressed" for at least `min_hold_frames` frames after it's seen down, which
should be set to comfortably more than one game-loop iteration's worth of
frames at the configured speed - see PygameFrontend._min_hold_frames.
"""

from __future__ import annotations

from typing import Sequence

import pygame

from .hardware_config import HardwareConfig

_KEY_NAME_TO_PYGAME = {
    "w": pygame.K_w,
    "a": pygame.K_a,
    "s": pygame.K_s,
    "d": pygame.K_d,
    "up": pygame.K_UP,
    "down": pygame.K_DOWN,
    "left": pygame.K_LEFT,
    "right": pygame.K_RIGHT,
}

_ACTIONS = ("p1_up", "p1_down", "p2_up", "p2_down")
_BIT_ATTRS = {"p1_up": "up1_bit", "p1_down": "down1_bit", "p2_up": "up2_bit", "p2_down": "down2_bit"}


class InputMapper:
    def __init__(self, config: HardwareConfig, min_hold_frames: int = 4):
        self.config = config
        self.min_hold_frames = min_hold_frames
        self._hold_counters = {action: 0 for action in _ACTIONS}

    def apply(self, cpu, pressed: Sequence[bool] | None = None) -> None:
        if pressed is None:
            pressed = pygame.key.get_pressed()
        kb = self.config.key_bindings
        key_names = {"p1_up": kb.p1_up, "p1_down": kb.p1_down, "p2_up": kb.p2_up, "p2_down": kb.p2_down}

        value = 0
        for action in _ACTIONS:
            if pressed[_KEY_NAME_TO_PYGAME[key_names[action]]]:
                self._hold_counters[action] = self.min_hold_frames
            elif self._hold_counters[action] > 0:
                self._hold_counters[action] -= 1

            if self._hold_counters[action] > 0:
                value |= 1 << getattr(self.config, _BIT_ATTRS[action])

        cpu.mem[self.config.input_port] = value
