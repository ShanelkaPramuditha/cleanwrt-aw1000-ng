#!/bin/sh
# cw-settings-pack-test.sh - check what tools/cw-settings-pack.sh guarantees.
#
#   usage: tools/tests/cw-settings-pack-test.sh
#
# The guarantee: the archive holds exactly one executable first-boot script that sorts after the
# image's own; run against a stock config it sets the hostname, the LAN address (as a list entry
# with a prefix) and, per band, the Wi-Fi name, WPA2 (WPA3 on 6 GHz), the key and the radio on;
# values with quotes survive intact; anything left out stays untouched; and bad values, or a
# Wi-Fi name without a key, are refused before any archive is written.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACK="$TESTS/../cw-settings-pack.sh"
[ -f "$PACK" ] || { echo "test: $PACK is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
# uci: a flat store in `uci show` format (key=type for sections, key='value' for options)
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
st="$UCI_STATE"
# keys hold [ ] and dots, so lines are matched as plain strings, never as patterns
pick() { awk -v p="$1" 'index($0, p) == 1' "$st"; }        # lines starting with <p>
drop() { awk -v k="$1" 'index($0, k "=") != 1 && index($0, k "+=") != 1' "$st" > "$st.n"; mv "$st.n" "$st"; }
[ "$1" = "-q" ] && shift
case "$1" in
	show) pick "$2." ;;
	get)  v=$(pick "$2=" | head -1); [ -n "$v" ] || exit 1; v=${v#*=}; v=${v#\'}; printf '%s\n' "${v%\'}" ;;
	set)  k=${2%%=*}; v=${2#*=}; drop "$k"; printf "%s='%s'\n" "$k" "$v" >> "$st" ;;
	add_list) k=${2%%=*}; v=${2#*=}; printf "%s+='%s'\n" "$k" "$v" >> "$st" ;;
	delete) drop "$2" ;;
	commit) echo "commit $2" >> "$st.commits" ;;
esac
exit 0
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/uci" "$WORK/bin/logger"

