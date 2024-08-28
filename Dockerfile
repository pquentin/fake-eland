# syntax=docker/dockerfile:1
FROM python:3.10-slim

WORKDIR /eland

ENV VIRTUAL_ENV=/eland/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ADD eland_import_hub_model $VIRTUAL_ENV/bin
