import sys
import os
import py_compile


# ---------- comments and lines ----------

def is_comment_only(line: str) -> bool:
    """True for lines that start with # (with any indentation)."""
    return line.lstrip().startswith("#")


def encode_line(line: str) -> str:
    if line == "":
        return ""
    if is_comment_only(line):
        # comments always start at the left edge, no indentation
        return line.lstrip()
    return ' '.join(format(b, '08b') for b in line.encode("utf-8"))


def decode_line(binary_line: str) -> str:
    stripped = binary_line.rstrip("\n")

    if stripped.strip() == "":
        return ""

    if stripped.lstrip().startswith("#"):
        # comments always start at the left edge
        return stripped.lstrip()

    data = bytes(int(b, 2) for b in stripped.split())
    return data.decode("utf-8")


def encode_source(source: str) -> str:
    return "\n".join(encode_line(line) for line in source.splitlines())


def decode_source(binary: str) -> str:
    return "\n".join(decode_line(line) for line in binary.splitlines()) + "\n"


# ---------- pipeline ----------

def make_binpy(py_path, binpy_path):
    with open(py_path, "r", encoding="utf-8") as f:
        source = f.read()
    with open(binpy_path, "w", encoding="utf-8") as f:
        f.write(encode_source(source))
    print(f"[build]   {py_path} -> {binpy_path}")


def restore_py(binpy_path, py_path):
    with open(binpy_path, "r", encoding="utf-8") as f:
        binary = f.read()
    with open(py_path, "w", encoding="utf-8") as f:
        f.write(decode_source(binary))
    print(f"[restore] {binpy_path} -> {py_path}")


def compile_pyc(py_path):
    pyc_path = py_compile.compile(py_path, doraise=True)
    print(f"[compile] {py_path} -> {pyc_path}")
    return pyc_path


# ---------- CLI ----------

def main():
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python binpy.py build   in.py     out.binpy")
        print("  python binpy.py restore in.binpy  out.py")
        print("  python binpy.py compile file.py")
        print("  python binpy.py auto    file.py")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "build":
        make_binpy(sys.argv[2], sys.argv[3])
    elif cmd == "restore":
        restore_py(sys.argv[2], sys.argv[3])
    elif cmd == "compile":
        compile_pyc(sys.argv[2])
    elif cmd == "auto":
        py_path = sys.argv[2]
        base = os.path.splitext(py_path)[0]
        make_binpy(py_path, base + ".binpy")
        restore_py(base + ".binpy", base + "_restored.py")
        compile_pyc(base + "_restored.py")
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()