fail=0
noted() { printf '  %-58s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }

stock() { # the config a fresh 25.12 flash of a two-radio board has when uci-defaults run
	UCI_STATE="$WORK/state"; export UCI_STATE
	rm -f "$UCI_STATE.commits"
	cat > "$UCI_STATE" <<'EOF'
system.cfg01=system
system.@system[0].hostname='OpenWrt'
network.lan=interface
network.lan.ipaddr+='192.168.1.1/24'
wireless.radio0=wifi-device
wireless.radio0.band='5g'
wireless.radio0.disabled='1'
wireless.default_radio0=wifi-iface
wireless.default_radio0.device='radio0'
wireless.default_radio0.ssid='OpenWrt'
wireless.default_radio0.encryption='none'
wireless.default_radio0.disabled='1'
wireless.radio1=wifi-device
wireless.radio1.band='2g'
wireless.radio1.disabled='1'
wireless.default_radio1=wifi-iface
wireless.default_radio1.device='radio1'
wireless.default_radio1.ssid='OpenWrt'
wireless.default_radio1.encryption='none'
wireless.default_radio1.disabled='1'
EOF
}
get() { PATH="$WORK/bin:$PATH" uci -q get "$1"; }
apply() { # <archive>: unpack it and run its script against the stock store
	rm -rf "$WORK/x"; mkdir "$WORK/x"; tar -C "$WORK/x" -xzf "$1"
	PATH="$WORK/bin:$PATH" sh "$WORK/x/etc/uci-defaults/zz-cw-my-settings"
}
pack() { sh "$PACK" "$@" >/dev/null 2>"$WORK/err"; }

echo "== full settings"
pack --hostname MyRouter --lan-ip 192.168.50.1 --ssid "Bob's WiFi" --ssid-2g Home-2G --key "pa'ss w0rd!" -o "$WORK/a.tar.gz"
is "archive holds only the one script" "$(tar -tzf "$WORK/a.tar.gz" | grep -v '/$' | tr '\n' ' ')" "etc/uci-defaults/zz-cw-my-settings "
stock; apply "$WORK/a.tar.gz"
is "script is executable" "$([ -x "$WORK/x/etc/uci-defaults/zz-cw-my-settings" ] && echo yes)" yes
is "script sorts after the image's own" "$(printf '99_zz-cw-nikki-defaults\n99-aw1000-defaults\nzz-cw-my-settings\n' | LC_ALL=C sort | tail -1)" zz-cw-my-settings
is "hostname" "$(get system.@system[0].hostname)" MyRouter
is "LAN address replaced, /24 added" "$(grep '^network.lan.ipaddr' "$UCI_STATE" | tr '\n' ' ')" "network.lan.ipaddr+='192.168.50.1/24' "
is "5 GHz name from --ssid, quote intact" "$(get wireless.default_radio0.ssid)" "Bob's WiFi"
is "2.4 GHz name from --ssid-2g" "$(get wireless.default_radio1.ssid)" Home-2G
is "key, quote intact" "$(get wireless.default_radio1.key)" "pa'ss w0rd!"
is "WPA2" "$(get wireless.default_radio0.encryption)" psk2
is "interfaces on" "$(get wireless.default_radio0.disabled)$(get wireless.default_radio1.disabled)" 00
is "radios on" "$(get wireless.radio0.disabled)$(get wireless.radio1.disabled)" 00
is "each changed config committed" "$(sort -u "$UCI_STATE.commits" | tr '\n' ' ')" "commit network commit system commit wireless "

echo "== only a key"
pack --key 12345678 -o "$WORK/b.tar.gz"
stock; apply "$WORK/b.tar.gz"
is "name stays the stock one" "$(get wireless.default_radio0.ssid)" OpenWrt
is "Wi-Fi secured and on" "$(get wireless.default_radio0.encryption)$(get wireless.default_radio0.disabled)" psk20
is "hostname untouched" "$(get system.@system[0].hostname)" OpenWrt
is "LAN untouched" "$(grep '^network.lan.ipaddr' "$UCI_STATE")" "network.lan.ipaddr+='192.168.1.1/24'"

echo "== only a hostname"
pack --hostname edge-01 -o "$WORK/c.tar.gz"
stock; apply "$WORK/c.tar.gz"
is "hostname" "$(get system.@system[0].hostname)" edge-01
is "Wi-Fi left off" "$(get wireless.radio0.disabled)$(get wireless.default_radio0.encryption)" 1none

echo "== refusals (and no archive written)"
refused() { # <label> <args...>
	label=$1; shift
	rm -f "$WORK/r.tar.gz"
	if pack "$@" -o "$WORK/r.tar.gz"; then noted "$label" "FAIL: accepted"
	elif [ -e "$WORK/r.tar.gz" ]; then noted "$label" "FAIL: archive written"
	else noted "$label" ok; fi
}
refused "Wi-Fi name without a key" --ssid Open
refused "short key" --key 1234567
refused "64 characters, not hex" --key "$(printf 'g%.0s' $(seq 64))"
refused "hostname with a dot" --hostname my.router
refused "hostname ending in -" --hostname router-
refused "LAN octet over 255" --lan-ip 192.168.300.1
refused "LAN prefix /31" --lan-ip 192.168.1.1/31
refused "SSID over 32 bytes" --ssid "$(printf 'x%.0s' $(seq 33))" --key 12345678
refused "nothing to set" -o "$WORK/r.tar.gz"
rm -f "$WORK/r.tar.gz"
if pack --key "$(printf 'a%.0s' $(seq 64))" -o "$WORK/r.tar.gz"; then noted "64 hex digits accepted" ok; else noted "64 hex digits accepted" "FAIL: $(cat "$WORK/err")"; fi

[ "$fail" = 0 ] && echo "cw-settings-pack: all checks passed" || { echo "cw-settings-pack: FAILED" >&2; exit 1; }
