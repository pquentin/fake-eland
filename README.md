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
This suggests the entrypoint of the Wolfi image is Python, which does not read PATH and cannot find the `eland_import_hub_model` file.
