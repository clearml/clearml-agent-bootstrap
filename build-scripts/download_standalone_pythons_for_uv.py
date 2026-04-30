# Downloads the latest standalone Python builds from the UV GitHub repository and generates a new metadata file referencing them.
# Only includes relevant Linux versions (musl and gnu), targeting x86_64 and aarch64 architectures, for streamlined server deployment.

# TODO: add support for merging with exsting "metadata.json" files

import os
import json
import sys
import subprocess
import urllib.parse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed


# Configurations
CPYTHON_STANDALONE_VERSION = os.environ.get("CPYTHON_STANDALONE_VERSION", "latest")
if CPYTHON_STANDALONE_VERSION and CPYTHON_STANDALONE_VERSION.lower() != "latest":
    METADATA_URL = f"https://raw.githubusercontent.com/astral-sh/uv/refs/tags/{CPYTHON_STANDALONE_VERSION}/crates/uv-python/download-metadata.json"
else:
    METADATA_URL = "https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv-python/download-metadata.json"

CUSTOM_SERVER_BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080/cpython_build/releases/"
TEMP_FILE = "__download-metadata.json"
DOWNLOAD_DIR = sys.argv[2] if len(sys.argv) > 2 else "cpython_build/releases/"
OUT_METADATA_FILE = sys.argv[3] if len(sys.argv) > 3 else "cpython_build/download-metadata.json"
MAX_WORKERS = 4

print("\nPreprocessing CPython standalone binary packages:")
print(f"  CPYTHON_STANDALONE_VERSION = {CPYTHON_STANDALONE_VERSION}")
print(f"  METADATA_URL = {METADATA_URL}")
print(f"  CUSTOM_SERVER_BASE = {CUSTOM_SERVER_BASE}")
print(f"  DOWNLOAD_DIR = {DOWNLOAD_DIR}")
print(f"  OUT_METADATA_FILE = {OUT_METADATA_FILE}")
print("\n\n")

# Step 1: Download metadata file using curl
subprocess.run(["curl", "-sSL", METADATA_URL, "-o", TEMP_FILE], check=True)

# Step 2: Load JSON content
with open(TEMP_FILE, "r", encoding="utf-8") as f:
    metadata = json.load(f)

os.unlink(TEMP_FILE)

# Step 3: Filter and organize by minor versions and arch+libc combos
latest_versions = defaultdict(dict)

download_count = 0
for key, entry in metadata.items():
    arch = entry.get("arch", {})
    cpu_family = arch.get("family")
    cpu_variant = arch.get("variant")
    libc = entry.get("libc")
    platform = entry.get("os", "")
    url = entry.get("url", "")
    prerelease = entry.get("prerelease", "")
    major = entry.get("major", "")
    minor = entry.get("minor", "")
    patch = entry.get("patch", "")

    # Skip non-linux and pre-release
    if platform != "linux" or cpu_family not in ["x86_64", "aarch64"] or prerelease:
        continue

    patch = int(patch)

    # Create a unique architecture key including family, variant, and libc
    arch_key = f"{cpu_family}_{cpu_variant}_{libc}"

    current = latest_versions[minor].get(arch_key)
    if not current or current["patch"] < patch:
        if minor not in latest_versions:
            latest_versions[minor] = {}
        latest_versions[minor][arch_key] = {
            "patch": patch,
            "url": url,
            "entry": entry,
            "key": key
        }
        download_count += 1

# Step 4: Download CPython tarballs and rewrite URLs
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
filtered_dict = {}

print(f"Downloading {download_count} python binary packages to: {DOWNLOAD_DIR}")

def download_file(info):
    url = info["url"]
    filename = urllib.parse.unquote(url.split("/")[-1])
    local_path = os.path.join(DOWNLOAD_DIR, filename)
    subprocess.run(["curl", "-sSL", url, "-o", local_path], check=True)
    return info, filename

futures = []
with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    for minor, arches in latest_versions.items():
        for arch_key, info in arches.items():
            futures.append(executor.submit(download_file, info))

    for idx, future in enumerate(as_completed(futures), 1):
        info, filename = future.result()
        print(f"Downloaded {idx}/{download_count}")
        key = info["key"]
        filtered_dict[key] = info["entry"]
        filtered_dict[key]["url"] = urllib.parse.urljoin(
            CUSTOM_SERVER_BASE + "/", urllib.parse.quote(filename)
        )

print("All downloads completed.")

# Step 5: Output updated metadata
with open(OUT_METADATA_FILE, "w", encoding="utf-8") as f:
    json.dump(filtered_dict, f, indent=2)

print("Storing {} python binary packages meta-data to: {}".format(len(filtered_dict), OUT_METADATA_FILE))
