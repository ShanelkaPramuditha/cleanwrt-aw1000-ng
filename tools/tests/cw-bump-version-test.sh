#!/bin/sh
# cw-bump-version-test.sh - check what tools/cw-bump-version.sh guarantees.
#
#   usage: tools/tests/cw-bump-version-test.sh
#
# The guarantee: after a release is published, the build label moves to the next -SP<n> in
# both files that carry it, the changelog closes the released section and opens the next
# one, the docs name the release as the current version - and a second run, or a run on a
# branch that moved on already, changes nothing it should not.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUMP="$TESTS/../cw-bump-version.sh"
[ -f "$BUMP" ] || { echo "test: $BUMP is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

fail=0
noted() { printf '  %-60s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }

tree() { # <label in the build files> <changelog heading lines...>
	R="$WORK/r"; rm -rf "$R"
	mkdir -p "$R/tools" "$R/configs" "$R/docs" "$R/.github/ISSUE_TEMPLATE"
	printf 'OPENWRT_TAG="v25.12.5"\nCW_VERSION="%s"\n' "$1" > "$R/tools/cw-release-build.sh"
	printf '# seed\nCONFIG_VERSION_NUMBER="%s"\n' "$1" > "$R/configs/arcadyan_aw1000.seed"
	shift
	{ printf -- '---\ntitle: x\n---\n\n# Changelog\n\n'; for h in "$@"; do printf '%s\n\n- an entry\n\n' "$h"; done; } > "$R/docs/changelog.md"
	printf "This fork's current version is \`25.12.5-R2.2-SP1\`: upstream's, marked by the \`-SP1\` suffix.\n" > "$R/docs/index.md"
	printf '            "softwareVersion": "25.12.5-R2.2-SP1",\n' > "$R/tools/docs-hooks.py"
	printf '      placeholder: CleanWRT 25.12.5-R2.2-SP1\n' > "$R/.github/ISSUE_TEMPLATE/bug_report.yml"
}
label() { sed -n 's/^CW_VERSION="\(.*\)"$/\1/p' "$R/tools/cw-release-build.sh"; }
seedl() { sed -n 's/^CONFIG_VERSION_NUMBER="\(.*\)"$/\1/p' "$R/configs/arcadyan_aw1000.seed"; }
heads() { grep '^## ' "$R/docs/changelog.md" | tr '\n' '|'; }
bump() { CW_REPO="$R" sh "$BUMP" "$@" > /dev/null; }

echo "after SP1 is published:"
tree 25.12.5-R2.2-SP1 "## 25.12.5-R2.2-SP1 (this fork, not yet released)" "## 25.12.5-R2.2"
bump --released 25.12.5-R2.2-SP1
is "the build script moves to SP2" "$(label)" 25.12.5-R2.2-SP2
is "the seed moves with it" "$(seedl)" 25.12.5-R2.2-SP2
is "changelog: SP2 opens, SP1 is released" "$(heads)" \
	"## 25.12.5-R2.2-SP2 (this fork, not yet released)|## 25.12.5-R2.2-SP1|## 25.12.5-R2.2|"
is "the new section is empty" "$(awk '/^## /{n++} n==1 && /^- /' "$R/docs/changelog.md" | wc -l | tr -d ' ')" 0

echo "a second run:"
cp -r "$R" "$WORK/before"
bump --released 25.12.5-R2.2-SP1
diff -r "$WORK/before" "$R" > /dev/null && noted "changes nothing" ok || noted "changes nothing" "FAIL: files changed"

echo "after SP2 is published:"
bump --released 25.12.5-R2.2-SP2
is "the label moves to SP3" "$(label)/$(seedl)" 25.12.5-R2.2-SP3/25.12.5-R2.2-SP3
is "the docs name SP2 as current" "$(grep -o '`[^`]*`' "$R/docs/index.md" | tr '\n' ' ')" '`25.12.5-R2.2-SP2` `-SP2` '
is "the site names SP2" "$(sed -n 's/.*"softwareVersion": "\([^"]*\)".*/\1/p' "$R/tools/docs-hooks.py")" 25.12.5-R2.2-SP2
is "the issue template names SP2" "$(sed -n 's/.*placeholder: CleanWRT //p' "$R/.github/ISSUE_TEMPLATE/bug_report.yml")" 25.12.5-R2.2-SP2
is "SP10 follows SP9" "$(tree 25.12.5-R2.2-SP9 "## 25.12.5-R2.2-SP9 (this fork, not yet released)"; bump --released 25.12.5-R2.2-SP9; label)" 25.12.5-R2.2-SP10

echo "edge cases:"
tree 25.12.5-R2.3 "## 25.12.5-R2.3 (this fork, not yet released)"
bump --released 25.12.5-R2.3
is "a label without -SP starts SP1" "$(label)" 25.12.5-R2.3-SP1
tree 25.12.5-R2.2-SP3 "## 25.12.5-R2.2-SP3 (this fork, not yet released)" "## 25.12.5-R2.2-SP2 (this fork, not yet released)"
bump --released 25.12.5-R2.2-SP2
is "a branch already past the release keeps its label" "$(label)/$(seedl)" 25.12.5-R2.2-SP3/25.12.5-R2.2-SP3
is "  and its open section is not doubled" "$(heads)" \
	"## 25.12.5-R2.2-SP3 (this fork, not yet released)|## 25.12.5-R2.2-SP2|"
tree 25.12.5-R2.2-SP1 "## 25.12.5-R2.2-SP1 (this fork, not yet released)"
CW_REPO="$R" sh "$BUMP" --released 'x;rm -rf /' > /dev/null 2>&1 && noted "a label with shell characters is refused" "FAIL: accepted" ||
	noted "a label with shell characters is refused" ok
CW_REPO="$R" sh "$BUMP" > /dev/null 2>&1 && noted "no --released: usage, nothing changed" "FAIL: ran" ||
	is "no --released: usage, nothing changed" "$(label)" 25.12.5-R2.2-SP1

echo
[ "$fail" = 0 ] && echo "bump-version: all cases passed" || { echo "bump-version: failures above" >&2; exit 1; }
