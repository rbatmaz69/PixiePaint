#!/usr/bin/env python3
"""Checks that every native library in a release bundle is 16-KB aligned.

    python3 tool/check_so_alignment.py                       # newest .aab
    python3 tool/check_so_alignment.py path/to/app.aab       # or an .apk

Newer Android devices run with 16-KB memory pages, and Play rejects bundles
whose native libraries are laid out for 4-KB ones. PixiePaint has no native
code of its own, but several plugins bring some, so the answer can change
with any dependency update — which is exactly why this is a script and not a
line in the release guide someone retypes once a year.

Reads the ELF program headers itself, with nothing but the standard library.
The obvious way is `objdump -p`, but binutils is not on a stock macOS, and on
this project's development machine there is no Xcode either — a check that
only runs where a toolchain happens to be installed is a check that quietly
stops running. The number wanted here is one field per segment; parsing it
directly costs less than the dependency does.

Exit code 0 = every library is fine, 1 = at least one is not (so it can go in
a pipeline), 2 = nothing to check.
"""
import pathlib
import struct
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent

#: What Play expects. A library aligned to more than this is fine too — the
#: requirement is a floor, not an exact value.
REQUIRED_ALIGN = 16 * 1024

PT_LOAD = 1


def load_alignments(data: bytes):
    """Returns the p_align of every PT_LOAD segment in an ELF image.

    Both 32- and 64-bit, both endiannesses: an app bundle carries a library
    per ABI, and armeabi-v7a is still 32-bit little-endian.
    """
    if data[:4] != b'\x7fELF':
        raise ValueError('not an ELF file')
    is64 = data[4] == 2
    endian = '<' if data[5] == 1 else '>'

    if is64:
        phoff, = struct.unpack_from(endian + 'Q', data, 0x20)
        phentsize, phnum = struct.unpack_from(endian + 'HH', data, 0x36)
    else:
        phoff, = struct.unpack_from(endian + 'I', data, 0x1C)
        phentsize, phnum = struct.unpack_from(endian + 'HH', data, 0x2A)

    aligns = []
    for i in range(phnum):
        off = phoff + i * phentsize
        if is64:
            p_type, = struct.unpack_from(endian + 'I', data, off)
            p_align, = struct.unpack_from(endian + 'Q', data, off + 0x30)
        else:
            p_type, = struct.unpack_from(endian + 'I', data, off)
            p_align, = struct.unpack_from(endian + 'I', data, off + 0x1C)
        if p_type == PT_LOAD:
            aligns.append(p_align)
    return aligns


def newest_bundle():
    """The bundle a fresh `flutter build appbundle --release` just wrote."""
    candidates = sorted(
        ROOT.glob('build/app/outputs/bundle/**/*.aab'),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def main():
    if len(sys.argv) > 1:
        bundle = pathlib.Path(sys.argv[1])
    else:
        bundle = newest_bundle()
        if bundle is None:
            sys.exit('No .aab found — run `flutter build appbundle --release` '
                     'first, or pass a path.')
    if not bundle.exists():
        sys.exit(f'{bundle} does not exist')

    print(f'{bundle.relative_to(ROOT) if bundle.is_relative_to(ROOT) else bundle}\n')

    bad = []
    checked = 0
    with zipfile.ZipFile(bundle) as zf:
        for name in sorted(zf.namelist()):
            if not name.endswith('.so'):
                continue
            aligns = load_alignments(zf.read(name))
            if not aligns:
                continue
            checked += 1
            # The smallest LOAD alignment decides: one 4-KB segment is enough
            # to make the whole library unloadable on a 16-KB device.
            worst = min(aligns)
            ok = worst >= REQUIRED_ALIGN
            if not ok:
                bad.append(name)
            print(f'  {"ok  " if ok else "FAIL"}  {worst // 1024:>3} KB  {name}')

    if checked == 0:
        print('\nNo native libraries in this bundle.')
        return 2
    print()
    if bad:
        print(f'{len(bad)} of {checked} libraries are below '
              f'{REQUIRED_ALIGN // 1024} KB. Updating the plugin that ships '
              'them is usually the fix.')
        return 1
    print(f'All {checked} native libraries are aligned to at least '
          f'{REQUIRED_ALIGN // 1024} KB.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
