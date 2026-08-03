"""Milestone 1: turn a single virtual LED on and off.

No assembler is used here - this is a tiny 8051 program written by hand,
opcode by opcode, so the CPU core can be proven correct before anything
about the real Ping Pong ROM is involved.

    ORG 0
    START:
        SETB P1.0        ; D2 90
        MOV  R0,#0xFF    ; 78 FF
    DELAY1:
        DJNZ R0,DELAY1   ; D8 FE
        CLR  P1.0        ; C2 90
        MOV  R0,#0xFF    ; 78 FF
    DELAY2:
        DJNZ R0,DELAY2   ; D8 FE
        SJMP START       ; 80 F2

Run directly (after `pip install pygame`) for a small window with one LED
that blinks about once a second:

    python -m emulator.milestones.m1_blink_led
"""

from __future__ import annotations

PROGRAM = bytes([
    0xD2, 0x90,  # SETB P1.0
    0x78, 0xFF,  # MOV R0,#0xFF
    0xD8, 0xFE,  # DJNZ R0,DELAY1
    0xC2, 0x90,  # CLR P1.0
    0x78, 0xFF,  # MOV R0,#0xFF
    0xD8, 0xFE,  # DJNZ R0,DELAY2
    0x80, 0xF2,  # SJMP START
])


def main() -> None:
    import pygame

    from emulator.cpu8051 import CPU8051, P1
    from emulator.memory import MemoryBus

    bus = MemoryBus()
    bus.load_code(PROGRAM)
    cpu = CPU8051(bus)

    pygame.init()
    pygame.display.set_caption("Milestone 1 - one LED")
    screen = pygame.display.set_mode((200, 200))
    clock = pygame.time.Clock()

    instructions_per_frame = 3  # slow enough for a human to see it blink
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        for _ in range(instructions_per_frame):
            cpu.step()

        led_on = bool(cpu.mem[P1] & 0x01)
        screen.fill((15, 15, 15))
        color = (255, 60, 40) if led_on else (50, 20, 20)
        pygame.draw.circle(screen, color, (100, 100), 60)
        pygame.display.flip()
        clock.tick(60)

    pygame.quit()


if __name__ == "__main__":
    main()
