# Agent Bootstrap on K8s

The bootstrap Docker image is supposed to be used as an `initContainer` in Task Pods. The init container will copy the bootstrap folder to a target directory for it to be used by the main Agent container.

## Clean the build folders

```bash
cd build-scripts
./clean_all_local_builds.sh
cd ..
```

## Build Bootstrap binaries

```bash
cd build-scripts
./build_all.sh
cd ..
```

## Build the Bootstrap Image

*From the root of the project* execute the following, specifying the `BOOTSTRAP_IMAGE_VER` tag:

```bash
BOOTSTRAP_IMAGE_VER=<TAG>; docker buildx build -t agent-bootstrap:$BOOTSTRAP_IMAGE_VER --load --platform linux/amd64,linux/arm64 -f k8s/Dockerfile .
```
