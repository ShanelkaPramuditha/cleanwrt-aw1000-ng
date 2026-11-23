#!/bin/sh
# cw-tailscale-off-test.sh - check what 54-cw-tailscale-off guarantees.
#
#   usage: tools/tests/cw-tailscale-off-test.sh
#
# The guarantee: a fresh flash has tailscaled off the boot path; a router that is logged in
# to Tailscale (a state file kept by a keep-settings upgrade) keeps it running; an image
# without Tailscale is not touched.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OFF="$TESTS/../../files/etc/uci-defaults/54-cw-tailscale-off"
[ -f "$OFF" ] || { echo "test: $OFF is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
# uci: the state_file option, when the case sets one
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
[ "$1" = "-q" ] && shift
[ "$1" = get ] && [ "$2" = tailscale.settings.state_file ] && [ -n "${TS_STATE_OPT:-}" ] &&
	{ printf '%s\n' "$TS_STATE_OPT"; exit 0; }
exit 1
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/logger"
chmod +x "$WORK/bin/uci" "$WORK/bin/logger"

fail=0
noted() { printf '  %-58s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }

root() { # a root with tailscale's init script, which records the actions it is given
	R="$WORK/root"; rm -rf "$R"; mkdir -p "$R/etc/init.d" "$R/etc/tailscale"
	printf '#!/bin/sh\necho "$1" >> "%s/actions"\n' "$R" > "$R/etc/init.d/tailscale"
	chmod +x "$R/etc/init.d/tailscale"
}
run() { PATH="$WORK/bin:$PATH" CW_ROOT="$R" sh "$OFF"; }
actions() { [ -f "$R/actions" ] && tr '\n' ' ' < "$R/actions" || :; }

root; run
is "fresh flash: stopped and taken off boot" "$(actions)" "stop disable "

root; printf 'login' > "$R/etc/tailscale/tailscaled.state"; run
is "logged in already: left running" "$(actions)" ""

root; : > "$R/etc/tailscale/tailscaled.state"; run
is "an empty state file is no login: off" "$(actions)" "stop disable "

root; mkdir -p "$R/srv"; printf 'login' > "$R/srv/ts.state"; TS_STATE_OPT=/srv/ts.state run
is "a state file moved in its config is found" "$(actions)" ""

R="$WORK/none"; rm -rf "$R"; mkdir -p "$R"; run; rc=$?
is "no Tailscale in the image: nothing to do" "$rc/$(ls "$R")" "0/"

echo
[ "$fail" = 0 ] && echo "tailscale-off: all cases passed" || { echo "tailscale-off: failures above" >&2; exit 1; }
