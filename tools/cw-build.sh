#!/bin/sh
# cw-build.sh - build the image on your own machine with one command, and watch it.
#
#   usage: tools/cw-build.sh [--clean | --dirclean | --check] [--tree <openwrt-tree>]
#
#   no flag      incremental build: only what changed is rebuilt
#   --clean      rebuild every package, keep the toolchain
#   --dirclean   rebuild everything, the toolchain included
#   --check      feed, patch, pin and config checks only, nothing is compiled
#   --tree DIR   the OpenWrt tree (default: openwrt next to this repository)
#
# It works out every path from where the repository is, so it is the same from your own shell
# or a root shell (where ~ is /root). It clones the OpenWrt tree at the pinned tag when there
# is none, starts tools/cw-release-build.sh as root and detached from the terminal (closing the
# window does not stop it), writes the whole output to <cw>/build.log, and shows the progress
# with tools/cw-build-progress.sh. Ctrl+C stops only the display; run this again and it attaches
# to the build that is running instead of starting a second one. At the end it prints where
# the image is, its size and its sha256, or the lines around the error.
#
# The local defaults are the ones the docs give: CW_MAX_IMAGE_MB=130, CW_BUILD_OPT_ARTIFACTS=0
# (the optional cw-opt feed is not built), CW_CCACHE=1. Each can be overridden from the
# environment.
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TREE=
MODE=
while [ $# -gt 0 ]; do
	case "$1" in
	--clean | --dirclean) MODE=$1 ;;
	--check) MODE=check ;;
	--tree) shift; TREE=${1:?--tree needs a directory} ;;
	-h | --help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*) echo "cw-build: unknown option '$1' (see --help)" >&2; exit 2 ;;
	esac
	shift
done
CW=$(dirname "$REPO")
[ -n "$TREE" ] || TREE="$CW/openwrt"
LOG="$CW/build.log"
PIDF="$CW/.cw-build.pid"

if [ -t 1 ]; then
	B=$(printf '\033[1m') D=$(printf '\033[2m') G=$(printf '\033[32m') Y=$(printf '\033[33m')
	R=$(printf '\033[31m') C=$(printf '\033[36m') N=$(printf '\033[0m')
else
	B= D= G= Y= R= C= N=
fi
say() { printf '%s\n' "$*"; }

TAG=$(sed -n 's/^OPENWRT_TAG="\(.*\)"$/\1/p' "$REPO/tools/cw-release-build.sh")
VER=$(sed -n 's/^CW_VERSION="\(.*\)"$/\1/p' "$REPO/tools/cw-release-build.sh")
OUT="$TREE/bin/targets/qualcommax/ipq807x"

banner() {
	say ""
	say "  ${B}${C}CleanWRT${N} ${B}$VER${N}  ${D}for the Arcadyan AW1000, on OpenWrt $TAG${N}"
	say "  ${D}repository${N}  $REPO"
	say "  ${D}tree      ${N}  $TREE"
	say "  ${D}log       ${N}  $LOG"
	say ""
}

running() { # the pid of a build this script started, when it is still alive
	[ -s "$PIDF" ] || return 1
	pid=$(cat "$PIDF")
	kill -0 "$pid" 2>/dev/null && return 0
	# kill -0 is refused for another user's process (a root build seen from your shell)
	[ -d "/proc/$pid" ] && grep -q cw-release-build "/proc/$pid/cmdline" 2>/dev/null
}

