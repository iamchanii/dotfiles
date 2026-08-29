#!/usr/bin/env python3
"""Apply the local Toshy keymapper_api customization idempotently."""

from pathlib import Path
import sys


CUSTOMIZATION = '''\
# Reserve the right Command/Meta key for Korean/English input switching.
# This must be registered before Toshy's standard Apple modifier maps.
modmap("Right Meta is Hangul", {
    Key.RIGHT_META: Key.HANGEUL
}, when=lambda ctx: True)
'''
START_MARKER = "###  SLICE_MARK_START: keymapper_api"
END_MARKER = "###  SLICE_MARK_END: keymapper_api"


def main() -> int:
    path = (
        Path(sys.argv[1]).expanduser()
        if len(sys.argv) > 1
        else Path.home() / ".config/toshy/toshy_config.py"
    )
    if not path.is_file():
        print(f"Toshy config not found: {path}", file=sys.stderr)
        return 1

    text = path.read_text()
    if 'modmap("Right Meta is Hangul"' in text:
        print(f"Already configured: {path}")
        return 0

    start = text.find(START_MARKER)
    end = text.find(END_MARKER)
    if start < 0 or end < 0 or start >= end:
        print("Toshy keymapper_api preservation markers not found", file=sys.stderr)
        return 1

    insert_at = text.find("\n", start) + 1
    updated = text[:insert_at] + "\n" + CUSTOMIZATION + "\n" + text[insert_at:]
    path.write_text(updated)
    print(f"Configured Right Meta as Hangul: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
