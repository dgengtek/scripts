FROM alpine:edge

ARG http_proxy
ARG author

ENV http_proxy=$http_proxy
ENV https_proxy=$http_proxy

LABEL author="github.com/$author"
LABEL description="custom scripts container for concourse build"

RUN echo -e "http_proxy=$http_proxy\nhttps_proxy=$https_proxy" >> /etc/environment \
  && apk update \
  && apk add bash python3 stow \
  && rm -rf /var/cache/*
