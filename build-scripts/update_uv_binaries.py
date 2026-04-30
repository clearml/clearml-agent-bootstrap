import requests
import os
import requests
import shutil
import tarfile
import zipfile
import os.path
import sys
from pathlib import Path

def remove_files_by_pattern_rglob(target_dir, pattern):
    target_path = Path(target_dir)
    deleted_files = 0

    print(f"Removing files matching '{pattern}' in: {target_path.resolve()}")

    for file_path in target_path.rglob(pattern):
        if file_path.is_file():
            try:
                file_path.unlink()
                print(f"Deleted: {file_path}")
                deleted_files += 1
            except Exception as e:
                print(f"Failed to delete {file_path}: {e}")

    print(f"Total files deleted: {deleted_files}")


def download_and_extract(url, target_dir):
    local_filename = url.split("/")[-1]
    local_path = os.path.join(target_dir, local_filename)

    print(f"Downloading {url}...")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(local_path, 'wb') as f:
            shutil.copyfileobj(r.raw, f)

    # Extract if it's a zip or tar.gz
    if local_filename.endswith(".zip"):
        with zipfile.ZipFile(local_path, 'r') as zip_ref:
            zip_ref.extractall(target_dir)
        print(f"Extracted {local_filename} as zip")
        os.unlink(os.path.join(target_dir, local_filename))
    elif local_filename.endswith(".tar.gz") or local_filename.endswith(".tgz"):
        with tarfile.open(local_path, 'r:gz') as tar_ref:
            tar_ref.extractall(target_dir)
        print(f"Extracted {local_filename} as tar.gz")
        os.unlink(os.path.join(target_dir, local_filename))
    else:
        print(f"Downloaded {local_filename} (no extraction attempted)")


def get_release_assets(owner, repo, version="latest"):
    if version and version.lower() != "latest":
        url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{version}"
    else:
        url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"

    response = requests.get(url)
    response.raise_for_status()
    release_data = response.json()

    print(f"Release: {release_data['name']}")
    print(f"Published at: {release_data['published_at']}")
    print("\nAssets:")

    links = {}
    assets = release_data.get('assets', [])
    if not assets:
        print("No assets found in this release.")
    else:
        for asset in assets:
            links[asset['name']] = asset['browser_download_url']

    return release_data['tag_name'], links


# setup
target_path = "../bootstrap/uv" if len(sys.argv)<2 else sys.argv[1]
current_dir = os.path.dirname(os.path.abspath(__file__))
target_path = os.path.abspath(os.path.join(current_dir, target_path))
try:
    os.mkdir(target_path)
except FileExistsError:
    print(f"directory {target_path} already exists")

# get release links (use UV_VERSION env var, default to "latest")
uv_version = os.environ.get("UV_VERSION", "latest")
print(f"UV version: {uv_version}")
resolved_tag, assets = get_release_assets("astral-sh", "uv", version=uv_version)
print(f"Resolved UV version: {resolved_tag}")
relevant_assets = {k: v for k, v in assets.items() if not k.lower().endswith(".sha256") and ("x86_64-unknown-linux" in k.lower() or "aarch64-unknown-linux" in k)}

# download files
for url in relevant_assets.values():
    download_and_extract(url, target_path)

# remove redundant files
remove_files_by_pattern_rglob(target_path, "uvx")

# write resolved version for BOM generation
resolved_file = os.path.join(target_path, ".resolved_version")
with open(resolved_file, "w") as f:
    f.write(resolved_tag)
print(f"Resolved version written to {resolved_file}")
