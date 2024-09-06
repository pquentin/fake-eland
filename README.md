# Migrating Eland Docker image to Wolfi

This repository produces a minimal example to show the problem I'm having with
migrating Eland's Docker image to Wolfi. This Docker image exists solely to run
the `eland_import_hub_model` Python script, which is annoying to install
locally as it requires a working Python environment and GBs of dependencies.
(As soon as we started publishing this Docker image, our number of support
cases about installing Eland dropped to zero.)

In this repository, `eland_import_hub_model` reproduces the way Python installs
console scripts:

 * in the `bin` directory of the active virtual environment "bin" directory
 * and with a shebang line telling the shell where the Python interpreter is in that virtual envirnment.

This means we need a shell to read that shebang line and run the script with
the correct Python interpreter.

Here's how I'm testing the two Dockerfiles.

## ✅ Using a Debian base image

```bash
$ docker build -t fake-eland-wolfi .
$ trivy image fake-eland
[...]
Total: 104 (UNKNOWN: 0, LOW: 67, MEDIUM: 29, HIGH: 7, CRITICAL: 1)
$ docker run -it fake-eland-wolfi eland_import_hub_model --foo bar baz
success! ['/eland/venv/bin/eland_import_hub_model', '--foo', 'bar', 'baz']
```

## ❌ Using a Wolfi base image

```bash
$ docker build -f Dockerfile.wolfi -t fake-eland-wolfi .
$ trivy image fake-eland-wolfi
[...]
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
$ docker run -it fake-eland-wolfi eland_import_hub_model --foo bar baz
/usr/bin/python: can't open file '//eland_import_hub_model': [Errno 2] No such file or directory
```

This suggests the entrypoint of the Wolfi image is Python, which does not read PATH and cannot find the `eland_import_hub_model` file. This suggests that we can give it the absolute path to the file, and it indeed works:

```bash
$ docker run -it fake-eland-wolfi /eland/venv/bin/eland_import_hub_mode --foo bar baz
success! ['/eland/venv/bin/eland_import_hub_model', '--foo', 'bar', 'baz']
```

But we don't want to type "/eland/venv/bin" as it's not backwards-compatible (and ugly). To keep the previous behavior, we need a shell.

## ✅? Using a Wolfi base image + shell

I initially implemented what a shell would have done in 10 lines of Python, but error handling would have been bad. Instead, I can use /bin/sh from python:3.10-dev (which is actually ash in busybox, and takes 658KB).

```bash
$ docker build -f Dockerfile.wolfi-shell -t fake-eland-wolfi .
$ trivy image fake-eland-wolfi
[...]
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
$ docker run -it fake-eland-wolfi eland_import_hub_model --foo bar baz
success! ['/eland/venv/bin/eland_import_hub_model', '--foo', 'bar', 'baz']
```

## ✅ Using a custom Python Wolfi base image + bash built via apko

[apko](https://github.com/chainguard-dev/apko/) is a command-line tool used to build container images, primarily based on the `apk` package format. It allows users to create minimal, efficient, and secure container base images in a reproducible way using a declarative language (YAML).

**Prerequisite**
You need `apko` to be installed locally, see https://github.com/chainguard-dev/apko/tree/main?tab=readme-ov-file#installation

Build the custom base image with the minimal python image + bash
```bash
./apko/build.sh

2024/09/06 19:35:44 INFO Determining packages for 1 architectures: [arm64]
2024/09/06 19:35:44 INFO setting apk repositories: [https://packages.wolfi.dev/os /var/folders/v3/xk5brb8j21107_2k28qxwq8c0000gn/T/apko-temp-737571932/base_image_apkindex] arch=aarch64
2024/09/06 19:35:45 INFO Building images for 1 architectures: [arm64]
2024/09/06 19:35:45 INFO detected git+ssh://github.com/mgreau/testing-apko.git@4f93e6ceb2c12275b3630209a8545bf9ff1a6648 as VCS URL
2024/09/06 19:35:45 INFO setting apk repositories: [https://packages.wolfi.dev/os /var/folders/v3/xk5brb8j21107_2k28qxwq8c0000gn/T/apko-temp-3959710311/base_image_apkindex]
2024/09/06 19:35:45 INFO installing bash (5.2.32-r2)
2024/09/06 19:35:45 INFO setting apk repositories: [https://packages.wolfi.dev/os]
...
2024/09/06 19:35:45 INFO built image layer tarball as /var/folders/v3/xk5brb8j21107_2k28qxwq8c0000gn/T/apko-temp-3959710311/apko-aarch64.tar.gz
2024/09/06 19:35:45 INFO OCI layer digest: sha256:70e1d8630c01f496526b4c687aa55035c0fe2a5670b5e2cb7d5af39e780f26b9 arch=aarch64
2024/09/06 19:35:45 INFO OCI layer diffID: sha256:b7636dc49d88159bdeda57954075a3d4c72714faa8ce730297979d7f9ebf5d0e arch=aarch64
2024/09/06 19:35:45 INFO built index file as /var/folders/v3/xk5brb8j21107_2k28qxwq8c0000gn/T/apko-temp-3959710311/index.json
Loaded image: python-bash:latest-arm64
```

The custom base image `python-bash:latest-arm64` is now available locally and can be used to build the fake-eland-wolfi image.

```bash
$ docker build -f Dockerfile.wolfi-shell-apko -t fake-eland-wolfi-apko .
$ trivy image fake-eland-wolfi-apko
[...]
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
$ docker run -it fake-eland-wolfi-apko eland_import_hub_model --foo bar baz
success! ['/eland/venv/bin/eland_import_hub_model', '--foo', 'bar', 'baz']
```
