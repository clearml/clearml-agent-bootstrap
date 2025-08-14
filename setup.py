import os
import json
import sys
import tarfile
import shutil
from setuptools import setup, find_packages
from setuptools.command.install import install


def preprocess_package_binary(data_folder):    
    dir1 = 'bootstrap/uv'
    dir2 = 'bootstrap/git'
    dir3 = 'bootstrap/dropbear'
    bundle1 = os.path.join(data_folder, 'uv.tar.gz')
    bundle2 = os.path.join(data_folder, 'git.tar.gz')
    bundle3 = os.path.join(data_folder, 'dropbear.tar.gz')
    
    os.makedirs(data_folder, exist_ok=True)

    # Remove existing tar files if they exist
    for tar_path in [bundle1, bundle2, bundle3]:
        if os.path.exists(tar_path):
            os.unlink(tar_path)

    # Create bundle1 from dir1
    with tarfile.open(bundle1, 'w:gz') as tar:
        print("packaging {}".format(dir1))
        tar.add(dir1, arcname=os.path.basename(dir1))

    # Create bundle2 from dir2
    with tarfile.open(bundle2, 'w:gz') as tar:
        print("packaging {}".format(dir2))
        tar.add(dir2, arcname=os.path.basename(dir2))

    # Create bundle3 from dir3
    with tarfile.open(bundle3, 'w:gz') as tar:
        print("packaging {}".format(dir3))
        tar.add(dir3, arcname=os.path.basename(dir3))


# Read version from version.txt
def read_version_string(version_file):
    with open(version_file, "r") as f:
        lines = f.read().splitlines()

    for line in lines:
        if line.startswith('__version__'):
            delim = '"' if '"' in line else "'"
            return line.split(delim)[1]
    else:
        raise RuntimeError("Unable to find version string.")


version = read_version_string("clearml_agent_bootstrap/version.py")
package_name="clearml_agent_bootstrap"


# Read long description from readme.md
with open("README.md", "r", encoding="utf-8") as f:
    long_description = f.read()

    
# Preprocess symlinks before packaging
if __name__ == "__main__":
    preprocess_package_binary(package_name+'/data')



setup(
    name=package_name,
    version=version,
    description="A data-only package with clearml-agent bootstrap tools and executables",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=[package_name, package_name+'.data',],
    include_package_data=True,
    package_data={
         package_name: ['data/*', ]
    },
    python_requires=">=3.0",
    url="https://github.com/clearml/clearml-agent-bootstrap",
    author="clearml",
    author_email="clearml@clearml.ai",
    license="Apache-2.0",
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "Intended Audience :: Science/Research",
        "Operating System :: POSIX :: Linux",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: Microsoft",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Topic :: System :: Hardware",
        "Topic :: System :: Systems Administration",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
    ],
)
