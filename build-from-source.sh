#!/usr/bin/env bash
# ==============================================================================
# Build NAM from Source with Modern Tcl/Tk 8.6 Patches
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Requires administrative privileges to install build dependencies."
    exec sudo bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/nam_build_src"

echo "Installing build prerequisites..."
apt-get update -y
apt-get install -y build-essential cmake debhelper libtclcl1-dev libotcl1-dev tcl8.6-dev tk8.6-dev libx11-dev libxext-dev libxmu-dev dpkg-dev

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Fetching upstream source..."
apt-get source nam || git clone https://salsa.debian.org/debian/nam.git nam-src

NAM_DIR=$(find . -maxdepth 1 -type d -name "nam*" | head -n 1)
cd "$NAM_DIR"

echo "Applying modern compatibility patch..."
patch -p1 < "$SCRIPT_DIR/patches/0001-fix-tcltk86-compatibility.patch" || true

# Ensure dummy tkUnixInit is omitted from CMake build
if [ -f "debian/CMakeLists.txt" ]; then
    sed -i '/tkUnixInit.c/d' debian/CMakeLists.txt
fi

echo "Building package..."
dpkg-buildpackage -us -uc -b

echo "Installing rebuilt binary..."
cd "$BUILD_DIR"
dpkg -i nam_*.deb || true
cp "$NAM_DIR/obj-"*/nam /usr/local/bin/nam 2>/dev/null || cp "$NAM_DIR"/nam /usr/local/bin/nam 2>/dev/null || true
chmod 755 /usr/local/bin/nam

# Re-apply holds
apt-mark hold nam ns2 2>/dev/null || true

echo "Build and installation complete!"
