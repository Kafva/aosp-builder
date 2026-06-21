FROM docker.io/ubuntu:26.04

ARG BUILDER_UID=${BUILDER_UID:-1000}
ARG BUILDER_GID=${BUILDER_GID:-1000}
ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
apt-get update
apt-get install -y \
    sudo \
    build-essential \
    curl \
    git \
    zstd \
    m4 \
    python3 \
    python3-dev \
    zip \
    make \
    ccache

rm -rf /var/lib/apt/
rm -rf /var/cache/apt/
EOF

# Create build user with matching UID/GID to outside user
RUN userdel ubuntu
RUN groupadd -g ${BUILDER_GID} _builder || :
RUN useradd --uid ${BUILDER_UID} --gid ${BUILDER_GID} --create-home --shell /bin/bash builder

# Make it easy to install more packages for debugging
RUN echo "builder ALL=NOPASSWD: ALL" > /etc/sudoers.d/builder

USER builder
WORKDIR /src
VOLUME /src

# Git configuration
RUN git config --global user.email "builder@googlesource.com"
RUN git config --global user.name "builder"
RUN git config --global remote.origin.prune true
RUN git config --global fetch.prune true
RUN git config --global commit.gpgsign false
