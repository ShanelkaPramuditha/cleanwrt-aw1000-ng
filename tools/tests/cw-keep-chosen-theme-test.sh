#!/bin/sh
# cw-keep-chosen-theme-test.sh - check what 29-cw-keep-chosen-theme guarantees.
#
#   usage: tools/tests/cw-keep-chosen-theme-test.sh
#
# The guarantee: a router upgraded with its settings kept stays on the theme it had,
# although Vantage's own first-boot script selects Vantage whenever its theme entry is
# new; and a fresh flash still opens in Vantage. Each case runs the first-boot chain the
# image runs, in name order: 29-cw-keep-chosen-theme, Vantage's 30_luci-theme-vantage
# (modelled below on its rule at the pinned v1.2.0, the package is not in this
# repository), then 96-cw-default-theme. The outcome checked is the base LuCI ends on.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KEEP="$TESTS/../../files/etc/uci-defaults/29-cw-keep-chosen-theme"
DEF="$TESTS/../../files/etc/uci-defaults/96-cw-default-theme"
for f in "$KEEP" "$DEF"; do [ -f "$f" ] || { echo "test: $f is missing" >&2; exit 1; }; done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"

# uci over a key=value file (the same stand-in as cw-default-theme-test.sh).
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
[ "$1" = "-q" ] && shift
case "$1" in
get)
	line=$(grep "^$2=" "$CFG" 2>/dev/null | head -1)
	[ -n "$line" ] || exit 1
	printf '%s\n' "${line#*=}"
	exit 0 ;;
show)
	sed -n "s|^\($2\.[^=]*=.*\)$|\1|p" "$CFG" | sed "s|=\(.*\)$|='\1'|"
	exit 0 ;;
delete)
	grep -v "^$2=" "$CFG" > "$CFG.tmp" 2>/dev/null || :
	mv "$CFG.tmp" "$CFG"; exit 0 ;;
set)
	key=${2%%=*}; val=${2#*=}
	grep -v "^$key=" "$CFG" > "$CFG.tmp" 2>/dev/null || :
	mv "$CFG.tmp" "$CFG"
	printf '%s=%s\n' "$key" "$val" >> "$CFG"; exit 0 ;;
commit) exit 0 ;;
esac
exit 1
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/uci" "$WORK/bin/logger"

# Vantage's 30_luci-theme-vantage @ v1.2.0: register, and select only when the entry is new.
cat > "$WORK/30_luci-theme-vantage" <<'V'
new=0
[ -n "$(uci -q get luci.themes.Vantage)" ] || new=1
uci -q set luci.themes.Vantage=/luci-static/vantage
[ "${PKG_UPGRADE:-}" != 1 ] && [ "$new" = 1 ] && uci -q set luci.main.mediaurlbase=/luci-static/vantage
uci -q commit luci
exit 0
V

fail=0
noted() { printf '  %-62s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }

case_run() { # <what> <expected base> <config lines> [extra-dir...]
	what=$1; want=$2; cfg=$3; shift 3
	ROOT="$WORK/root"; rm -rf "$ROOT"
	mkdir -p "$ROOT/etc/config"
	for d in bootstrap footstrap vantage "$@"; do mkdir -p "$ROOT/www/luci-static/$d"; done
	printf '%s\n' "$cfg" > "$ROOT/etc/config/luci"
	for s in "$KEEP" "$WORK/30_luci-theme-vantage" "$DEF"; do
		CFG="$ROOT/etc/config/luci" CW_ROOT="$ROOT" PATH="$WORK/bin:$PATH" sh "$s"
	done
	got=$(sed -n 's/^luci\.main\.mediaurlbase=//p' "$ROOT/etc/config/luci")
	reg=$(sed -n 's/^luci\.themes\.Vantage=//p' "$ROOT/etc/config/luci")
	if [ "$got" != "$want" ]; then noted "$what" "FAIL: base [$got], expected [$want]"
	elif [ "$reg" != /luci-static/vantage ]; then noted "$what" "FAIL: Vantage not in the design list"
	else noted "$what" ok; fi
}

echo "a fresh flash:"
case_run "the stock bootstrap base opens in Vantage" /luci-static/vantage \
	"luci.main.mediaurlbase=/luci-static/bootstrap
luci.themes.Bootstrap=/luci-static/bootstrap"
case_run "no base at all opens in Vantage" /luci-static/vantage ""

echo "an upgrade that kept the settings:"
case_run "a router on Footstrap stays on Footstrap" /luci-static/footstrap \
	"luci.main.mediaurlbase=/luci-static/footstrap
luci.themes.Footstrap=/luci-static/footstrap"
case_run "a router on another installed theme stays on it" /luci-static/custom \
	"luci.main.mediaurlbase=/luci-static/custom" custom
case_run "a base whose theme is gone moves to Vantage" /luci-static/vantage \
	"luci.main.mediaurlbase=/luci-static/argon
luci.themes.Argon=/luci-static/argon"
case_run "a router already on Vantage stays on it" /luci-static/vantage \
	"luci.main.mediaurlbase=/luci-static/vantage
luci.themes.Vantage=/luci-static/vantage"

echo "what must not happen:"
rm -rf "$WORK/nov"; mkdir -p "$WORK/nov/etc/config" "$WORK/nov/www/luci-static/footstrap"
printf 'luci.main.mediaurlbase=/luci-static/footstrap\n' > "$WORK/nov/etc/config/luci"
CFG="$WORK/nov/etc/config/luci" CW_ROOT="$WORK/nov" PATH="$WORK/bin:$PATH" sh "$KEEP"
grep -q '^luci\.themes\.Vantage=' "$WORK/nov/etc/config/luci" &&
	noted "Vantage not installed: no entry is written" "FAIL: an entry for a missing theme" ||
	noted "Vantage not installed: no entry is written" ok

echo
[ "$fail" = 0 ] && echo "keep-chosen-theme: all cases passed" || { echo "keep-chosen-theme: failures above" >&2; exit 1; }
