"""Verify every 64-bit ELF PT_LOAD segment in an Android APK for 16 KiB pages.
ZIP entry alignment is separately checked by Android SDK zipalign -c -P 16.
"""
import argparse
import struct
from zipfile import ZipFile

PAGE = 16384

def check_elf(data):
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        raise ValueError("expected little-endian ELF64")
    header = struct.unpack_from("<16sHHIQQQIHHHHHH", data)
    phoff, phentsize, phnum = header[5], header[9], header[10]
    if phentsize < 56 or not phnum or phoff + phentsize * phnum > len(data):
        raise ValueError("invalid program headers")
    loads = 0
    for i in range(phnum):
        typ, flags, offset, vaddr, paddr, filesz, memsz, align = struct.unpack_from(
            "<IIQQQQQQ", data, phoff + i * phentsize
        )
        if typ != 1:
            continue
        loads += 1
        if align < PAGE or align & (align - 1) or (vaddr - offset) % PAGE:
            raise ValueError(f"PT_LOAD {i}: alignment={align}, offset={offset:#x}, vaddr={vaddr:#x}")
    if not loads:
        raise ValueError("no PT_LOAD segments")
    return loads

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk")
    args = parser.parse_args()
    errors = []
    with ZipFile(args.apk) as archive:
        libs = [n for n in archive.namelist()
                if n.startswith(("lib/arm64-v8a/", "lib/x86_64/")) and n.endswith(".so")]
        if not libs:
            raise SystemExit("FAIL: no 64-bit native libraries")
        for name in sorted(libs):
            try:
                loads = check_elf(archive.read(name))
                print(f"PASS: {name}: {loads} aligned LOAD segments")
            except (ValueError, struct.error) as exc:
                errors.append(f"{name}: {exc}")
    if errors:
        raise SystemExit("FAIL: 16 KB ELF alignment:\n" + "\n".join(errors))
    print(f"PASS: all {len(libs)} 64-bit native libraries support 16 KB ELF alignment")

if __name__ == "__main__":
    main()
