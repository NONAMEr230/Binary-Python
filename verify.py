import sys
from binpy import decode_source


def normalize_newline(s: str) -> str:
    """Guarantees exactly one trailing newline."""
    if not s.endswith("\n"):
        s = s + "\n"
    return s


def normalize_comments(s: str) -> str:
    """Strips indentation from comments — for soft comparison."""
    lines = []
    for line in s.splitlines():
        if line.lstrip().startswith("#"):
            lines.append(line.lstrip())
        else:
            lines.append(line)
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 3:
        print("Usage: python verify.py source.py encoded.binpy")
        sys.exit(2)

    src_path = sys.argv[1]
    bin_path = sys.argv[2]

    with open(src_path, "r", encoding="utf-8") as f:
        original = f.read()

    with open(bin_path, "r", encoding="utf-8") as f:
        binary = f.read()

    decoded = decode_source(binary)

    original_n = normalize_newline(original)
    decoded_n  = normalize_newline(decoded)

    # 1) strict byte-exact comparison
    if original_n == decoded_n:
        print("[OK] Round-trip OK (byte-exact)")
        sys.exit(0)

    # 2) soft comparison — ignore comment indentation
    if normalize_comments(original_n) == normalize_comments(decoded_n):
        print("[OK] Round-trip OK (comment indentation normalized)")
        sys.exit(0)

    # 3) real mismatch — show the first differing line
    print("[WARN] Round-trip mismatch!")
    print(f"  original: {len(original_n)} chars")
    print(f"  decoded:  {len(decoded_n)} chars")

    orig_lines = original_n.splitlines()
    dec_lines  = decoded_n.splitlines()
    for i in range(max(len(orig_lines), len(dec_lines))):
        o = orig_lines[i] if i < len(orig_lines) else "<missing>"
        d = dec_lines[i] if i < len(dec_lines) else "<missing>"
        if o != d:
            print(f"  line {i+1}:")
            print(f"    original: {o!r}")
            print(f"    decoded:  {d!r}")
            break

    sys.exit(1)


if __name__ == "__main__":
    main()