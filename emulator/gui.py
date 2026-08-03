"""Pygame front end: ties the CPU core, LED matrix decoder and keyboard input
together into a playable loop. Speed is deliberately decoupled from the
original 4 MHz timing - we just run a batch of instructions per rendered
frame, since "good enough to keep developing on" matters more than
cycle-accurate timing here.
"""

from __future__ import annotations

import math

import pygame

from .cpu8051 import CPU8051
from .hardware_config import HardwareConfig
from .input_mapper import InputMapper
from .led_matrix import LedMatrixDisplay
from .memory import MemoryBus

LED_ON = (255, 70, 40)
LED_OFF = (40, 20, 18)
BACKGROUND = (10, 10, 10)

# Measured on 2018_PingPong.hex: one game-loop iteration (READ_PUERTO back to
# READ_PUERTO) runs ~330 instructions. Padded for safety margin so a button
# held for min_hold_frames is guaranteed to still be down the next time the
# CPU actually samples the input port, however low --speed is set.
INSTRUCTIONS_PER_GAME_LOOP_ESTIMATE = 400


class PygameFrontend:
    def __init__(
        self,
        config: HardwareConfig,
        program: bytes,
        instructions_per_frame: int = 2000,
        cell_size: int = 48,
        fps: int = 60,
    ):
        self.config = config
        self.program = program
        self.instructions_per_frame = instructions_per_frame
        self.cell_size = cell_size
        self.fps = fps

        min_hold_frames = max(4, math.ceil(INSTRUCTIONS_PER_GAME_LOOP_ESTIMATE / instructions_per_frame))

        self.bus: MemoryBus
        self.cpu: CPU8051
        self.display: LedMatrixDisplay
        self.input_mapper = InputMapper(config, min_hold_frames=min_hold_frames)
        self._reset()

    def _reset(self) -> None:
        self.bus = MemoryBus()
        self.bus.load_code(self.program)
        self.cpu = CPU8051(self.bus)
        self.display = LedMatrixDisplay(self.config)

    def run(self) -> None:
        pygame.init()
        pygame.display.set_caption(f"Ping Pong 8051 emulator ({self.config.name})")
        margin = self.cell_size // 2
        width = self.config.cols * self.cell_size + margin * 2
        height = self.config.rows * self.cell_size + margin * 2
        screen = pygame.display.set_mode((width, height))
        clock = pygame.time.Clock()

        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key == pygame.K_r:
                        self._reset()

            self.input_mapper.apply(self.cpu)
            for _ in range(self.instructions_per_frame):
                self.cpu.step()
                self.display.sample(self.cpu)

            self._draw(screen, margin)
            pygame.display.flip()
            clock.tick(self.fps)

        pygame.quit()

    def _draw(self, screen: "pygame.Surface", margin: int) -> None:
        screen.fill(BACKGROUND)
        size = self.cell_size
        radius = size // 2 - 3
        fb = self.display.framebuffer
        for row in range(self.config.rows):
            for col in range(self.config.cols):
                cx = margin + col * size + size // 2
                cy = margin + row * size + size // 2
                color = LED_ON if fb[row][col] else LED_OFF
                pygame.draw.circle(screen, color, (cx, cy), radius)
