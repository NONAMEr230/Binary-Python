import os
import sys
import subprocess


def main():
    if len(sys.argv) < 2:
        print("Usage: python build_exe.py program_restored.py")
        sys.exit(1)

    script = os.path.abspath(sys.argv[1])

    if not os.path.isfile(script):
        print(f"[ERROR] File not found: {script}")
        sys.exit(1)

    script_dir = os.path.dirname(script)
    base_name = os.path.splitext(os.path.basename(script))[0]

    dist_dir = os.path.join(script_dir, "dist")
    build_dir = os.path.join(script_dir, "build")
    spec_dir = script_dir

    print(f"[exe] Source:       {script}")
    print(f"[exe] dist:         {dist_dir}")
    print(f"[exe] build:        {build_dir}")

    # Check for PyInstaller
    try:
        import PyInstaller  # noqa
    except ImportError:
        print("[exe] PyInstaller not found, installing...")
        subprocess.run(
            [sys.executable, "-m", "pip", "install",
             "--quiet", "--disable-pip-version-check", "pyinstaller"],
            check=True,
        )

    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--onefile",
        "--noconfirm",
        "--clean",
        "--distpath", dist_dir,
        "--workpath", build_dir,
        "--specpath", spec_dir,
        script,
    ]

    print("[exe] Command:")
    print("      " + " ".join(f'"{c}"' if " " in c else c for c in cmd))
    print()

    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"[ERROR] PyInstaller returned code {result.returncode}")
        sys.exit(result.returncode)

    exe_path = os.path.join(dist_dir, base_name + ".exe")
    print()
    print(f"[OK] Final .exe: {exe_path}")


if __name__ == "__main__":
    main()