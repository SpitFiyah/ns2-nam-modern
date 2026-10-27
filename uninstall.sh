#!/usr/bin/env bash
# ==============================================================================
# Uninstaller for NS-2 & NAM Modern Linux Setup
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo/root access."
    exec sudo bash "$0" "$@"
fi

echo "Removing update locks..."
apt-mark unhold nam ns2 2>/dev/null || true
rm -f /etc/apt/preferences.d/pin-nam.pref

echo "Removing local nam binary..."
rm -f /usr/local/bin/nam

echo "Done. (Note: ns2 and system packages were not removed; run 'sudo apt purge ns2 nam' if desired)."
