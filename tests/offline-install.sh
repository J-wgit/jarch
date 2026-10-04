#!/usr/bin/env bash
# Offline end-to-end test: runs the real installer in an Ubuntu container with
# pacman/makepkg/systemctl stubbed, twice, then checks dotfiles, backups,
# idempotence and the recorded calls. Use this where Arch mirrors are unreachable;
# tests/container-install.sh is the real thing.
set -euo pipefail
cd "$(dirname "$0")/.."
profiles="${1:-base,desktop,dev}"

docker run --rm -v "$PWD:/src:ro" -e DEBIAN_FRONTEND=noninteractive ubuntu:24.04 bash -euo pipefail -c "
    apt-get update -qq >/dev/null && apt-get install -y -qq stow sudo git python3 >/dev/null
    touch /etc/arch-release
    printf '[options]\n#Color\n#ParallelDownloads = 5\n' > /etc/pacman.conf
    useradd -m -s /bin/sh tester
    echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester
    echo 'old bashrc' > /home/tester/.bashrc
    cp -r /src /home/tester/.jarch && chown -R tester: /home/tester
    install -d -o tester /stub/bin && cp /src/tests/stubs/* /stub/bin/
    touch /stub/log /stub/db && chmod 666 /stub/log /stub/db && chown -R tester /stub
    # sudo keeps PATH so stubs win
    sed -i 's/^Defaults\s*secure_path/#&/' /etc/sudoers
    echo 'Defaults env_keep += \"STUB_LOG STUB_DB STUB_BIN\"' > /etc/sudoers.d/stubs
    run='env PATH=/stub/bin:\$PATH STUB_BIN=/stub/bin STUB_LOG=/stub/log STUB_DB=/stub/db ~/.jarch/install/jarch-install --yes --profile $profiles'
    echo '===== dry run (must change nothing) ====='
    cp /etc/pacman.conf /tmp/pacman.conf.orig
    su - tester -c 'find ~ -not -path \"*/.local*\" | sort' > /tmp/home.before
    su - tester -c \"\$run --dry-run\" 2>&1 | tee /tmp/dry.out
    su - tester -c 'find ~ -not -path \"*/.local*\" | sort' > /tmp/home.after
    diff /tmp/home.before /tmp/home.after
    cmp /etc/pacman.conf /tmp/pacman.conf.orig
    ! grep -q 'ERR' /tmp/dry.out
    ! grep -qv '^systemctl is-enabled' /stub/log  # only read-only calls
    echo '===== first run ====='
    su - tester -c \"\$run\"
    cp /stub/log /stub/log.first && : > /stub/log
    echo '===== second run ====='
    su - tester -c \"\$run\"
    su - tester -c '~/.jarch/tests/offline-verify.sh $profiles'
"
