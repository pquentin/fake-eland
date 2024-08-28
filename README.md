# Migrating Eland Docker image to Wolfi

This repository produces a minimal example to show the problem I'm having with
migrating Eland Docker image to Wolfi. This Docker image exists solely to run
the "eland_import_hub_model" Python script, which is annoying to install
locally as it requires a working Python environment and GBs of dependencies.
(As soon as we started publishing this image, our number of support cases
about installing Eland dropped to zero.)

In this repository, "eland_import_hub_model" reproduces the way Python installs
console scripts: in the virtual environment "bin" directory, with a shebang
that points to the Python installed in that environment. This means we need
cooperation from a shell to read that shebang line and invoke the correct
Python interpreter.

Here's how to reproduce what I'm seeing:

## ✅ Using a Debian base image

```bash
$ docker build -t fake-eland-wolfi .
$ docker run -it fake-eland-wolfi eland_import_hub_model --foo bar baz
success! ['/eland/venv/bin/eland_import_hub_model', '--foo', 'bar', 'baz']
```

## ❌ Using a Wolfi base image

```bash
$ docker build -f Dockerfile.wolfi -t fake-eland-wolfi .
$ docker run -it fake-eland-wolfi eland_import_hub_model --foo bar baz
/usr/bin/python: can't open file '//eland_import_hub_model': [Errno 2] No such file or directory
```

This suggests the entrypoint of the Wolfi image is Python, which ironically
does not know how to run that image.
