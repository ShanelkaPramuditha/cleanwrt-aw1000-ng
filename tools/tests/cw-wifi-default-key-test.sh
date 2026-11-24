#!/bin/sh
# cw-wifi-default-key-test.sh - check what 56-cw-wifi-default-key guarantees.
#
#   usage: tools/tests/cw-wifi-default-key-test.sh
#
# The guarantee: OpenWrt's generated network (named 'OpenWrt', open, off) comes up on with
# WPA2 and the password 'password123' (WPA3 on 6 GHz), its radio on; a network someone has
# configured - another name, a key, any encryption - is never touched.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$TESTS/../../files/etc/uci-defaults/56-cw-wifi-default-key"
[ -f "$SCRIPT" ] || { echo "test: $SCRIPT is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
# uci: a flat store in `uci show` format, as in cw-settings-pack-test.sh
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
st="$UCI_STATE"
pick() { awk -v p="$1" 'index($0, p) == 1' "$st"; }
drop() { awk -v k="$1" 'index($0, k "=") != 1' "$st" > "$st.n"; mv "$st.n" "$st"; }
[ "$1" = "-q" ] && shift
case "$1" in
	show) pick "$2." ;;
	get)  v=$(pick "$2=" | head -1); [ -n "$v" ] || exit 1; v=${v#*=}; v=${v#\'}; printf '%s\n' "${v%\'}" ;;
	set)  k=${2%%=*}; v=${2#*=}; drop "$k"; printf "%s='%s'\n" "$k" "$v" >> "$st" ;;
	commit) echo "commit $2" >> "$st.commits" ;;
esac
exit 0
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/uci" "$WORK/bin/logger"
UCI_STATE="$WORK/state"; export UCI_STATE

fail=0
noted() { printf '  %-58s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }
get() { PATH="$WORK/bin:$PATH" uci -q get "$1" || :; }
run() { rm -f "$UCI_STATE.commits"; PATH="$WORK/bin:$PATH" sh "$SCRIPT"; }
commits() { [ -f "$UCI_STATE.commits" ] && tr '\n' '|' < "$UCI_STATE.commits" || :; }

radio() { # <name> <band> <ssid> <encryption> [key]: one radio and its network
	printf '%s\n' "wireless.$1=wifi-device" "wireless.$1.band='$2'" \
		"wireless.default_$1=wifi-iface" "wireless.default_$1.device='$1'" \
		"wireless.default_$1.ssid='$3'" "wireless.default_$1.encryption='$4'" \
		"wireless.default_$1.disabled='1'" >> "$UCI_STATE"
	[ -z "${5:-}" ] || echo "wireless.default_$1.key='$5'" >> "$UCI_STATE"
}

echo "== a fresh flash: the generated networks"
: > "$UCI_STATE"; radio radio0 5g OpenWrt none; radio radio1 2g OpenWrt none
run
is "5 GHz: WPA2" "$(get wireless.default_radio0.encryption)" psk2
is "5 GHz: the password" "$(get wireless.default_radio0.key)" password123
is "5 GHz: on" "$(get wireless.default_radio0.disabled)" 0
is "5 GHz radio: on" "$(get wireless.radio0.disabled)" 0
is "2.4 GHz: WPA2, password, on" "$(get wireless.default_radio1.encryption)/$(get wireless.default_radio1.key)/$(get wireless.default_radio1.disabled)" psk2/password123/0
is "name kept" "$(get wireless.default_radio1.ssid)" OpenWrt
is "committed once" "$(commits)" "commit wireless|"

echo "== 6 GHz"
: > "$UCI_STATE"; radio radio2 6g OpenWrt none
run
is "WPA3, as 6 GHz requires" "$(get wireless.default_radio2.encryption)" sae

echo "== configured networks are left alone"
: > "$UCI_STATE"
radio radio0 5g MyWiFi none                 # renamed, still open
radio radio1 2g OpenWrt psk2 own-secret     # the name kept, a key set
radio radio3 2g OpenWrt sae                 # encryption chosen
run
is "renamed open network: still off, open" "$(get wireless.default_radio0.disabled)/$(get wireless.default_radio0.encryption)" 1/none
is "own key: untouched" "$(get wireless.default_radio1.key)/$(get wireless.default_radio1.disabled)" own-secret/1
is "own encryption: untouched" "$(get wireless.default_radio3.encryption)/$(get wireless.default_radio3.disabled)" sae/1
is "nothing committed" "$(commits)" ""

echo "== no Wi-Fi at all"
: > "$UCI_STATE"
run
is "nothing committed" "$(commits)" ""

[ "$fail" = 0 ] && echo "cw-wifi-default-key: all checks passed" || { echo "cw-wifi-default-key: FAILED" >&2; exit 1; }
