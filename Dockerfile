FROM debian:stable-slim

# Explicit WireGuard version to install
ARG WIREGUARD_VERSION

# Disable prompts from apt.
ARG DEBIAN_FRONTEND=noninteractive

ENV WIREGUARD_HOST_ROOT /host
ENV HOME /root

# Add more deb repos, initialize apt
RUN \
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
    && apt-get update

# Install WireGuard, https://www.wireguard.com/install
RUN \
    echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-unstable \
    && apt-get update \
    && apt-get install -y --no-install-recommends wireguard=$WIREGUARD_VERSION

# Some base images have an empty /lib/modules by default
# If it's not empty, docker build will fail instead of
# silently overwriting the existing directory
RUN rm -df /lib/modules \
    && ln -s $WIREGUARD_HOST_ROOT/lib/modules /lib/modules

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["bash"]