summary() {
	rc=$1
	say ""
	if [ "$rc" = 0 ] && grep -q '^== CW_CHECK_ONLY=1: .* passed' "$LOG" 2>/dev/null; then
		say "  ${G}${B}Checks passed.${N} ${D}Feeds, patches, pins and the config compose; nothing was compiled.${N}"
	elif [ "$rc" = 0 ]; then
		img=$(ls "$OUT"/*-squashfs-sysupgrade.bin 2>/dev/null | head -1)
		if [ -n "$img" ]; then
			size=$(du -h "$img" | cut -f1)
			sum=$(sha256sum "$img" | cut -d' ' -f1)
			say "  ${G}${B}Build finished.${N}"
			say ""
			say "  ${D}image ${N}  $img"
			say "  ${D}size  ${N}  $size"
			say "  ${D}sha256${N}  $sum"
			say ""
			say "  ${D}Copy it somewhere else before the next build: each build clears that folder.${N}"
		else
			say "  ${G}${B}Done.${N} ${D}(no image: that was a check run, or see $LOG)${N}"
		fi
		grep -q "the tree's feed key is not the release key" "$LOG" 2>/dev/null &&
			say "  ${D}Release key note in the log: normal for a local build, the image is fine to flash.${N}"
	else
		say "  ${R}${B}The build stopped with an error.${N} The lines around it:"
		say ""
		# the first ERROR line and what led up to it; else the end of the log
		line=$(grep -n -m1 -E '^ERROR|^make.*Error [0-9]|error:' "$LOG" 2>/dev/null | cut -d: -f1)
		if [ -n "$line" ]; then
			from=$((line > 15 ? line - 15 : 1))
			sed -n "${from},$((line + 5))p" "$LOG" | sed 's/^/    /'
		else
			tail -n 25 "$LOG" | sed 's/^/    /'
		fi
		say ""
		say "  ${D}Whole log: $LOG${N}"
	fi
	say ""
}

banner

# Ctrl+C: the build runs in its own session and does not get it; only the display stops.
trap 'printf "\n\n  %sDisplay stopped; the build goes on.%s Run tools/cw-build.sh again to watch it.\n\n" "$D" "$N"; exit 130' INT

# Attach to a build that is running already.
if running; then
	say "  ${Y}A build is running already${N} (pid $(cat "$PIDF")); showing its progress."
	say "  ${D}Ctrl+C stops only this display. Run this command again to come back.${N}"
	say ""
	set +e
	CW_PIDFILE="$PIDF" sh "$REPO/tools/cw-build-progress.sh" "$LOG" "$TREE"
	rc=$?
	set -e
	[ "$rc" = 130 ] || summary "$rc"
	exit "$rc"
fi

# The tree: cloned at the pinned tag when there is none. A tree at another tag is the user's to
# replace (it may hold hours of build state), so that only stops with the command to run.
if [ ! -f "$TREE/scripts/feeds" ]; then
	say "  No OpenWrt tree at $TREE: cloning $TAG (a few hundred MB)..."
	git clone --depth 1 --branch "$TAG" https://github.com/openwrt/openwrt.git "$TREE"
	say ""
fi
have=$(git -C "$TREE" describe --tags --exact-match 2>/dev/null || echo "?")
if [ "$have" != "$TAG" ]; then
	say "  ${R}The tree is at $have, this repository builds $TAG.${N}"
	say "  Replace it:  rm -rf '$TREE' && tools/cw-build.sh   (the next build starts from scratch)"
	exit 1
fi

# Disk space: a full build needs tens of GB.
free=$(df -Pk "$TREE" | awk 'NR == 2 { print int($4 / 1048576) }')
[ "${free:-0}" -lt 25 ] &&
	say "  ${Y}Only ${free} GB free under $TREE.${N} ${D}A first build needs about 50 GB; it may run out.${N}"

# Start the build as root, detached: setsid puts it in its own session, so neither Ctrl+C here
# nor closing the terminal reaches it.
as_root=
[ "$(id -u)" = 0 ] || as_root=sudo
case "$MODE" in
check) set -- ; checkonly=1 ;;
"") set -- ; checkonly=0 ;;
*) set -- "$MODE"; checkonly=0 ;;
esac
say "  Starting the ${B}${MODE:-incremental}${N} build ${D}(sudo may ask for your password)${N}"
$as_root true
: > "$LOG" 2>/dev/null || $as_root sh -c ": > '$LOG'; chmod 644 '$LOG'"
$as_root env -u TERM \
	CW_MAX_IMAGE_MB="${CW_MAX_IMAGE_MB:-130}" \
	CW_BUILD_OPT_ARTIFACTS="${CW_BUILD_OPT_ARTIFACTS:-0}" \
	CW_CCACHE="${CW_CCACHE:-1}" \
	CW_CHECK_ONLY="$checkonly" \
	CW_PIDFILE="$PIDF" CW_LOG="$LOG" CW_TREE="$TREE" CW_REPO="$REPO" \
	setsid sh -c 'echo $$ > "$CW_PIDFILE"; exec "$CW_REPO/tools/cw-release-build.sh" "$CW_TREE" "$@" < /dev/null >> "$CW_LOG" 2>&1' sh "$@" &
n=0
while [ ! -s "$PIDF" ] && [ "$n" -lt 20 ]; do sleep 0.5; n=$((n + 1)); done
say "  ${D}Running in the background (pid $(cat "$PIDF" 2>/dev/null || echo ?)). Ctrl+C stops only this display;${N}"
say "  ${D}run tools/cw-build.sh again to come back to it.${N}"
say ""

set +e
CW_PIDFILE="$PIDF" sh "$REPO/tools/cw-build-progress.sh" "$LOG" "$TREE"
rc=$?
set -e
[ "$rc" = 130 ] || summary "$rc"
exit "$rc"
