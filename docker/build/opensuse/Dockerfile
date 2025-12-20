FROM opensuse/tumbleweed:latest

ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG NODE_VERSION=22.0.0
ARG GO_VERSION=1.24.0
ARG BUN_VERSION=1.2.23
ARG RUST_TOOLCHAIN=stable

RUN zypper -n ref \
  && zypper -n up \
  && zypper -n in --no-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    tar \
    gzip \
    xz \
    unzip \
    file \
    bash \
    xdg-utils \
    pkg-config \
    cmake \
    python3 \
    clang \
    clang-devel \
    webkit2gtk3-devel \
    libopenssl-devel \
    libappindicator3-1 \
    librsvg-devel \
    patchelf \
    squashfs \
    desktop-file-utils \
    appstream \
    dpkg \
    fakeroot \
  && zypper -n in -t pattern devel_basis \
  && zypper clean -a

# Non-root user that matches the host UID/GID (for correct file ownership on bind mounts)
RUN groupadd --gid ${LOCAL_GID} builder \
  && useradd --uid ${LOCAL_UID} --gid ${LOCAL_GID} --create-home --shell /bin/bash builder

# Go
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
  | tar -C /usr/local -xz

# Node.js (pinned version, includes npm)
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
  | tar -C /usr/local --strip-components=1 -xJ

# Bun (pinned version)
ENV BUN_INSTALL=/opt/bun
RUN mkdir -p "$BUN_INSTALL" \
  && curl -fsSL https://bun.com/install | bash -s "bun-v${BUN_VERSION}" \
  && ln -sf "$BUN_INSTALL/bin/bun" /usr/local/bin/bun

# Rust
ENV CARGO_HOME=/opt/cargo
ENV RUSTUP_HOME=/opt/rustup
RUN mkdir -p "$CARGO_HOME" "$RUSTUP_HOME" \
  && curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "$RUST_TOOLCHAIN" \
  && "$CARGO_HOME/bin/rustup" component add rustfmt clippy

ENV PATH=/usr/local/go/bin:/opt/go/bin:/opt/cargo/bin:/opt/bun/bin:$PATH

WORKDIR /workspace

RUN mkdir -p /opt/cache /opt/go/pkg/mod /opt/bun/install/cache \
  && chown -R builder:builder /opt/cache /opt/cargo /opt/rustup /opt/go /opt/bun

USER builder

CMD ["bash", "-lc", "bash"]
