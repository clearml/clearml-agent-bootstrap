import os
import shutil
import tarfile
import filecmp
import shutil
from urllib.request import urlopen


def _fetch_file(source_path_or_url, target_path):
    # Determine if source is a URL or file path
    if source_path_or_url.startswith(('http://', 'https://')):
        # Download from URL and save using shutil
        try:
            with urlopen(source_path_or_url) as response, open(target_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
            print(f"Downloaded {source_path_or_url} file to: {target_path}")
            return target_path
        except Exception as e:
            print(f"Download {source_path_or_url} failed: {e}")
    else:
        # Copy local file using shutil
        try:
            target_path = os.path.expanduser(target_path)
            shutil.copy2(source_path_or_url, target_path)
            print(f"Copied {source_path_or_url} to: {target_path}")
            return target_path
        except Exception as e:
            print(f"Copy {source_path_or_url} failed: {e}")


def install(output_dir, python_binary_metadata_file=None, force=False):
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    tar1 = os.path.join(data_dir, 'uv.tar.gz')
    tar2 = os.path.join(data_dir, 'git.tar.gz')
    tar3 = os.path.join(data_dir, 'dropbear.tar.gz')
    script_path = os.path.join(data_dir, 'bootstrap.sh')
    local_version = os.path.join(os.path.dirname(__file__), 'version.py')
    target_version = os.path.join(output_dir, 'version.txt')

    # Check if version.txt exists and compare with version.py
    if not force and os.path.exists(target_version) and filecmp.cmp(local_version, target_version, shallow=False):
        return True

    print("INFO: unpacking bootstrap package to {}".format(output_dir))

    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    # Extract both bundles
    for tar_path in [tar1, tar2, tar3]:
        with tarfile.open(tar_path, 'r:gz') as tar:
            tar.extractall(path=output_dir)

    # Copy the shell script
    shutil.copy(script_path, os.path.join(output_dir, 'bootstrap.sh'))

    # copy meta file
    if python_binary_metadata_file:
        target_json = _fetch_file(python_binary_metadata_file, os.path.join(output_dir, 'download-metadata.json'))

    # Copy the version file
    shutil.copy(local_version, target_version)

    return True
