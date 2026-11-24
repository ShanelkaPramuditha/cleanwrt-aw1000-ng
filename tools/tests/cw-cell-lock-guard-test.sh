#!/bin/sh
# cw-cell-lock-guard-test.sh - check what /usr/sbin/cw-cell-lock-guard guarantees.
#
#   usage: tools/tests/cw-cell-lock-guard-test.sh
#
# The guarantee: a locked modem that reports no usable cell for lockcell_guard_minutes
# checks in a row is unlocked once; a modem that has its cell, is not locked, has the guard
# off, or does not answer is never unlocked, and a good reading resets the count.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GUARD="$TESTS/../../files/usr/sbin/cw-cell-lock-guard"
[ -f "$GUARD" ] || { echo "test: $GUARD is missing" >&2; exit 1; }
command -v jq >/dev/null || { echo "test: jq is required (it stands in for jsonfilter)" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"

# uci: answers from $WORK/uci (lines "qmodem.<sec>.<opt>=<value>"), for get and show
cat > "$WORK/bin/uci" <<STUB
#!/bin/sh
[ "\$1" = "-q" ] && shift
case "\$1" in
	show) cat "$WORK/uci" ;;
	get) sed -n "s|^\$2=||p" "$WORK/uci" | head -1 | grep . ;;
	*) exit 1 ;;
esac
STUB
# jsonfilter: the two path forms the guard uses, through jq
cat > "$WORK/bin/jsonfilter" <<'STUB'
#!/bin/sh
expr=
while [ $# -gt 0 ]; do case "$1" in -e) expr=$2; shift 2 ;; *) shift ;; esac; done
path=$(printf '%s' "$expr" | sed 's/^@//; s/\[\*\]/[]/g')
jq -r "$path // empty" 2>/dev/null
STUB
printf '#!/bin/sh\necho "$*" >> "%s/log"\n' "$WORK" > "$WORK/bin/logger"
# modem_ctrl.sh: the reading in $WORK/reading; set_neighborcell is recorded
cat > "$WORK/modem_ctrl" <<STUB
#!/bin/sh
case "\$1" in
	get_neighborcell) cat "$WORK/reading" ;;
	set_neighborcell) echo "\$2 \$3" >> "$WORK/unlocks" ;;
esac
STUB
chmod +x "$WORK/bin/uci" "$WORK/bin/jsonfilter" "$WORK/bin/logger" "$WORK/modem_ctrl"

fail=0
noted() { printf '  %-62s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }
is() { [ "$2" = "$3" ] && noted "$1" ok || noted "$1" "FAIL: [$2], expected [$3]"; }

reading() { # <LTE status> <state> <serving pci or empty>
	if [ -n "$3" ]; then serving="[{\"rat\":\"LTE\",\"pci\":\"$3\"}]"; else serving="[]"; fi
	printf '{"neighborcell":{"state":"%s","serving":%s,"lockcell_status":{"LTE":"%s","NR":"unlock"}}}' \
		"$2" "$serving" "$1" > "$WORK/reading"
}
config() { # <guard enabled> <minutes>
	printf 'qmodem.main=main\nqmodem.modem1=modem-device\nqmodem.modem1.lockcell_guard_enabled=%s\nqmodem.modem1.lockcell_guard_minutes=%s\n' \
		"$1" "$2" > "$WORK/uci"
}
fresh() { rm -rf "$WORK/state" "$WORK/unlocks" "$WORK/log"; }
check() { PATH="$WORK/bin:$PATH" CW_GUARD_MODEM_CTRL="$WORK/modem_ctrl" CW_GUARD_STATE_DIR="$WORK/state" sh "$GUARD" --once; }
unlocks() { [ -f "$WORK/unlocks" ] && grep -c . "$WORK/unlocks" || echo 0; }

echo "cw-cell-lock-guard:"

fresh; config 1 3; reading locked SEARCH ""
check; check
is "locked, no cell, 2 of 3 checks: not unlocked yet" "$(unlocks)" 0
check
is "locked, no cell, 3 of 3 checks: unlocked" "$(unlocks)" 1
is "the unlock goes to the right modem with an empty lock" "$(cut -d' ' -f1 "$WORK/unlocks")" modem1
grep -q '"pci":""' "$WORK/unlocks" && noted "the unlock request clears PCI and ARFCN" ok || noted "the unlock request clears PCI and ARFCN" FAIL
grep -q 'unlocking' "$WORK/log" && noted "the unlock is logged" ok || noted "the unlock is logged" FAIL
check
is "the count starts again after an unlock" "$(unlocks)" 1

fresh; config 1 2; reading locked LIMSRV 194
check; check
is "LIMSRV counts as lost even with a cell listed" "$(unlocks)" 1

fresh; config 1 2; reading locked NOCONN ""
check; check
is "no serving cell counts as lost" "$(unlocks)" 1

fresh; config 1 2; reading locked SEARCH ""
check; reading locked NOCONN 194; check; reading locked SEARCH ""; check
is "a good reading in between resets the count" "$(unlocks)" 0

fresh; config 1 1; reading locked NOCONN 194
check
is "locked with its cell: never unlocked" "$(unlocks)" 0

fresh; config 1 1; reading unlock SEARCH ""
check
is "not locked: never unlocked" "$(unlocks)" 0

fresh; config 0 1; reading locked SEARCH ""
check
is "guard off: never unlocked" "$(unlocks)" 0

fresh; config 1 1; printf '' > "$WORK/reading"
check
is "no answer from the modem: never unlocked" "$(unlocks)" 0

fresh; config 1 abc; reading locked SEARCH ""
check; check; check; check
is "a bad minutes value falls back to 5" "$(unlocks)" 0
check
is "... and unlocks on the 5th check" "$(unlocks)" 1

exit "$fail"
