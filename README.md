# BinPy — Documentation

**BinPy** is a minimal text-based format for storing Python source code as binary digits (`0` and `1`). It is a plain text file — no headers, no compression, no tricks. Just zeros and ones, one line of Python per line of `.binpy`.

---

## 1. Overview

```
program.py  ──encode──►  program.binpy  ──decode──►  program_restored.py  ──compile──►  program_restored.pyc  ──PyInstaller──►  program_restored.exe
```

- **`.binpy`** — plain text file containing only `0` and `1` (spaces optional) and `#` comments.
- **One line of `.binpy`** = **one line of Python source**, encoded as UTF-8 bytes and written as 8-bit groups.
- **Comment line in `.binpy`** = **comment line in Python**, written as plain text starting with `#`.
- **Empty line in `.binpy`** = **empty line in Python**.
- The format is human-readable, diff-friendly, and round-trip verifiable.

---

## 2. Format Specification

### 2.1 Structure

```
<line 1>
<line 2>
...
<line N>
```

Each `<line>` is one of:

- a **binary line** — sequence of 8-bit groups separated by spaces;
- a **comment line** — plain text starting with `#` (no leading spaces);
- an **empty line**.

Binary example:

```
01001000 01100101 01101100 01101100 01101111
```

This decodes to `Hello`.

### 2.2 Encoding rules

| Input                     | `.binpy` representation                        |
|---------------------------|------------------------------------------------|
| `def foo():`              | `01100100 01100101 01100110 ... 00111010`      |
| `    def foo():`          | `00100000 00100000 00100000 00100000 01100100 ...` |
| `# comment`               | `# comment`                                    |
| `    # comment`           | `# comment` (indent stripped)                  |
| `        # comment`       | `# comment` (indent stripped)                  |
| empty line                | empty line                                     |
| Cyrillic `Привет`         | 12 bytes → 96 bits (2 bytes per character)     |

### 2.3 Comment rules

- A line is treated as a **comment** if, after stripping leading spaces and tabs, it starts with `#`.
- Comments are stored **as plain text**, always starting at the **left edge** — no indentation.
- On decoding, comments are restored **without indentation**.
- Inline comments (`x = 5  # comment`) are **not** split off — the whole line is encoded as binary. After decoding, the comment reappears inside the code line.

### 2.4 Character encoding

- **UTF-8**. Latin letters = 1 byte (8 bits), Cyrillic = 2 bytes (16 bits), emoji = 4 bytes (32 bits).
- No BOM, no escaping, no compression.

### 2.5 Trailing newline

The decoder always appends a single `\n` at the end of the reconstructed source. During verification, this is normalized so that files with or without a final newline compare equal.

---

## 3. Command-Line Tools

BinPy ships as two Python scripts plus two Windows batch files.

### 3.1 `binpy.py`

Core converter and compiler.

```bash
python binpy.py build   input.py     output.binpy
python binpy.py restore input.binpy  output.py
python binpy.py compile file.py
python binpy.py auto    file.py
```

| Command   | Description                                          |
|-----------|------------------------------------------------------|
| `build`   | Encode `.py` → `.binpy`                              |
| `restore` | Decode `.binpy` → `.py`                              |
| `compile` | Compile `.py` → `.pyc`                               |
| `auto`    | Run `build`, `restore`, and `compile` in one shot    |

### 3.2 `verify.py`

Round-trip check between a `.py` file and its `.binpy` counterpart.

```bash
python verify.py source.py source.binpy
```

Output:

- `[OK] Round-trip OK (byte-exact)` — perfect match, including comment indentation.
- `[OK] Round-trip OK (comment indentation normalized)` — matches after stripping indentation from comment lines.
- `[WARN] Round-trip mismatch!` — prints the first differing line with both versions.

### 3.3 `build.bat`

Interactive encoder. Converts `.py` → `.binpy` and stores the result **next to the batch file**.

```bat
build.bat
build.bat program
build.bat program.py
build.bat "C:\path\to\my program.py"
```

Features:

- Lists all `.py` files in the script directory.
- Accepts either a number from the list or a file name.
- Automatically appends `.py` if missing.
- Asks before overwriting an existing `.binpy`.
- Verifies the round-trip after encoding.

### 3.4 `compile.bat`

Interactive compiler. Converts `.binpy` → `.py` → `.pyc` → optionally `.exe`.

```bat
compile.bat
compile.bat program
compile.bat program.binpy
```

Features:

- Lists all `.binpy` files in the script directory.
- Accepts either a number or a file name.
- Asks whether to also build a standalone `.exe` via PyInstaller.
- Stores all artifacts inside `compile/` next to the batch file.

---

## 4. Directory Layout

