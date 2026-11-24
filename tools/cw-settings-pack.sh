#!/bin/sh
# cw-settings-pack.sh - make a settings archive to flash together with a CleanWRT image.
#
#   usage: tools/cw-settings-pack.sh [--hostname NAME] [--lan-ip ADDR[/PREFIX]] [--ssid NAME] [--ssid-2g NAME] [--ssid-5g NAME] [--ssid-6g NAME] [--key PASSWORD] [-o FILE | --script FILE]
#
# The image itself ships the stock OpenWrt defaults (hostname OpenWrt, LAN 192.168.1.1) and Wi-Fi
# 'OpenWrt' on with the password 'password123' (files/etc/uci-defaults/56-cw-wifi-default-key),
# so a reset always brings a router back to values anyone can look up. This tool is for the other side: your own router, set up the moment it
# is flashed, without rebuilding or touching the signed image.
#
# It writes a .tar.gz holding one first-boot script, etc/uci-defaults/zz-cw-my-settings. Use it
# either way:
#   sysupgrade -v -f mysettings.tar.gz cleanwrt-...-sysupgrade.bin     (from OpenWrt/CleanWRT)
#   LuCI -> System -> Backup / Flash Firmware -> Restore backup        (after a factory install)
# The script runs once on the next boot, after the Wi-Fi config exists and after the image's own
# first-boot scripts (zz- sorts last), then deletes itself. A later reset (firstboot, or
# sysupgrade -n) removes it with the rest of the settings: the stock defaults come back.
#
# Options (each one optional; anything not given stays at the image default):
#   --hostname NAME        system hostname (letters, digits, '-'; up to 63)
#   --lan-ip ADDR[/PREFIX] LAN address, prefix 8-30, default /24 (e.g. 192.168.50.1)
#   --ssid NAME            Wi-Fi name on every band
#   --ssid-2g/-5g/-6g NAME Wi-Fi name on one band (overrides --ssid there); without --key the
#                          networks keep the image's password ('password123')
#   --key PASSWORD         WPA2 password (8-63 characters, or 64 hex digits); turns Wi-Fi on
#   -o FILE                output archive (default: mysettings.tar.gz)
#   --script FILE          write only the first-boot script, no archive. tools/cw-build.sh uses
#                          it to build these values into a local image (see docs/custom-settings.md)
#
# The tool never makes a network open: with --key every network gets that password, without it
# only the names change and each network keeps the password it has (on a fresh flash the
# image's 'password123'). The archive holds the Wi-Fi password in plain text: keep it like a
# password.
set -eu

usage() { sed -n '4p' "$0" | sed 's/^# *//' >&2; exit 2; }
die() { echo "cw-settings-pack: $*" >&2; exit 1; }

HOSTNAME_V='' LANIP='' SSID='' SSID2='' SSID5='' SSID6='' KEY='' OUT=mysettings.tar.gz SCRIPT_OUT=''
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
	case "$1" in
		--hostname) [ $# -ge 2 ] || usage; HOSTNAME_V=$2; shift 2 ;;
		--lan-ip)   [ $# -ge 2 ] || usage; LANIP=$2; shift 2 ;;
		--ssid)     [ $# -ge 2 ] || usage; SSID=$2; shift 2 ;;
		--ssid-2g)  [ $# -ge 2 ] || usage; SSID2=$2; shift 2 ;;
		--ssid-5g)  [ $# -ge 2 ] || usage; SSID5=$2; shift 2 ;;
		--ssid-6g)  [ $# -ge 2 ] || usage; SSID6=$2; shift 2 ;;
		--key)      [ $# -ge 2 ] || usage; KEY=$2; shift 2 ;;
		-o)         [ $# -ge 2 ] || usage; OUT=$2; shift 2 ;;
		--script)   [ $# -ge 2 ] || usage; SCRIPT_OUT=$2; shift 2 ;;
		-h|--help)  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) echo "cw-settings-pack: unknown option '$1'" >&2; usage ;;
	esac
done

export LC_ALL=C

# ── validation: a bad value is refused here, not found later on a router that will not boot
#    the way you expect ──────────────────────────────────────────────────────────────────────
if [ -n "$HOSTNAME_V" ]; then
	printf '%s\n' "$HOSTNAME_V" | grep -Eqx '[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?' ||
		die "--hostname '$HOSTNAME_V': use letters, digits and '-' (not first or last), up to 63"
fi

