# Allegro CL Express (Linux x86-64) for running lisp-check and make check.
#
# Franz's license doesn't allow redistributing Allegro, so the tarball is not in
# this repo. Download it from https://franz.com/downloads/clp/download and pass
# the folder that contains it as the "allegro" build context:
#
#   docker build --platform linux/amd64 --build-context allegro=$HOME/Downloads -t lisp-skills-allegro .
#   docker run --rm --platform linux/amd64 -v "$PWD":/work lisp-skills-allegro \
#     alisp -batch -e '(progn (print (+ 1 2)) (finish-output) (exit 0 :quiet t))'

FROM ubuntu:24.04

ARG ACL_TARBALL=acl11.0express-linux-x64.tbz2

RUN apt-get update \
    && apt-get install -y --no-install-recommends bzip2 make \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,from=allegro,source=${ACL_TARBALL},target=/tmp/acl.tbz2 \
    tar xjf /tmp/acl.tbz2 -C /opt

ENV PATH="/opt/acl11.0express.64:${PATH}"

WORKDIR /work
