#!/usr/bin/env bash
# Verify every package in profiles/*/pacman and profiles/*/multilib exists in
# the official repos, and every profiles/*/jarch entry has a PKGBUILD.
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
# multilib lists, against a scratch copy of the sync databases with [multilib]
# on, so the system's pacman.conf stays as it is
if compgen -G 'profiles/*/multilib' >/dev/null; then
    ml="$(mktemp -d)"
    chmod 755 "$ml"  # pacman downloads as the unprivileged alpm user
    trap 'rm -rf "$ml"' EXIT
    sed '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf >"$ml/pacman.conf"
    grep -q '^\[multilib\]' "$ml/pacman.conf" || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >>"$ml/pacman.conf"
    mlpac=(pacman --config "$ml/pacman.conf" --dbpath "$ml/db")
    mkdir -p "$ml/db"
    "${mlpac[@]}" -Sy --noconfirm >/dev/null
    for list in profiles/*/multilib; do
        while read -r pkg; do
            if ! "${mlpac[@]}" -Si "$pkg" &>/dev/null; then
                echo "MISSING: $pkg ($list)"
                missing=$((missing + 1))
            fi
        done < <(read_list "$list")
    done
fi
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
