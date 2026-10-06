#!/usr/bin/env bash
# Build pkgbuilds/ into a [jarch] pacman repo. Runs as root in an archlinux
# container (CI); makepkg itself runs as an unprivileged "builder" user.
#
#   build-repo.sh [OUT_DIR]       (default out/repo)
#
# Environment:
#   JARCH_SIGNING_KEY   armored private GPG key (no passphrase): sign packages and the db
#   JARCH_TEST_SIGN=1   sign with a throwaway key instead, and export its public
#                       key to OUT_DIR/jarch.asc (for the install test)
#   REBUILD=1           rebuild packages already in OUT_DIR's database
set -euo pipefail
cd "$(dirname "$0")/../.."
out="${1:-out/repo}"

pacman -Syu --noconfirm --needed base-devel git >/dev/null
id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/builder
mkdir -p "$out"
chown -R builder: . "$out"
as_builder() { sudo -u builder -H "$@"; }
as_builder git config --global --add safe.directory '*'

# Jarch's own packages count commits for their version; a shallow clone would
# make versions go backwards
if [[ "${JARCH_REQUIRE_HISTORY:-0}" == 1 && "$(as_builder git rev-parse --is-shallow-repository)" == true ]]; then
    echo "Need the full git history (actions/checkout with fetch-depth: 0)" >&2
    exit 1
fi

sign=()
if [[ -n "${JARCH_SIGNING_KEY:-}" ]]; then
    as_builder gpg --batch --import <<<"$JARCH_SIGNING_KEY"
elif [[ "${JARCH_TEST_SIGN:-0}" == 1 ]]; then
    as_builder gpg --batch --passphrase '' --quick-gen-key 'Jarch CI test key <ci@jarch.invalid>' ed25519 sign never
fi
key="$(as_builder gpg --batch --with-colons --list-secret-keys 2>/dev/null | awk -F: '/^fpr/ { print $10; exit }')"
if [[ -n "$key" ]]; then
    sign=(--sign "$key")
    as_builder gpg --batch --armor --export "$key" >"$out/jarch.asc"
    echo "Signing with $key"
fi

as_builder tools/jarch-pkg/jarch-pkg build --out "$out" "${sign[@]}" ${REBUILD:+--rebuild}
ls -l "$out"
