#!/bin/sh
# cw-build.sh - build the image on your own machine with one command, and watch it.
#
#   usage: tools/cw-build.sh [--clean | --dirclean | --check] [--defaults | --same] [--tree <openwrt-tree>]
#
#   no flag      incremental build: only what changed is rebuilt
#   --clean      rebuild every package, keep the toolchain
#   --dirclean   rebuild everything, the toolchain included
#   --check      feed, patch, pin and config checks only, nothing is compiled
#   --defaults   no questions: the stock defaults (OpenWrt, 192.168.1.1, Wi-Fi 'OpenWrt' / password123)
#   --same       no questions: the values you gave last time
#   --tree DIR   the OpenWrt tree (default: openwrt next to this repository)
#
# Before a build starts it asks for the router's defaults: hostname, LAN address, Wi-Fi names
# and Wi-Fi password. Enter keeps the value shown; with nothing changed the image is the stock
# one. Your values are built into the image (a reset brings them back) and offered again next
# time from <cw>/.cw-build-settings (mode 600: it holds the Wi-Fi password). Without a terminal,
# or with CW_HOSTNAME, CW_LAN_IP, CW_SSID, CW_SSID_2G, CW_SSID_5G or CW_WIFI_KEY set, nothing is
# asked and those variables (or the stock defaults) are used.
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
ASK=
while [ $# -gt 0 ]; do
	case "$1" in
	--clean | --dirclean) MODE=$1 ;;
	--check) MODE=check ;;
	--defaults | --same) ASK=${1#--} ;;
	--tree) shift; TREE=${1:?--tree needs a directory} ;;
	-h | --help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*) echo "cw-build: unknown option '$1' (see --help)" >&2; exit 2 ;;
	esac
	shift
done
CW=$(dirname "$REPO")
[ -n "$TREE" ] || TREE="$CW/openwrt"
LOG="$CW/build.log"
PIDF="$CW/.cw-build.pid"
SETF="$CW/.cw-build-settings"      # your answers, offered again next time
SCRIPTF="$CW/.cw-build-settings.sh" # the first-boot script made from them, for the build

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

# ── The router's defaults: asked here, built into the image ─────────────────────────────────
# Stock values: what the image ships when nothing is changed (docs/first-boot.md).
# Wi-Fi is on with D_KEY (files/etc/uci-defaults/56-cw-wifi-default-key).
D_HOST=OpenWrt D_LAN=192.168.1.1 D_SSID=OpenWrt D_KEY=password123

sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

save_settings() {
	( umask 077
	  { echo "# tools/cw-build.sh: the answers of the last build. Holds the Wi-Fi password."
	    echo "S_HOST=$(sq "$S_HOST")"; echo "S_LAN=$(sq "$S_LAN")"
	    echo "S_SSID2=$(sq "$S_SSID2")"; echo "S_SSID5=$(sq "$S_SSID5")"; echo "S_KEY=$(sq "$S_KEY")"
	  } > "$SETF" )
}

show_settings() {
	say "    hostname     $S_HOST"
	say "    LAN address  $S_LAN"
	if [ "$S_KEY" = "$D_KEY" ]; then
		say "    Wi-Fi        2.4 GHz '$S_SSID2'   5 GHz '$S_SSID5'   password: stock ($D_KEY)"
	else
		say "    Wi-Fi        2.4 GHz '$S_SSID2'   5 GHz '$S_SSID5'   password: your own"
	fi
}

# The first-boot script, through tools/cw-settings-pack.sh (one place for the validation and
# the uci commands). Nothing changed from stock: no script, the stock image. Fails with the
# tool's message on a bad value.
make_script() {
	set --
	[ "$S_HOST" = "$D_HOST" ] || set -- "$@" --hostname "$S_HOST"
	case "$S_LAN" in "$D_LAN" | "$D_LAN/24") ;; *) set -- "$@" --lan-ip "$S_LAN" ;; esac
	if [ "$S_SSID2" != "$D_SSID" ] || [ "$S_SSID5" != "$D_SSID" ]; then
		if [ "$S_SSID2" = "$S_SSID5" ]; then
			set -- "$@" --ssid "$S_SSID2"
		else
			set -- "$@" --ssid-2g "$S_SSID2" --ssid-5g "$S_SSID5"
		fi
	fi
	[ "$S_KEY" = "$D_KEY" ] || set -- "$@" --key "$S_KEY"
	rm -f "$SCRIPTF"
	[ $# -gt 0 ] || return 0
	sh "$REPO/tools/cw-settings-pack.sh" "$@" --script "$SCRIPTF"
}

ask() { # <prompt> <current>: prints the answer, the current value on Enter
	printf '  %s [%s]: ' "$1" "$2" >/dev/tty
	read -r a </dev/tty || a=
	printf '%s' "${a:-$2}"
}

