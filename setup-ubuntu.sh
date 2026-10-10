#!/usr/bin/env bash
#
# One-time setup for building BannerOffset with Theos on Ubuntu 22.04
# (for example inside NewTerm's Ubuntu 22.04 environment).
#
# Installs:
#   - build dependencies (apt)
#   - Theos (git clone into $THEOS, default ~/theos)
#   - the iOS Linux cross-toolchain (sbingner/llvm-project, includes ldid)
#   - the iPhoneOS 14.5 SDK (from theos/sdks)
#
# Usage:   ./setup-ubuntu.sh
# Env vars (optional):
#   THEOS=/path/to/theos      (default: $HOME/theos)
#   SDK_VERSION=14.5          (must match TARGET in Makefile)
#
set -euo pipefail

THEOS="${THEOS:-$HOME/theos}"
SDK_VERSION="${SDK_VERSION:-14.5}"
TOOLCHAIN_URL="https://github.com/sbingner/llvm-project/releases/download/v10.0.0-2/linux-ios-arm64e-clang-toolchain.tar.lzma"
TOOLCHAIN_DIR="$THEOS/toolchain/linux/iphone"

log() { printf '\n==> %s\n' "$*"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

# The prebuilt toolchain below is an x86_64 Linux binary.
ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ]; then
    echo "WARNING: this machine is $ARCH, but the prebuilt Linux iOS toolchain is x86_64." >&2
    echo "         If you already have an $ARCH-compatible iOS toolchain, place it in:" >&2
    echo "         $TOOLCHAIN_DIR/bin" >&2
    echo "         Otherwise, run this setup on an x86_64 Ubuntu 22.04 machine." >&2
fi

log "Installing apt dependencies"
$SUDO apt-get update
$SUDO apt-get install -y \
    build-essential fakeroot git perl libtinfo5 libio-compress-perl \
    curl unzip xz-utils lzma ca-certificates

log "Installing Theos into $THEOS"
if [ ! -f "$THEOS/makefiles/common.mk" ]; then
    if [ -d "$THEOS" ] && [ -n "$(ls -A "$THEOS" 2>/dev/null)" ]; then
        echo "ERROR: $THEOS exists and is not empty but is not a Theos checkout." >&2
        echo "       Move it aside or set THEOS=/some/other/path and re-run." >&2
        exit 1
    fi
    git clone --recursive https://github.com/theos/theos.git "$THEOS"
else
    git -C "$THEOS" submodule update --init --recursive
fi

log "Installing iOS Linux toolchain into $TOOLCHAIN_DIR"
if [ -x "$TOOLCHAIN_DIR/bin/clang-10" ] || [ -x "$TOOLCHAIN_DIR/bin/clang" ]; then
    echo "Toolchain already present, skipping download."
else
    TMP="$(mktemp -d)"
    curl -fL -o "$TMP/toolchain.tar.lzma" "$TOOLCHAIN_URL"
    mkdir -p "$TMP/extract"
    tar --lzma -xf "$TMP/toolchain.tar.lzma" -C "$TMP/extract"
    mkdir -p "$TOOLCHAIN_DIR"
    cp -a "$TMP/extract/ios-arm64e-clang-toolchain/." "$TOOLCHAIN_DIR/"
    rm -rf "$TMP"
fi

log "Installing iPhoneOS${SDK_VERSION}.sdk into $THEOS/sdks"
SDK_DIR="$THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk"
if [ -d "$SDK_DIR" ]; then
    echo "SDK already present, skipping download."
else
    TMP="$(mktemp -d)"
    git clone --depth 1 --filter=blob:none --sparse https://github.com/theos/sdks.git "$TMP/sdks"
    git -C "$TMP/sdks" sparse-checkout set "iPhoneOS${SDK_VERSION}.sdk"
    mkdir -p "$THEOS/sdks"
    cp -a "$TMP/sdks/iPhoneOS${SDK_VERSION}.sdk" "$THEOS/sdks/"
    rm -rf "$TMP"
fi

# Persist THEOS for future shells (only once).
if ! grep -qs "export THEOS=" "$HOME/.bashrc"; then
    echo "export THEOS=\"$THEOS\"" >> "$HOME/.bashrc"
fi

log "Setup complete"
echo "THEOS=$THEOS"
echo "Next: cd BannerOffset && ./build.sh"
