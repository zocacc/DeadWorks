"""Install only the Windows x64 template from the verified Godot 4.7.2 TPZ."""

from hashlib import sha256
from pathlib import Path
from shutil import copyfileobj
from sys import argv
from zipfile import ZipFile


VERSION = "4.7.2.stable"
EXPECTED_SHA256 = "f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"
TARGETS = {"windows_release_x86_64.exe", "windows_release_x86_64_console.exe", "version.txt"}


def main() -> None:
    if len(argv) != 2:
        raise SystemExit("Uso: python tools/install_windows_export_template.py arquivo.tpz")
    archive_path = Path(argv[1])
    digest = sha256()
    with archive_path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    if digest.hexdigest() != EXPECTED_SHA256:
        raise SystemExit("SHA-256 do template Godot não confere")

    destination = Path.home() / ".local/share/godot/export_templates" / VERSION
    with ZipFile(archive_path) as archive:
        files = {Path(name).name: name for name in archive.namelist() if name.startswith("templates/")}
        if "windows_release_x86_64.exe" not in files or "version.txt" not in files:
            raise SystemExit("TPZ não contém o template Windows x64 esperado")
        if archive.read(files["version.txt"]).decode().strip() != VERSION:
            raise SystemExit("Versão interna do template não confere")
        destination.mkdir(parents=True, exist_ok=True)
        for name in TARGETS.intersection(files):
            with archive.open(files[name]) as source, (destination / name).open("wb") as target:
                copyfileobj(source, target)
    print(f"Template Windows x64 instalado em {destination}")


if __name__ == "__main__":
    main()
