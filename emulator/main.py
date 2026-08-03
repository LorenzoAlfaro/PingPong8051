"""CLI entry point.

    python -m emulator.main --rom 2018_PingPong.hex

Controls: player 1 = W/S, player 2 = Up/Down arrows, R = reset, Esc = quit.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from .gui import PygameFrontend
from .hardware_config import DIRECT_8x8
from .hex_loader import load_program

PRESETS = {
    "direct_8x8": DIRECT_8x8,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="8051 Ping Pong hardware emulator")
    parser.add_argument(
        "--rom",
        default="2018_PingPong.hex",
        help="compiled program image (.hex or .bin) to run, default: 2018_PingPong.hex",
    )
    parser.add_argument("--hardware", choices=sorted(PRESETS), default="direct_8x8")
    parser.add_argument(
        "--speed",
        type=int,
        default=25,
        help=(
            "CPU instructions per rendered frame - controls ball/paddle speed since this emulator "
            "isn't cycle-accurate to the real 4MHz part. One ball step is ~330 instructions, so "
            "speed=25 at 60fps is about 4-5 ball steps/sec; raise it for a faster, more arcade-like "
            "pace, lower it (try 10-15) if that's still too fast. Default: 25"
        ),
    )
    parser.add_argument("--cell-size", type=int, default=48, help="pixel size of one LED cell")
    parser.add_argument("--fps", type=int, default=60)
    args = parser.parse_args()

    rom_path = Path(args.rom)
    if not rom_path.exists():
        raise SystemExit(
            f"ROM not found: {rom_path}\n"
            "Build it in MCU8051IDE from 2018_PingPong.asm first, or pass --rom with a path to a compiled .hex/.bin."
        )

    program = load_program(rom_path)
    config = PRESETS[args.hardware]
    frontend = PygameFrontend(
        config=config,
        program=program,
        instructions_per_frame=args.speed,
        cell_size=args.cell_size,
        fps=args.fps,
    )
    frontend.run()


if __name__ == "__main__":
    main()
