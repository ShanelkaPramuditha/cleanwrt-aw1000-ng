#!/bin/sh
# cw-bump-version.sh - move the repository to the next version label after a release.
#
#   usage: tools/cw-bump-version.sh --released <label>
#
# Run by the release workflow right after it publishes v<label>, so the default branch is
# always one label ahead of the newest tag and the next draft build can never name a
# release that is published already. Run it by hand the same way if a release was published
# without the workflow.
#
# What it changes, all at once, so the files never disagree:
#   - docs/changelog.md: "## <label> (this fork, not yet released)" becomes "## <label>", and
#     an empty "## <next> (this fork, not yet released)" section opens above it. The build's
#     release checks refuse a draft until that section has at least one entry.
#   - the places that name the current released version: docs/index.md, the site's
#     softwareVersion (tools/docs-hooks.py) and the issue-template placeholders.
#   - the build label: CW_VERSION in tools/cw-release-build.sh and CONFIG_VERSION_NUMBER in
#     configs/arcadyan_aw1000.seed, to <next>, but only while they still say <label>. A branch
#     that has moved on already (someone bumped by hand) keeps its label.
#
# <next> is <label> with its -SP<n> raised by one, or <label>-SP1 when <label> has no -SP
# (an upstream label such as 25.12.5-R2.3, after merging a new upstream release).
#
# Running it twice for the same label changes nothing the second time.
# CW_REPO points it at another checkout (tools/tests/cw-bump-version-test.sh uses that).
set -eu

REPO=${CW_REPO:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
[ "${1:-}" = --released ] && [ -n "${2:-}" ] || { sed -n '4p' "$0" | sed 's/^# *//' >&2; exit 2; }
rel=$2
case "$rel" in
	*[!A-Za-z0-9._-]* | -*) echo "cw-bump-version: '$rel' is not a version label" >&2; exit 2 ;;
esac

case "$rel" in
	*-SP[0-9]*)
		n=${rel##*-SP}
		case "$n" in *[!0-9]*) echo "cw-bump-version: cannot read the -SP number of '$rel'" >&2; exit 2 ;; esac
		next="${rel%-SP*}-SP$((n + 1))"
		;;
	*) next="$rel-SP1" ;;
esac

SCRIPT="$REPO/tools/cw-release-build.sh"
SEED="$REPO/configs/arcadyan_aw1000.seed"
LOG="$REPO/docs/changelog.md"
for f in "$SCRIPT" "$SEED" "$LOG"; do [ -f "$f" ] || { echo "cw-bump-version: $f is missing" >&2; exit 1; }; done
cur=$(sed -n 's/^CW_VERSION="\(.*\)"$/\1/p' "$SCRIPT")

# sed's regex needs the dots of a label escaped
re() { printf '%s' "$1" | sed 's/[.]/\\./g'; }

# 1. the changelog: close the released section, open the next one
pending=" (this fork, not yet released)"
sed -i "s/^## $(re "$rel")$(re "$pending")\$/## $rel/" "$LOG"
if ! grep -q "^## $(re "$next")\( \|\$\)" "$LOG"; then
	awk -v h="## $next$pending" '!done && /^## / { print h; print ""; done = 1 } { print }' "$LOG" > "$LOG.tmp"
	mv "$LOG.tmp" "$LOG"
fi

# 2. the current released version, wherever the docs and the site name it
if [ -f "$REPO/docs/index.md" ]; then
	sed -i -E "s/^(This fork's current version is \`)[^\`]*(\`)/\1$rel\2/" "$REPO/docs/index.md"
	case "$rel" in *-SP[0-9]*)
		sed -i -E "s/(marked by the \`)-SP[0-9]+(\` suffix)/\1-SP${rel##*-SP}\2/" "$REPO/docs/index.md" ;;
	esac
fi
[ -f "$REPO/tools/docs-hooks.py" ] &&
	sed -i -E "s/(\"softwareVersion\": \")[^\"]*(\")/\1$rel\2/" "$REPO/tools/docs-hooks.py"
for t in "$REPO"/.github/ISSUE_TEMPLATE/*.yml; do
	[ -f "$t" ] && sed -i -E "s/(placeholder: CleanWRT )[0-9][A-Za-z0-9._-]*/\1$rel/" "$t"
done

# 3. the build label, which must stay the same in both files
if [ "$cur" = "$rel" ]; then
	sed -i "s/^CW_VERSION=\"$(re "$rel")\"\$/CW_VERSION=\"$next\"/" "$SCRIPT"
	sed -i "s/^CONFIG_VERSION_NUMBER=\"$(re "$rel")\"\$/CONFIG_VERSION_NUMBER=\"$next\"/" "$SEED"
	echo "version: $rel -> $next"
else
	echo "version: the build label is $cur, not $rel - left as it is"
fi
