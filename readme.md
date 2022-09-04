# Vessel Run

This repository contains the Docker image used as a base image for Vessel development environments.

The parts of this are:

1. A Rust project, based on [this article from Amos](https://fasterthanli.me/articles/remote-development-with-rust-on-fly-io)
2. Dockerfile that uses the Rust program as it's main program
    - It starts SSH 
    - It starts Supervisor (no Supervisord configuration here, it's used by images that use this as a base image)
    - It listens to the network for SSH connections and shuts down the VM after a period of inactivity

## Building and Deploying

This needs to be built on an AMD64 linux machine, as it's meant to be used within Fly.io (currently AMD64 only).

The resulting Docker image exists in Docker Hub and is used as the image run on Fly.io's infrastructure.

```bash
# Assuming run on Intel-based CPU
docker build -t vesselapp/base:latest .
```