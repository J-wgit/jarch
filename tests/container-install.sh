#!/usr/bin/env bash
# Run a real jarch-install inside a throwaway archlinux container, then
# re-run it to prove it's idempotent and check the results.
# Usage: tests/container-install.sh [profiles=base]
#
# JARCH_TEST_REPO=DIR installs Jarch's packages from a [jarch] repo built into
# DIR (by .github/scripts/build-repo.sh). If DIR/jarch.asc exists, the repo is
# signed with that key and the test trusts it the way keys/jarch.asc would be.
# Without it, whatever jarch.conf points at is used (the published repo, or a
# local build from pkgbuilds/ if that can't be reached).
set -euo pipefail
cd "$(dirname "$0")/.."
profiles="${1:-base}"

# Behind a TLS-intercepting proxy, set JARCH_TEST_CA to its CA bundle
ca_args=() ca_setup=:
if [[ -n "${JARCH_TEST_CA:-}" ]]; then
    ca_args=(-v "$JARCH_TEST_CA:/etc/ca-certificates/trust-source/anchors/test-ca.crt:ro")
    ca_setup=update-ca-trust
fi

repo_args=() repo_setup=: expect=any
if [[ -n "${JARCH_TEST_REPO:-}" ]]; then
    repo_args=(-v "$(realpath "$JARCH_TEST_REPO"):/jarch-repo:ro")
    repo_setup="mkdir -p /home/tester/.config/jarch
        echo 'JARCH_REPO_SERVER=file:///jarch-repo' > /home/tester/.config/jarch/jarch.conf
        if [[ -f /jarch-repo/jarch.asc ]]; then install -Dm644 /jarch-repo/jarch.asc /home/tester/.jarch/keys/jarch.asc; fi
        chown -R tester: /home/tester"
    expect=repo
fi

docker run --rm "${ca_args[@]}" "${repo_args[@]}" -v "$PWD:/src:ro" archlinux:latest bash -euo pipefail -c "
    $ca_setup
    pacman -Syu --noconfirm --needed sudo git >/dev/null
    useradd -m -G wheel tester
    echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester
    # a pre-existing file the installer must back up, not clobber
    echo 'old bashrc' > /home/tester/.bashrc
    cp -r /src /home/tester/.jarch && chown -R tester: /home/tester
    $repo_setup

    su - tester -c '~/.jarch/install/jarch-install --yes --profile $profiles'
    echo '===== second run (must be a clean no-op) ====='
    su - tester -c '~/.jarch/install/jarch-install --yes --profile $profiles'

    su - tester -c '~/.jarch/tests/verify.sh $profiles $expect'
"
