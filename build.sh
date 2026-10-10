#!/usr/bin/env bash
#
# Builds the rootless BannerOffset .deb (com.sonic125.banneroffset).
# Output: packages/com.sonic125.banneroffset_<version>_iphoneos-arm64.deb
#
# Usage: ./build.sh
#
set -euo pipefail

cd "$(dirname "$0")"
export THEOS="${THEOS:-$HOME/theos}"

if [ ! -f "$THEOS/makefiles/common.mk" ]; then
    echo "Theos not found at $THEOS. Run ./setup-ubuntu.sh first." >&2
    exit 1
fi

make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

echo
echo "Built package(s):"
ls -1 packages/*.deb
