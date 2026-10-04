#!/usr/bin/env bash
# Run a real jarch-install inside a throwaway archlinux container, then
# re-run it to prove it's idempotent and check the results.
# Usage: tests/container-install.sh [profiles=base]
set -euo pipefail
cd "$(dirname "$0")/.."
profiles="${1:-base}"

# Behind a TLS-intercepting proxy, set JARCH_TEST_CA to its CA bundle
ca_args=() ca_setup=:
if [[ -n "${JARCH_TEST_CA:-}" ]]; then
    ca_args=(-v "$JARCH_TEST_CA:/etc/ca-certificates/trust-source/anchors/test-ca.crt:ro")
    ca_setup=update-ca-trust
fi

docker run --rm "${ca_args[@]}" -v "$PWD:/src:ro" archlinux:latest bash -euo pipefail -c "
    $ca_setup
    pacman -Syu --noconfirm --needed sudo git >/dev/null
    useradd -m -G wheel tester
    echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester
    # a pre-existing file the installer must back up, not clobber
    echo 'old bashrc' > /home/tester/.bashrc
    cp -r /src /home/tester/.jarch && chown -R tester: /home/tester

    su - tester -c '~/.jarch/install/jarch-install --yes --profile $profiles'
    echo '===== second run (must be a clean no-op) ====='
    su - tester -c '~/.jarch/install/jarch-install --yes --profile $profiles'

    su - tester -c '~/.jarch/tests/verify.sh $profiles'
"