if [ -n "$LANIP" ]; then
	case "$LANIP" in */*) ;; *) LANIP="$LANIP/24" ;; esac
	printf '%s\n' "$LANIP" | awk -F'[./]' '
		NF != 5 { exit 1 }
		{ for (i = 1; i <= 5; i++) if ($i !~ /^[0-9]+$/) exit 1
		  for (i = 1; i <= 4; i++) if ($i > 255) exit 1
		  if ($5 < 8 || $5 > 30) exit 1 }' ||
		die "--lan-ip '$LANIP': expected an IPv4 address like 192.168.50.1 or 192.168.50.1/24 (prefix 8-30)"
fi

check_ssid() { # <option> <value>
	[ -n "$2" ] || return 0
	[ "${#2}" -le 32 ] || die "$1: a Wi-Fi name is at most 32 bytes"
	case "$2" in *[[:cntrl:]]*) die "$1: control characters are not allowed" ;; esac
}
check_ssid --ssid "$SSID"
check_ssid --ssid-2g "$SSID2"
check_ssid --ssid-5g "$SSID5"
check_ssid --ssid-6g "$SSID6"

if [ -n "$KEY" ]; then
	if printf '%s\n' "$KEY" | grep -Eqx '[0-9A-Fa-f]{64}'; then
		:
	else
		[ "${#KEY}" -ge 8 ] && [ "${#KEY}" -le 63 ] || die "--key: a WPA2 password is 8-63 characters (or 64 hex digits)"
		case "$KEY" in *[![:print:]]*) die "--key: use printable ASCII characters only" ;; esac
	fi
fi

[ -n "$HOSTNAME_V$LANIP$SSID$SSID2$SSID5$SSID6$KEY" ] || die "nothing to set: give at least one option"

# ── the first-boot script ─────────────────────────────────────────────────────────────────
sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/etc/uci-defaults"
S="$WORK/etc/uci-defaults/zz-cw-my-settings"
{
	echo '#!/bin/sh'
	if [ -n "$SCRIPT_OUT" ]; then
		echo '# Made by tools/cw-settings-pack.sh and built into this image by tools/cw-build.sh.'
		echo '# Runs on the first boot, and again after every reset: these are the image defaults.'
	else
		echo '# Made by tools/cw-settings-pack.sh. Runs once on the first boot after it was restored,'
		echo '# then the system deletes it. A reset brings back the stock defaults.'
	fi
	if [ -n "$HOSTNAME_V" ]; then
		echo "uci set system.@system[0].hostname=$(sq "$HOSTNAME_V")"
		echo 'uci commit system'
	fi
	if [ -n "$LANIP" ]; then
		# config_generate writes the LAN address as a list entry with its prefix
		echo 'uci -q delete network.lan.ipaddr'
		echo 'uci -q delete network.lan.netmask'
		echo "uci add_list network.lan.ipaddr=$(sq "$LANIP")"
		echo 'uci commit network'
	fi
	if [ -n "$KEY$SSID$SSID2$SSID5$SSID6" ]; then
		echo "SSID_ALL=$(sq "$SSID")"
		echo "SSID_2G=$(sq "$SSID2")"
		echo "SSID_5G=$(sq "$SSID5")"
		echo "SSID_6G=$(sq "$SSID6")"
		echo "KEY=$(sq "$KEY")"
		cat <<'EOS'
for radio in $(uci show wireless | sed -n "s/^wireless\.\([^.=]*\)=wifi-device.*/\1/p"); do
	iface=$(uci show wireless | grep "device='$radio'" | head -1 | cut -d. -f1-2)
	[ -n "$iface" ] || continue
	case "$(uci -q get "wireless.$radio.band")" in
		2g) ssid=${SSID_2G:-$SSID_ALL} ;;
		5g) ssid=${SSID_5G:-$SSID_ALL} ;;
		6g) ssid=${SSID_6G:-$SSID_ALL} ;;
		*)  ssid=$SSID_ALL ;;
	esac
	[ -n "$ssid" ] && uci set "$iface.ssid=$ssid"
	# no key given: only the names change, each network keeps its password and state
	[ -n "$KEY" ] || continue
	if [ "$(uci -q get "wireless.$radio.band")" = 6g ]; then
		uci set "$iface.encryption=sae"   # 6 GHz allows WPA3 only
	else
		uci set "$iface.encryption=psk2"
	fi
	uci set "$iface.key=$KEY"
	uci set "$iface.disabled=0"
	uci set "wireless.$radio.disabled=0"
done
uci commit wireless
EOS
	fi
	echo 'logger -t cw-settings "custom settings applied (tools/cw-settings-pack.sh)"'
	echo 'exit 0'
} > "$S"
chmod 0755 "$S"

# --script: the script alone, for a build to put in the image overlay. Private, because it
# holds the Wi-Fi password.
if [ -n "$SCRIPT_OUT" ]; then
	( umask 077; cat "$S" > "$SCRIPT_OUT" )
	exit 0
fi

# root-owned entries, like a real backup; GNU tar and bsdtar (macOS) spell it differently
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
if tar --version 2>/dev/null | grep -q 'GNU tar'; then
	tar --owner=0 --group=0 --numeric-owner -C "$WORK" -czf "$OUT" etc
else
	tar --uid 0 --gid 0 -C "$WORK" -czf "$OUT" etc
fi

echo "wrote $OUT"
[ -n "$HOSTNAME_V" ] && echo "  hostname   $HOSTNAME_V"
[ -n "$LANIP" ]      && echo "  LAN        $LANIP  (the router answers there after the reboot)"
if [ -n "$KEY$SSID$SSID2$SSID5$SSID6" ]; then
	if [ -n "$KEY" ]; then w='on, password set'; else w="the image's password kept"; fi
	echo "  Wi-Fi      $w${SSID:+, name '$SSID'}${SSID2:+, 2.4 GHz '$SSID2'}${SSID5:+, 5 GHz '$SSID5'}${SSID6:+, 6 GHz '$SSID6'}"
fi
echo "Flash:   sysupgrade -v -f $(basename "$OUT") <image>-sysupgrade.bin   (not with -n)"
echo "Or:      LuCI -> System -> Backup / Flash Firmware -> Restore backup"
[ -z "$KEY" ] || echo "The archive holds the Wi-Fi password in plain text."
