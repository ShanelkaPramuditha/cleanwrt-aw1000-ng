#!/bin/sh
# cw-wireguard-restore-test.sh - check what 55-cw-wireguard-restore and its hotplug half guarantee.
#
#   usage: tools/tests/cw-wireguard-restore-test.sh
#
# The guarantee: a router upgraded with a WireGuard tunnel configured gets WireGuard installed
# again once it is online, and its tunnels brought up; a failed download is retried on the next
# interface; a router without a tunnel, or with WireGuard installed, is never touched.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARM="$TESTS/../../files/etc/uci-defaults/55-cw-wireguard-restore"
HOOK="$TESTS/../../files/etc/hotplug.d/iface/95-cw-wireguard-restore"
for f in "$ARM" "$HOOK"; do [ -f "$f" ] || { echo "test: $f is missing" >&2; exit 1; }; done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
# uci show network: the lines of $NETCFG. apk and ifup record what they are asked; apk
# fails while $WORK/offline exists.
cat > "$WORK/bin/uci" <<'S'
#!/bin/sh
[ "$1" = -q ] && shift
[ "$1" = show ] && [ "$2" = network ] && { cat "$NETCFG"; exit 0; }
exit 1
S
cat > "$WORK/bin/apk" <<'S'
#!/bin/sh
[ -e "$WORK/offline" ] && exit 1
echo "apk $*" >> "$WORK/calls"
S
printf '#!/bin/sh\necho "ifup $1" >> "$WORK/calls"\n' > "$WORK/bin/ifup"
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/"*
export WORK PATH="$WORK/bin:$PATH" CW_WG_FOREGROUND=1

fail=0
noted() { printf '  %-60s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }

root() { # <network config lines...>
	R="$WORK/root"; rm -rf "$R" "$WORK/calls" "$WORK/offline"; mkdir -p "$R/etc" "$R/tmp" "$R/lib/netifd/proto"
	NETCFG="$WORK/net"; printf '%s\n' "$@" > "$NETCFG"; export NETCFG
}
arm() { CW_ROOT="$R" sh "$ARM"; }
hook() { ACTION=${1:-ifup} CW_ROOT="$R" sh "$HOOK"; }
calls() { [ -f "$WORK/calls" ] && tr '\n' '|' < "$WORK/calls" || :; }
marked() { [ -f "$R/etc/cw-wireguard-restore" ] && echo yes || echo no; }

root "network.lan=interface" "network.lan.proto='static'" "network.wg0=interface" "network.wg0.proto='wireguard'" \
	"network.wg1=interface" "network.wg1.proto='wireguard'"
arm
is "a tunnel and no WireGuard: armed" "$(marked)" yes
hook
is "  online: installed, both tunnels up" "$(calls)" "apk update|apk add kmod-wireguard wireguard-tools luci-proto-wireguard|ifup wg0|ifup wg1|"
is "  and disarmed" "$(marked)" no
rm -f "$WORK/calls"; hook
is "  a later interface does nothing" "$(calls)" ""

root "network.wg0=interface" "network.wg0.proto='wireguard'"
arm; : > "$WORK/offline"; hook
is "offline: nothing installed" "$(calls)" ""
is "  stays armed" "$(marked)" yes
is "  and the lock is released" "$([ -d "$R/tmp/cw-wireguard-restore.lock" ] && echo held || echo free)" free
rm -f "$WORK/offline"; hook
is "  the next interface installs it" "$(calls)" "apk update|apk add kmod-wireguard wireguard-tools luci-proto-wireguard|ifup wg0|"

root "network.wg0=interface" "network.wg0.proto='wireguard'"
arm; hook ifdown
is "an ifdown event does nothing" "$(calls)" ""

root "network.wg0=interface" "network.wg0.proto='wireguard'"
: > "$R/lib/netifd/proto/wireguard.sh"; arm
is "WireGuard installed already: not armed" "$(marked)" no

root "network.lan=interface" "network.lan.proto='static'" "network.wan.proto='dhcp'"
arm; hook
is "no tunnel: not armed, nothing installed" "$(marked)/$(calls)" "no/"

root "network.wg0=interface" "network.wg0.proto='wireguard'"
arm; mkdir "$R/tmp/cw-wireguard-restore.lock"; hook
is "an install in progress: a second one does not start" "$(calls)" ""

echo
[ "$fail" = 0 ] && echo "wireguard-restore: all cases passed" || { echo "wireguard-restore: failures above" >&2; exit 1; }
