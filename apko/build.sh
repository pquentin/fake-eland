#!/bin/bash

# Script for building image on top of base with apko.
# Must be run from the root of github repository.

apko_binary="${1:-apko}"

WORKDIR="./apko/build"
BASE_IMAGE=docker.elastic.co/wolfi/python:3.10
BASE_IMAGE_WORKDIR="$WORKDIR/base_image"
APKINDEX_WORKDIR="$WORKDIR/apkindexes"
FS_DUMP_WORKDIR="$WORKDIR/fs_dump"
ARCH=aarch64

# Pull base image
crane pull "$BASE_IMAGE" "$BASE_IMAGE_WORKDIR" --format=oci
# Prepare apkindex for base image
mkdir -p "$FS_DUMP_WORKDIR"
crane export "$BASE_IMAGE" "$FS_DUMP_WORKDIR/fs.tar"
tar -C "$FS_DUMP_WORKDIR" -xf "$FS_DUMP_WORKDIR/fs.tar"
mkdir -p "$APKINDEX_WORKDIR/$ARCH/"
cp "$FS_DUMP_WORKDIR/lib/apk/db/installed" "$APKINDEX_WORKDIR/$ARCH/APKINDEX"

"$apko_binary" lock "apko/base_image.yaml"

mkdir -p "$WORKDIR/top_image"

"$apko_binary" build "apko/base_image.yaml" python-bash:latest "apko/python_bash.tar" --lockfile="apko/base_image.lock.json" --sbom=False

docker load -i "apko/python_bash.tar"
