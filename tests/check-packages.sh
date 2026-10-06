#!/usr/bin/env bash
# Verify every package in profiles/*/pacman exists in the official repos,
# and every profiles/*/jarch entry has a PKGBUILD.
# Runs inside an Arch container (CI) or on an Arch machine.
set -euo pipefail
cd "$(dirname "$0")/.."
source install/lib/common.sh

pacman -Sy --noconfirm >/dev/null
missing=0
for list in profiles/*/pacman; do
    while read -r pkg; do
        if ! pacman -Si "$pkg" &>/dev/null && ! pacman -Sg "$pkg" &>/dev/null; then
            echo "MISSING: $pkg ($list)"
            missing=$((missing + 1))
        fi
    done < <(read_list "$list")
done
for list in profiles/*/jarch; do
    [[ -f "$list" ]] || continue
    while read -r pkg; do
        if [[ ! -f "pkgbuilds/$pkg/PKGBUILD" ]]; then
            echo "MISSING: $pkg ($list has no pkgbuilds/$pkg/PKGBUILD)"
            missing=$((missing + 1))
        fi
    done < <(read_list "$list")
done
[[ $missing -eq 0 ]] && echo "All listed packages exist." || exit 1
