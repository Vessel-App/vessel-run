# syntax = docker/dockerfile:1.4

################################################################################
# Let's just make our own Rust builder image based on ubuntu:20.04 to avoid
# any libc version problems
FROM ubuntu:20.04 AS builder

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
ENV NVM_VERSION=v0.39.1

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
			nginx supervisor; \
        gosu nobody true; \
		apt clean autoclean; \
		apt autoremove --yes; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/; \
        sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen;


RUN set -eux; \
		useradd -ms /usr/bin/bash vessel; \
		usermod -aG sudo vessel; \
		echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

# Note that we've changed the `ListenAddress` here from `0.0.0.0` to
# `127.0.0.2`. It's not really necessary but it's neat that 127.0.0.1 is a /8.
RUN set -eux; \
		echo "Port 2222" >> /etc/ssh/sshd_config; \
		echo "AddressFamily inet" >> /etc/ssh/sshd_config; \
		echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config; \
		echo "PasswordAuthentication no" >> /etc/ssh/sshd_config; \
		echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config; \
		echo "ClientAliveCountMax 10" >> /etc/ssh/sshd_config;

# Install PHP and friends
RUN echo "Set disable_coredump false" >> /etc/sudo.conf \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php8.1-fpm php8.1-cli \
       php8.1-pgsql php8.1-sqlite3 php8.1-gd \
       php8.1-curl php8.1-memcached \
       php8.1-imap php8.1-mysql php8.1-mbstring \
       php8.1-xml php8.1-zip php8.1-bcmath php8.1-soap \
       php8.1-intl php8.1-readline php8.1-xdebug \
       php8.1-msgpack php8.1-igbinary  php8.1-imagick \
       php8.1-ldap php8.1-gmp php8.1-redis php8.1-pcov \
    && php -r "readfile('http://getcomposer.org/installer');" | php8.1 -- --install-dir=/usr/bin/ --filename=composer \
    && mkdir /run/php \
    && phpdismod -v ALL -s cli xdebug pcov \
    && sed -i 's/^user =.*$/user = vessel/g' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i 's/^group =.*$/group = vessel/g' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i 's/^listen.owner =.*$/listen.owner = vessel/g' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i 's/^listen.group =.*$/listen.group = vessel/g' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i 's/^;clear_env =.*$/clear_env = no/g' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i 's/^display_errors = .*/display_errors = On/g' /etc/php/8.1/fpm/php.ini \
    && sed -i 's/^display_errors = .*/display_errors = On/g' /etc/php/8.1/cli/php.ini \
    \
    && sed -i 's/^user.*$/user vessel;/g' /etc/nginx/nginx.conf


USER vessel
WORKDIR /home/vessel

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | bash \
    && bash -c 'source $HOME/.nvm/nvm.sh \
        && nvm install --latest-npm 14 \
        && nvm alias default 14 \
        && nvm use default \
        && nvm install-latest-npm \
        && curl -o- -L https://yarnpkg.com/install.sh | bash'

WORKDIR /app

COPY --from=builder /app/vessel-run ./vessel-run

USER root

COPY docker/entrypoint /app/entrypoint
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN chmod +x /app/entrypoint \
    && apt-get clean autoclean \
	&& apt-get autoremove --yes \
	&& rm -rf /var/lib/{apt,dpkg,cache,log}/

ENTRYPOINT /app/entrypoint
CMD ["/app/vessel-run"]
