"""Loads a compiled 8051 program image (Intel HEX or raw binary) into bytes
suitable for MemoryBus.load_code(). No assembler involved: this only reads
what an assembler/IDE (e.g. MCU8051IDE) already produced, such as this
repo's 2018_PingPong.hex / 2018_PingPong.bin.
"""

from __future__ import annotations

from pathlib import Path


def load_intel_hex(path: str | Path) -> bytearray:
    image = bytearray()
    extended_linear_base = 0

    with open(path, "r", encoding="ascii") as f:
        for line_no, raw_line in enumerate(f, start=1):
            line = raw_line.strip()
            if not line:
                continue
            if not line.startswith(":"):
                raise ValueError(f"{path}:{line_no}: expected line to start with ':'")

            data = bytes.fromhex(line[1:])
            byte_count, addr_hi, addr_lo, record_type = data[0], data[1], data[2], data[3]
            payload = data[4:4 + byte_count]
            checksum = data[4 + byte_count]

            computed = (-sum(data[:4 + byte_count])) & 0xFF
            if computed != checksum:
                raise ValueError(f"{path}:{line_no}: checksum mismatch")

            if record_type == 0x00:  # data
                addr = extended_linear_base + ((addr_hi << 8) | addr_lo)
                end = addr + len(payload)
                if end > len(image):
                    image.extend(b"\x00" * (end - len(image)))
                image[addr:end] = payload
            elif record_type == 0x01:  # end of file
                break
            elif record_type == 0x04:  # extended linear address
                extended_linear_base = ((payload[0] << 8) | payload[1]) << 16
            elif record_type == 0x02:  # extended segment address
                extended_linear_base = ((payload[0] << 8) | payload[1]) << 4
            # other record types (start addresses) don't affect memory contents

    return image


def load_binary(path: str | Path) -> bytearray:
    return bytearray(Path(path).read_bytes())


def load_program(path: str | Path) -> bytearray:
    path = Path(path)
    suffix = path.suffix.lower()
    if suffix == ".hex":
        return load_intel_hex(path)
    if suffix in (".bin", ".rom"):
        return load_binary(path)
    raise ValueError(f"Don't know how to load program image with extension '{suffix}': {path}")
