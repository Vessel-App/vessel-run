# Vessel Run

This repository contains the Docker image used for PHP remote development.

The parts of this are:

1. A Rust project, based on [this article from Amos](https://fasterthanli.me/articles/remote-development-with-rust-on-fly-io)
2. Dockerfile that uses the Rust program as it's main program
    - It starts SSH 
    - It starts Supervisor (which in turn runs nginx/php-fpm)
    - It listens to the network for SSH connections and shuts down the VM after a period of inactivity

## Building and Deploying

This needs to be built on an AMD64 linux machine. Cross-compilation bugs) result in build failures related to Rust.

The resulting Docker image exists in Docker Hub and is used as the image run on Fly.io's infrastructure.

```bash
docker build -t vesselapp/php:8.1 .
```