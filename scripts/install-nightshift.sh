#!/usr/bin/env bash
set -euo pipefail

# Install Nightshift binary from GitHub releases

VERSION="${VERSION:-latest}"
REPO="marcus/nightshift"

# Detect OS and architecture
OS=""
ARCH=""

case "$(uname -s)" in
  Linux*)     OS="linux" ;;
  Darwin*)    OS="darwin" ;;
  CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
  *)          echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [[ "$OS" == "windows" ]]; then
  EXT="zip"
  BINARY="nightshift.exe"
else
  EXT="tar.gz"
  BINARY="nightshift"
fi

# Resolve version
if [[ "$VERSION" == "latest" ]]; then
  echo "Fetching latest release..."
  TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
else
  TAG="$VERSION"
fi

# Strip leading 'v' for asset filename (goreleaser uses raw version)
VERSION_NO_V="${TAG#v}"

echo "Installing nightshift ${TAG} for ${OS}_${ARCH}..."

ASSET="nightshift_${VERSION_NO_V}_${OS}_${ARCH}.${EXT}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${URL}..."
curl -fsSL -o "${TMPDIR}/${ASSET}" "$URL"

# Extract
if [[ "$EXT" == "tar.gz" ]]; then
  tar -xzf "${TMPDIR}/${ASSET}" -C "$TMPDIR"
else
  unzip -q "${TMPDIR}/${ASSET}" -d "$TMPDIR"
fi

# Find the binary
BINARY_PATH=$(find "$TMPDIR" -name "$BINARY" -type f | head -1)
if [[ -z "$BINARY_PATH" ]]; then
  echo "Error: could not find ${BINARY} in release archive" >&2
  exit 1
fi

# Install to a location on PATH
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"
cp "$BINARY_PATH" "${INSTALL_DIR}/${BINARY}"
chmod +x "${INSTALL_DIR}/${BINARY}"

# Add to PATH for current session
export PATH="${INSTALL_DIR}:${PATH}"
if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${INSTALL_DIR}" >> "$GITHUB_PATH"
fi

echo "nightshift installed: $(${BINARY} --version 2>/dev/null || echo 'version unknown')"

