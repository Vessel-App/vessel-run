#!/usr/bin/env bash

set -eux

docker build -t vesselapp/base:latest .
docker push vesselapp/base:latest
