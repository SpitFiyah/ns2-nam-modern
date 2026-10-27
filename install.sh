#!/usr/bin/env bash
# ==============================================================================
# NS-2 & NAM Modern Linux Automated Installer
# Maintained by SpitFiyah <mirafnan619@gmail.com>
# Supports: Ubuntu 20.04, 22.04, 24.04, 26.04+ (amd64 / Debian-based)
# ==============================================================================

set -e

export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   NS-2 & NAM (Network Animator) Modern Linux Setup   ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check for root / sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] This installer requires administrative privileges.${NC}"
    echo -e "    Restarting with sudo..."
    exec sudo bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Architecture verification
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [ "$ARCH" != "amd64" ] && [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}[X] Warning: Detected architecture '$ARCH'. Pre-built packages are for amd64.${NC}"
    echo -e "    If installation fails, run ./build-from-source.sh instead."
fi

echo -e "\n${BLUE}[1/5] Updating package cache and installing dependencies...${NC}"
apt-get update -y
apt-get install -y ns2 tcl8.6 tk8.6 libotcl1 libtclcl1 libx11-6 libxext6 libxmu6

echo -e "\n${BLUE}[2/5] Installing patched NAM package...${NC}"
if [ -f "$SCRIPT_DIR/deb/nam_1.15-11_amd64.deb" ]; then
    dpkg -i "$SCRIPT_DIR/deb/nam_1.15-11_amd64.deb" || apt-get install -f -y
else
    echo -e "${YELLOW}[!] Pre-built .deb not found, using binary fallback...${NC}"
    cp "$SCRIPT_DIR/bin/nam" /usr/bin/nam
    chmod 755 /usr/bin/nam
fi

echo -e "\n${BLUE}[3/5] Installing high-priority binary to /usr/local/bin...${NC}"
cp "$SCRIPT_DIR/bin/nam" /usr/local/bin/nam
chmod 755 /usr/local/bin/nam

# Test whether the binary can run on the host glibc
if ! /usr/local/bin/nam 2>&1 | grep -q -E "Usage: nam|invalid option"; then
    echo -e "${YELLOW}[!] Pre-built binary requires a different glibc version for this distribution.${NC}"
    echo -e "${BLUE}[*] Automatically building from source with modern patches...${NC}"
    "$SCRIPT_DIR/build-from-source.sh"
fi

echo -e "\n${BLUE}[4/5] Applying update protection locks...${NC}"
# Prevent apt-get upgrade from replacing patched nam and ns2
apt-mark hold nam ns2 >/dev/null 2>&1 || true

# APT pinning safeguard
cat << 'EOF' > /etc/apt/preferences.d/pin-nam.pref
Package: nam ns2
Pin: version *
Pin-Priority: 1001
EOF

echo -e "${GREEN}[✔] Update locks applied (held via apt-mark and /etc/apt/preferences.d/pin-nam.pref).${NC}"

echo -e "\n${BLUE}[5/5] Verifying installation...${NC}"
NS_PATH=$(which ns 2>/dev/null || true)
NAM_PATH=$(which nam 2>/dev/null || true)

if [ -n "$NS_PATH" ] && [ -n "$NAM_PATH" ]; then
    echo -e "${GREEN}[✔] NS-2 found at: $NS_PATH${NC}"
    echo -e "${GREEN}[✔] NAM found at:  $NAM_PATH${NC}"
    echo -e "\n${GREEN}======================================================${NC}"
    echo -e "${GREEN}  Installation Complete! NAM & NS-2 are ready to use. ${NC}"
    echo -e "${GREEN}======================================================${NC}"
    echo -e "\nTo test the animation immediately, run:"
    echo -e "  ${YELLOW}cd examples && ns lab_demo.tcl${NC}\n"
else
    echo -e "${RED}[X] Installation error: ns or nam binary was not found in PATH.${NC}"
    exit 1
fi
