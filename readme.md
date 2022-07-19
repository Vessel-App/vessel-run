# Vessel Run

This repository contains the Docker image used for PHP remote development.

The parts of this are:

1. A Rust project, based on [this article from Amos](https://fasterthanli.me/articles/remote-development-with-rust-on-fly-io)
2. Dockerfile that uses the Rust program as it's main program
    - It starts SSH 
    - It starts Supervisor (which in turn runs nginx/php-fpm)
    - It listens to the network for SSH connections and shuts down the VM after a period of inactivity

## Building and Deploying

The resulting Docker image used in this project should be uploaded to Fly's registry.

[This article](https://til.simonwillison.net/fly/fly-docker-registry) has notes on using Fly's registry.

The steps look like this:

```bash
# Auth against Fly's registry
# This upserts file ~/.docker/config.json (possibly differing on Linux vs Mac)
fly auth docker

# Build a docker image to push
docker build -t registry.fly.io/vessel-run:latest .

# Push the image to Fly's registry
docker push registry.fly.io/vessel-run:latest
```

The problem is that the image name needs to correspond to an existing app within your account.

So, we need to:

1. Create an app for each team in Vessel
2. Push a copy of the image to the repo for that app
3. When machines in that app are created and run, they can pull that image to start it
