# syntax = docker/dockerfile:1.4

################################################################################
# Make our own Rust builder image based on ubuntu:20.04 to avoid
# any libc version problems
FROM ubuntu:20.04 AS builder

LABEL fly_launch_runtime="vessel"

# Install base utils: curl to grab rustup, gcc + build-essential for linking.
# we could probably reduce that a bit but /shrug
RUN set -eux; \
		export DEBIAN_FRONTEND=noninteractive; \
		apt update; \
		apt install --yes --no-install-recommends \
			curl ca-certificates \
			gcc build-essential \
			; \
		apt clean autoclean; \
		apt autoremove --yes; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/; \
		echo "Installed base utils!"

# Install rustup
RUN set -eux; \
        curl --location --fail \
            "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init" \
            --output rustup-init; \
		chmod +x rustup-init; \
		./rustup-init -y --no-modify-path; \
		rm rustup-init;

# Add rustup to path, check that it works
ENV PATH=${PATH}:/root/.cargo/bin
RUN set -eux; \
		rustup --version;

# Build some code!
WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/app/target \
    --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    --mount=type=cache,target=/root/.rustup \
    set -eux; \
    rustup install stable; \
    cargo build --release; \
    objcopy --compress-debug-sections target/release/vessel-run ./vessel-run




################################################################################
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN set -eux; \
        ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
        echo $TZ > /etc/timezone; \
	    apt update; \
		apt install --yes --no-install-recommends \
			locales gnupg gosu zip unzip sqlite3 libtool automake rsync \
            bind9-dnsutils iputils-ping iproute2 ca-certificates htop \
			curl wget ca-certificates git-core \
			openssh-server openssh-client \
			sudo less vim \
            software-properties-common \
			supervisor; \
        gosu nobody true; \
		apt clean autoclean; \
		apt autoremove --yes; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/; \
        sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen; \
        mkdir -p /app; \
		useradd -ms /usr/bin/bash vessel; \
		usermod -aG sudo vessel; \
		echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

# Note that we're listening on port 2222
RUN set -eux; \
		echo "Port 2222" >> /etc/ssh/sshd_config; \
		echo "AddressFamily inet" >> /etc/ssh/sshd_config; \
		echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config; \
		echo "PasswordAuthentication no" >> /etc/ssh/sshd_config; \
		echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config; \
		echo "ClientAliveCountMax 10" >> /etc/ssh/sshd_config;


COPY --from=builder /app/vessel-run /app/vessel-run
COPY docker/entrypoint /app/entrypoint

RUN chmod +x /app/entrypoint

ENTRYPOINT ["/app/entrypoint"]
