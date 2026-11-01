#!/usr/bin/env bash
# Every profile has a jarch-meta-<profile> package (pkgbuilds/jarch-meta.sh),
# listed in its own jarch list, whose dependencies are exactly the profile's
# pacman and jarch lists (plus jarch-meta-base), with pacman groups expanded.
# Runs package() with pacman stubbed: no Arch needed, nothing installed.
set -euo pipefail
cd "$(dirname "$0")/.."
source install/lib/common.sh
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
# A stub pacman that knows one group, "jarch-test-group" (a b), and no packages by that name
cat >"$t/pacman" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    -Sg|-Sgq) if [[ -z "${2:-}" ]]; then printf 'jarch-test-group a\njarch-test-group b\n'; else printf 'a\nb\n'; fi ;;
    -Si) [[ "${2:-}" != jarch-test-group ]] ;;
esac
STUB
chmod +x "$t/pacman"

# meta_depends <dir> — the depends a jarch-meta PKGBUILD's package() produces
meta_depends() {
    (
        cd "$1"
        # shellcheck disable=SC2034  # read by the PKGBUILD
        startdir="$PWD"
        PATH="$t:$PATH"
        # shellcheck disable=SC1091
        source ./PKGBUILD
        package
        # shellcheck disable=SC2154  # set by package()
        printf '%s\n' "${depends[@]}"
    )
}

fail=0
check() { if eval "$2"; then ok "$1"; else err "$1"; fail=1; fi; }

for d in profiles/*/; do
    p="$(basename "$d")"
    meta="pkgbuilds/jarch-meta-$p"
    check "$p: has $meta/PKGBUILD" "[[ -f $meta/PKGBUILD ]]"
    [[ -f "$meta/PKGBUILD" ]] || continue
    check "$p: jarch list installs jarch-meta-$p" "read_list profiles/$p/jarch | grep -qx jarch-meta-$p"
    {
        [[ "$p" == base ]] || echo jarch-meta-base
        read_list "profiles/$p/pacman"
        read_list "profiles/$p/jarch" | grep -vx "jarch-meta-$p" || true
    } >"$t/want"
    meta_depends "$meta" >"$t/got"
    check "$p: jarch-meta-$p depends on exactly its lists" "diff -u $t/want $t/got"
done

# A group in a list becomes its members
mkdir -p "$t/repo/profiles/grp" "$t/repo/pkgbuilds/jarch-meta-grp"
printf 'git\njarch-test-group\n' >"$t/repo/profiles/grp/pacman"
cp pkgbuilds/jarch-meta.sh "$t/repo/pkgbuilds/"
sed 's/^_profile=.*/_profile=grp/' pkgbuilds/jarch-meta-base/PKGBUILD >"$t/repo/pkgbuilds/jarch-meta-grp/PKGBUILD"
check "groups expand to their members" "[[ \"\$(meta_depends $t/repo/pkgbuilds/jarch-meta-grp | tr '\n' ' ')\" == 'jarch-meta-base git a b ' ]]"
exit $fail