```
BinPy format/
├── build.bat              ← .py → .binpy
├── compile.bat            ← .binpy → .pyc / .exe
├── binpy.py               ← core converter
├── verify.py              ← round-trip checker
├── program.py             ← source code
├── program.binpy          ← encoded source (next to batch)
└── compile/               ← all build artifacts
    ├── program_restored.py
    ├── program_restored.spec
    ├── __pycache__/
    │   └── program_restored.cpython-XXX.pyc
    ├── build/
    └── dist/
        └── program_restored.exe
```

---

## 5. Workflow

### 5.1 Encode a Python file

```bat
build.bat program
```

Result: `program.binpy` in the same folder as `build.bat`.

### 5.2 Compile a `.binpy` back to Python

```bat
compile.bat program
```

Result:

- `compile/program_restored.py` — restored source.
- `compile/__pycache__/program_restored.cpython-XXX.pyc` — Python bytecode.

### 5.3 Build a standalone `.exe`

```bat
compile.bat program
Build .exe too? (y/N): y
```

Result: `compile/dist/program_restored.exe`.

### 5.4 Verify integrity

```bat
python verify.py program.py program.binpy
```

---

## 6. Example

Source `program.py`:

```python
# Factorial calculator
# Author: den

def factorial(n):
    result = 1
    for i in range(1, n + 1):
        result *= i
    return result


def main():
    # print factorials 1..10
    for n in range(1, 11):
        print(f"{n}! = {factorial(n)}")


if __name__ == "__main__":
    main()
```

After `build.bat program`, `program.binpy` looks like:

```
# Factorial calculator
# Author: den
01100100 01100101 01100110 00100000 01100110 01100001 01100011 01110100 ...

# print factorials 1..10
01100110 01101111 01110010 00100000 01101110 00100000 01101001 01101110 ...
```

Comments are plain text at the left edge, code lines are binary, empty lines stay empty. The whole file decodes back to Python source line by line.

---

## 7. Error Handling

| Error message                                       | Meaning                                          |
|-----------------------------------------------------|--------------------------------------------------|
| `Cannot resolve path for: <name>`                   | File name could not be turned into a full path.  |
| `File not found: <path>`                            | The `.py` or `.binpy` does not exist.            |
| `Python not found in PATH.`                         | `python` is not available in the system PATH.    |
| `Length (<n>) not multiple of 8`                    | A `.binpy` line has a broken 8-bit group.        |
| `Round-trip mismatch!`                              | Decoded source differs from the original.        |
| `ERROR: Script file '...' does not exist.`          | PyInstaller received an empty or wrong path.     |

---

## 8. Limitations

- **Not obfuscation.** `.binpy` is trivially reversible — anyone can decode it with one command.
- **Not compression.** The file is roughly the same size as the original UTF-8 source (Latin: 8× larger in characters, same in bytes; Cyrillic: same in bytes).
- **Not encryption.** Use AES or XOR on top if you need secrecy.
- **Comment indentation is lost.** On decode, comments lose leading whitespace by design. This does not affect Python semantics but is not byte-exact for files containing indented comments.
- **Line-based.** Extremely long lines (thousands of characters) become extremely long `.binpy` lines — most editors handle it, but diff tools may struggle.
- **No metadata.** No version, no checksum, no length header. If the file gets corrupted, nothing detects it unless you use `verify.py`.

---

## 9. Extending the Format

The format is deliberately minimal. Possible extensions:

- **Metadata header.** Add a first line like `#META version=1 lines=42` — decoders skip it.
- **Hex encoding.** Replace `01001000` with `48` for a 4× shorter file.
- **Base64.** Even shorter, though less readable.
- **Preserve comment indentation.** Encode indent as `@N# comment` — a `@N` prefix stores how many spaces preceded the `#`. The decoder restores them.
- **Compression.** Wrap the payload in `zlib.compress()`.
- **Encryption.** XOR with a key, or AES via `cryptography`.
- **Checksum footer.** Append `#CRC32:xxxxxxxx` at the end.

All of these can be layered on without breaking the basic `encode → decode` contract.

---

## 10. Quick Reference

| Task                             | Command                              |
|----------------------------------|--------------------------------------|
| Encode `.py` to `.binpy`         | `build.bat program`                  |
| Compile `.binpy` to `.pyc`       | `compile.bat program`                |
| Compile and build `.exe`         | `compile.bat program` → answer `y`   |
| Restore `.py` without compiling  | `python binpy.py restore in.binpy out.py` |
| Verify round-trip                | `python verify.py file.py file.binpy` |

---

**BinPy** — a tiny, transparent format: encode your Python source as 0s and 1s, keep comments as plain text at the left edge, decode it back to Python, compile it into `.pyc` or a standalone `.exe`. Nothing hidden, nothing clever — just a clean bridge between human-readable code and binary text.