ask_key() { # hidden; Enter keeps the current one
	while :; do
		if [ "$S_KEY" = "$D_KEY" ]; then
			printf '  Wi-Fi password [Enter keeps the stock %s]: ' "$D_KEY" >/dev/tty
		else
			printf '  Wi-Fi password [Enter keeps your saved one]: ' >/dev/tty
		fi
		stty -echo </dev/tty 2>/dev/null; read -r k </dev/tty || k=; stty echo </dev/tty 2>/dev/null; echo >/dev/tty
		[ -n "$k" ] || return 0
		printf '  Again, to confirm: ' >/dev/tty
		stty -echo </dev/tty 2>/dev/null; read -r k2 </dev/tty || k2=; stty echo </dev/tty 2>/dev/null; echo >/dev/tty
		[ "$k" = "$k2" ] && { S_KEY=$k; return 0; }
		say "  ${Y}The two did not match.${N}"
	done
}

settings() {
	S_HOST=$D_HOST S_LAN=$D_LAN S_SSID2=$D_SSID S_SSID5=$D_SSID S_KEY=$D_KEY
	saved=0
	# shellcheck disable=SC1090
	[ -f "$SETF" ] && . "$SETF" && saved=1
	# saved before Wi-Fi had a stock password: no password then meant the stock one
	[ -n "$S_KEY" ] || S_KEY=$D_KEY

	# From the environment, without questions (scripts, CI-like use)
	if [ -n "${CW_HOSTNAME:-}${CW_LAN_IP:-}${CW_SSID:-}${CW_SSID_2G:-}${CW_SSID_5G:-}${CW_WIFI_KEY:-}" ]; then
		S_HOST=${CW_HOSTNAME:-$D_HOST} S_LAN=${CW_LAN_IP:-$D_LAN}
		S_SSID2=${CW_SSID_2G:-${CW_SSID:-$D_SSID}} S_SSID5=${CW_SSID_5G:-${CW_SSID:-$D_SSID}} S_KEY=${CW_WIFI_KEY:-$D_KEY}
		ASK=env
	fi
	case "$ASK" in
	defaults) S_HOST=$D_HOST S_LAN=$D_LAN S_SSID2=$D_SSID S_SSID5=$D_SSID S_KEY=$D_KEY ;;
	same | env) ;;
	*)
		if ! { [ -t 0 ] && [ -r /dev/tty ]; }; then
			# no terminal to ask on: the stock image, unless --same
			S_HOST=$D_HOST S_LAN=$D_LAN S_SSID2=$D_SSID S_SSID5=$D_SSID S_KEY=$D_KEY
		else
			trap 'stty echo </dev/tty 2>/dev/null; printf "\n\n  Stopped; nothing was started.\n\n"; exit 130' INT
			say "  ${B}The router's defaults${N} ${D}(built into the image; a reset brings them back)${N}"
			if [ "$saved" = 1 ]; then
				say "  ${D}Last time:${N}"
				show_settings
				printf '  Use these again? [Y]es, [c]hange, stock [d]efaults: ' >/dev/tty
				read -r a </dev/tty || a=
				case "$a" in
				[cC]*) saved=0 ;;
				[dD]*) S_HOST=$D_HOST S_LAN=$D_LAN S_SSID2=$D_SSID S_SSID5=$D_SSID S_KEY=$D_KEY ;;
				esac
			fi
			if [ "$saved" = 0 ]; then
				say "  ${D}Enter keeps the value in brackets.${N}"
				while :; do
					S_HOST=$(ask "Hostname" "$S_HOST")
					S_LAN=$(ask "LAN address (e.g. 192.168.50.1 or 192.168.50.1/24)" "$S_LAN")
					S_SSID2=$(ask "Wi-Fi name, 2.4 GHz" "$S_SSID2")
					S_SSID5=$(ask "Wi-Fi name, 5 GHz" "$S_SSID5")
					ask_key
					if make_script; then
						say ""
						show_settings
						printf '  Build with these? [Y/n]: ' >/dev/tty
						read -r a </dev/tty || a=
						case "$a" in [nN]*) say "" ;; *) break ;; esac
					else
						say "  ${D}Again: Enter keeps what you typed.${N}"
					fi
				done
			fi
			trap - INT
			say ""
		fi
		;;
	esac

	make_script || exit 2
	if [ ! -f "$SCRIPTF" ]; then   # nothing differs from stock
		rm -f "$SETF"
		say "  Defaults: ${B}stock${N} ${D}(OpenWrt, 192.168.1.1, Wi-Fi 'OpenWrt' with password $D_KEY)${N}"
	else
		[ "$ASK" = env ] || save_settings
		say "  Defaults: ${B}your own${N}, built into the image:"
		show_settings
		[ "$S_KEY" = "$D_KEY" ] && say "  ${D}A reset brings these values back.${N}" ||
			say "  ${D}The image holds your Wi-Fi password: don't share it. A reset brings these values back.${N}"
	fi
	say ""
}

[ "$MODE" = check ] || settings

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
	CW_LOCAL_SETTINGS="$( [ "$MODE" != check ] && [ -f "$SCRIPTF" ] && echo "$SCRIPTF" || true)" \
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
