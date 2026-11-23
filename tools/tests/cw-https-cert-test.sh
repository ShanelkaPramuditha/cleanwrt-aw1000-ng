#!/bin/sh
# cw-https-cert-test.sh - check what files/usr/sbin/cw-https-cert guarantees.
#
#   usage: tools/tests/cw-https-cert-test.sh
#
# The guarantee: the certificate names the LAN address (without a prefix length), the hostname
# and <hostname>.<domain>; --if-missing keeps an existing certificate; a px5g failure leaves the
# old certificate in place; the key is the user's only.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CERT="$TESTS/../../files/usr/sbin/cw-https-cert"
[ -f "$CERT" ] || { echo "test: $CERT is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
cat > "$WORK/bin/uci" <<'S'
#!/bin/sh
[ "$1" = -q ] && shift
case "$2" in
"system.@system[0].hostname") [ -n "${T_HOST:-}" ] && echo "$T_HOST" && exit 0 ;;
network.lan.ipaddr) [ -n "${T_IP:-}" ] && echo "$T_IP" && exit 0 ;;
"dhcp.@dnsmasq[0].domain") [ -n "${T_DOMAIN:-}" ] && echo "$T_DOMAIN" && exit 0 ;;
esac
exit 1
S
# px5g: records its arguments, writes the files it is told to, or fails when asked
cat > "$WORK/bin/px5g" <<'S'
#!/bin/sh
[ -n "${T_PX5G_FAIL:-}" ] && exit 1
echo "$*" > "$WORK/px5g.args"
while [ $# -gt 0 ]; do
	case "$1" in -keyout) echo newkey > "$2" ;; -out) echo newcrt > "$2" ;; esac
	shift
done
S
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/"*
export WORK PATH="$WORK/bin:$PATH"

fail=0
noted() { printf '  %-58s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }
root() { R="$WORK/root"; rm -rf "$R" "$WORK/px5g.args"; mkdir -p "$R/etc"; }
run() { CW_ROOT="$R" sh "$CERT" --no-restart "$@" >/dev/null 2>&1; }
sans() { tr ' ' '\n' < "$WORK/px5g.args" | sed -n 's/^subjectAltName=//p' | tr '\n' ' '; }

root; T_HOST=CleanWRT T_IP=192.168.1.1/24 run
is "names the LAN address, hostname and hostname.lan" "$(sans)" "DNS:cleanwrt DNS:cleanwrt.lan IP:192.168.1.1 "
is "  the files are in place" "$(cat "$R/etc/uhttpd.crt")/$(cat "$R/etc/uhttpd.key")" "newcrt/newkey"
is "  the key is the user's only" "$(stat -c %a "$R/etc/uhttpd.key")" 600

root; T_HOST=Router T_IP=10.0.0.1 T_DOMAIN=home run
is "another hostname, address and domain" "$(sans)" "DNS:router DNS:router.home IP:10.0.0.1 "

root; run
is "no settings at all: openwrt, openwrt.lan, no IP" "$(sans)" "DNS:openwrt DNS:openwrt.lan "

root; echo old > "$R/etc/uhttpd.crt"; echo old > "$R/etc/uhttpd.key"; T_IP=192.168.1.1 run --if-missing
is "--if-missing keeps an existing certificate" "$(cat "$R/etc/uhttpd.crt")/$([ -f "$WORK/px5g.args" ] && echo ran || echo idle)" "old/idle"

root; echo old > "$R/etc/uhttpd.crt"; echo old > "$R/etc/uhttpd.key"
T_IP=192.168.1.1 T_PX5G_FAIL=1 run && rc=0 || rc=$?
is "px5g fails: exit 1, the old certificate stays" "$rc/$(cat "$R/etc/uhttpd.crt")/$(ls "$R/etc" | tr '\n' ' ')" "1/old/uhttpd.crt uhttpd.key "

echo
[ "$fail" = 0 ] && echo "https-cert: all cases passed" || { echo "https-cert: failures above" >&2; exit 1; }
