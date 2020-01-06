FROM docker.p.intranet.dgeng.eu/python:pip-3.8-slim-buster as scripts

ARG http_proxy
ARG author

ENV http_proxy=$http_proxy
ENV https_proxy=$http_proxy

LABEL author="github.com/$author"
LABEL description="scripts container"

RUN set -x \
  && useradd -m uscripts \
  && apt-get update \
  && apt-get install -y bash stow git make

ADD . /scripts/


FROM scripts

USER uscripts
ENV PATH=$PATH:/home/uscripts/.local/bin
RUN set -x \
  && make -C /scripts install
