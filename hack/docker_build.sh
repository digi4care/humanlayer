#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  hack/docker_build.sh <ubuntu|debian|arch> -- <command>

Examples:
  hack/docker_build.sh ubuntu -- make setup
  hack/docker_build.sh debian -- make check-test
  hack/docker_build.sh arch -- make codelayer-nightly-bundle-linux

Notes:
- Artifacts will be written into your working tree (bind-mounted into the container).
- Build caches are stored in ./.docker-cache/ (gitignored).
- This is intended for build/packaging reproducibility across distros.
EOF
}

if [ "$#" -lt 3 ]; then
  usage
  exit 2
fi

DISTRO="$1"
shift

if [ "$1" != "--" ]; then
  usage
  exit 2
fi
shift

SERVICE="build-${DISTRO}"

case "$DISTRO" in
  ubuntu|debian|arch)
    ;;
  *)
    echo "Unknown distro: $DISTRO" >&2
    usage
    exit 2
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found" >&2
  exit 1
fi

# Ensure cache dirs exist (so bind mounts work)
mkdir -p \
  ./.docker-cache/tauri \
  ./.docker-cache/cargo-registry \
  ./.docker-cache/cargo-git \
  ./.docker-cache/go-pkg-mod \
  ./.docker-cache/bun-cache

export LOCAL_UID
export LOCAL_GID
LOCAL_UID="$(id -u)"
LOCAL_GID="$(id -g)"

# Build image (uses LOCAL_UID/LOCAL_GID build args)
docker compose -f docker-compose.build.yml build "$SERVICE"

# Run command
CMD="$*"
docker compose -f docker-compose.build.yml run --rm -T "$SERVICE" bash -lc "$CMD"
