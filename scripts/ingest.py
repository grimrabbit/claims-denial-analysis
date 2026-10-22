"""Download the raw CMS Transparency in Coverage file into data/raw/.

Usage (from the repo root, with the virtual environment active):

    python scripts/ingest.py           # download if the file isn't there yet
    python scripts/ingest.py --force   # download again, replacing the file

The file is saved unchanged. After downloading, the script checks its
SHA-256 fingerprint against the version this project was built on, so you
know whether CMS has changed the file since.
"""

import argparse
import hashlib
import sys
import urllib.request
from pathlib import Path

SOURCE_URL = "https://data.healthcare.gov/datafile/py2026/transparency_in_coverage_PUF.xlsx"

# SHA-256 of the file the analysis and KFF reconciliation were built on
# (downloaded Oct 3, 2026). A different value means CMS published a new version.
EXPECTED_SHA256 = "27379dc76590027b0e6d21d736331f87376f0ac87810d68e9f7cca555eef4b1f"

# Paths are built from this script's location, so it works from any folder.
REPO_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = REPO_ROOT / "data" / "raw"
TARGET = RAW_DIR / "tcpuf_py2026.xlsx"


def sha256_of(path: Path) -> str:
    """Return the SHA-256 fingerprint of a file, reading it in chunks."""
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(url: str, target: Path) -> None:
    """Download to a temporary file, then rename, so a failed download
    never leaves a half-written file where dbt expects a complete one."""
    temp = target.with_suffix(".part")
    print(f"Downloading {url}")
    try:
        with urllib.request.urlopen(url, timeout=60) as response, temp.open("wb") as out:
            while chunk := response.read(1024 * 1024):
                out.write(chunk)
    except Exception:
        temp.unlink(missing_ok=True)
        raise
    temp.replace(target)
    print(f"Saved {target.relative_to(REPO_ROOT)} ({target.stat().st_size:,} bytes)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="download even if the file exists")
    parser.add_argument("--url", default=SOURCE_URL, help=argparse.SUPPRESS)
    args = parser.parse_args()

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    if TARGET.exists() and not args.force:
        print(f"{TARGET.relative_to(REPO_ROOT)} already exists; skipping download (use --force to replace).")
    else:
        download(args.url, TARGET)

    actual = sha256_of(TARGET)
    if actual == EXPECTED_SHA256:
        print("Fingerprint matches the version this project was built on.")
        return 0

    print(
        "WARNING: this file differs from the version this project was built on.\n"
        f"  expected {EXPECTED_SHA256}\n"
        f"  got      {actual}\n"
        "CMS may have republished it. Run `dbt build` and check that the KFF\n"
        "reconciliation tests still pass before trusting the numbers.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
