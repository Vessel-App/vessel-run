#!/usr/bin/env bash

docker build -t vesselapp/base:latest .
docker push vesselapp/base:latest
