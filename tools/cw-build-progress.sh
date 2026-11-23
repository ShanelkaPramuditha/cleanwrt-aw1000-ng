#!/bin/sh
# cw-build-progress.sh - a progress bar for a running build, read from its log.
#
#   usage: tools/cw-build-progress.sh [--plain] <build.log> [<openwrt-tree>]
#
# Run it in a second terminal while tools/cw-release-build.sh writes <build.log>, or start the
# build in the background and run this in front of it (docs/building.md). It only reads: the
# log, and the tree's package list for its first estimate. Stopping it (Ctrl+C) does not touch
# the build.
#
# What it counts: OpenWrt prints one line per build step, " make[N] -C <dir> compile" (or
# host-compile), and each directory compiles once per run. Done = the distinct directories the
# log has compiled so far. Total = what the last finished run in this tree compiled, kept in
# <tree>/.cw-progress-total; before any run has finished there, an estimate from the selected
# packages (each one's source directory, plus the host tools and the toolchain). The estimate
# is rough, so the bar stays at 99% until the build reports its end.
#
# It shows the phase (setup, download, compile, image, checks), the bar, done/total, the
# package compiling now, the elapsed time and a time-left estimate from the pace so far, and
# exits when the build ends: 0 when it printed IMAGE_OK, 1 otherwise.
#
# --plain prints a new line instead of redrawing one: at each phase, every 5%, and at least
# every 10 minutes. That is the form a CI log can show (GitHub Actions cannot redraw a line);
# it is chosen by itself under GitHub Actions (GITHUB_ACTIONS=true) or when the output is not a
# terminal. CW_PROGRESS_TOTAL_FILE moves the saved total out of the tree (CI keeps it in the
# cached dl/ directory, as the tree itself is fresh on every run).
set -u

PLAIN=0
[ "${1:-}" = --plain ] && { PLAIN=1; shift; }
[ "${GITHUB_ACTIONS:-}" = true ] && PLAIN=1
[ -t 1 ] || PLAIN=1
LOG=${1:?usage: tools/cw-build-progress.sh [--plain] <build.log> [<openwrt-tree>]}
TREE=${2:-}
INTERVAL=${CW_PROGRESS_INTERVAL:-2}
[ "$PLAIN" = 1 ] && INTERVAL=${CW_PROGRESS_INTERVAL:-15}

# Wait for the log: the build may not have created it yet.
n=0
while [ ! -f "$LOG" ]; do
	[ "$n" -ge 120 ] && { echo "cw-build-progress: $LOG does not exist" >&2; exit 2; }
	n=$((n + 1)); sleep 1
done

# The tree, when not given: the build prints "== seed: ..." and works in the tree it was given.
# Its "-C <dir>" lines are relative, so the tree is only needed for the total.
TOTAL_FILE=${CW_PROGRESS_TOTAL_FILE:-}
[ -z "$TOTAL_FILE" ] && [ -n "$TREE" ] && TOTAL_FILE="$TREE/.cw-progress-total"

estimate_total() { # distinct source directories of the selected packages, plus tools and toolchain
	[ -n "$TREE" ] && [ -f "$TREE/tmp/.packageinfo" ] && [ -f "$TREE/.config" ] || { echo 0; return; }
	awk '
		FNR == NR { if ($0 ~ /^CONFIG_PACKAGE_[^=]+=[ym]$/) { sub(/^CONFIG_PACKAGE_/, ""); sub(/=.*/, ""); sel[$0] = 1 } next }
		/^Source-Makefile: / { d = $2; sub(/\/Makefile$/, "", d); n = split(d, p, "/"); dir = p[n] }
		/^Package: / { if (sel[$2]) dirs[dir] = 1 }
		END { c = 0; for (k in dirs) c++; print c }
	' "$TREE/.config" "$TREE/tmp/.packageinfo"
}

# The total: the last finished run's count, else an estimate. A fresh tree has no package list
# until the build's defconfig has run, so the estimate is tried again on every pass until then.
total=0
find_total() {
	if [ -n "$TOTAL_FILE" ] && [ -s "$TOTAL_FILE" ]; then
		total=$(cat "$TOTAL_FILE")
		case "$total" in ''|*[!0-9]*) total=0 ;; esac
		[ "$total" -gt 0 ] && return
	fi
	pk=$(estimate_total)
	if [ "$pk" -gt 0 ]; then
		tools=$(ls "$TREE"/tools/*/Makefile 2>/dev/null | wc -l)
		total=$((pk + tools * 4 / 5 + 12))   # most host tools build; toolchain and kernel ~12 steps
	fi
}
last_phase= last_step=-1 last_print=0

start=$(date +%s)
cols=$(tput cols 2>/dev/null || echo 100)
[ "$cols" -lt 60 ] && cols=60
barw=$((cols - 62)); [ "$barw" -lt 10 ] && barw=10; [ "$barw" -gt 40 ] && barw=40

fmt() { s=$1; [ "$s" -lt 0 ] && s=0; printf '%d:%02d:%02d' $((s / 3600)) $((s % 3600 / 60)) $((s % 60)); }

while :; do
	[ "$total" -gt 0 ] || find_total
	# one pass over the log: phase, distinct compiled dirs, the newest one, and the end state
	set -- $(sed 's/\x1b\[[0-9;]*m//g' "$LOG" 2>/dev/null | awk '
		/=== CW RELEASE BUILD START/ { ph = "download" }
		/^ make\[[0-9]+\] world/ || /^ make\[[0-9]+\] -C [^ ]+ (compile|host-compile)$/ { if (ph == "download" || ph == "setup") ph = "compile" }
		/^ make\[[0-9]+\] -C [^ ]+ (compile|host-compile)$/ {
			d = $3; n = split(d, p, "/"); k = p[n]
			if (!(k in seen)) { seen[k] = 1; done++ }
			cur = k
		}
		/^-- world rc=/ { ph = "image" }
		/^IMAGE_SIZE / { ph = "checks" }
		/^IMAGE_OK / { ok = 1 }
		/^IMAGE_BUILT_WITH_PRIOR_ERRORS / { ok = 0 }
		/=== CW RELEASE BUILD END/ { end = 1 }
		END {
			if (ph == "") ph = "setup"
			if (cur == "") cur = "-"
			printf "%s %d %s %d %d\n", ph, done + 0, cur, end + 0, ok + 0
		}')
	phase=$1 done=$2 cur=$3 ended=$4 ok=$5
	# the build's own start time, when the log has it, so a watcher started late still times it
	if [ -z "${bstart:-}" ]; then
		d=$(sed -n 's/.*=== CW RELEASE BUILD START \(.*\) (clean=.*/\1/p' "$LOG" | head -1)
		[ -n "$d" ] && bstart=$(date -d "$d" +%s 2>/dev/null) && start=$bstart
	fi
	now=$(date +%s); el=$((now - start))

	if [ "$total" -gt 0 ]; then
		[ "$done" -gt "$total" ] && total=$done
		pct=$((done * 100 / total)); [ "$pct" -gt 99 ] && [ "$ended" = 0 ] && pct=99
		left="--:--:--"
		[ "$done" -ge 5 ] && [ "$phase" = compile ] && left=$(fmt $(( el * (total - done) / done )))
		tot_s=$total
	else
		pct=0; left="--:--:--"; tot_s="?"
	fi
	[ "$ended" = 1 ] && { pct=100; tot_s=$done; left="0:00:00"; }
	fill=$((pct * barw / 100))
	bar=$(printf '%*s' "$fill" '' | tr ' ' '#')$(printf '%*s' $((barw - fill)) '' | tr ' ' '.')
	curw=$((cols - barw - 52)); [ "$curw" -lt 8 ] && curw=8
	cur=$(printf '%.*s' "$curw" "$cur")
	if [ "$PLAIN" = 0 ]; then
		printf '\r\033[K%-8s [%s] %3d%%  %s/%s  %-*s  %s  left %s' \
			"$phase" "$bar" "$pct" "$done" "$tot_s" "$curw" "$cur" "$(fmt "$el")" "$left"
	elif [ "$phase" != "$last_phase" ] || [ $((pct / 5)) -ne "$last_step" ] ||
	     [ $((now - last_print)) -ge 600 ] || [ "$ended" = 1 ]; then
		bar=$(printf '%*s' $((pct / 5)) '' | tr ' ' '#')$(printf '%*s' $((20 - pct / 5)) '' | tr ' ' '.')
		printf '>> progress: %-8s [%s] %3d%%  %s/%s steps  now: %s  elapsed %s  left %s\n' \
			"$phase" "$bar" "$pct" "$done" "$tot_s" "$cur" "$(fmt "$el")" "$left"
		last_phase=$phase last_step=$((pct / 5)) last_print=$now
	fi

	if [ "$ended" = 1 ]; then
		[ "$PLAIN" = 0 ] && echo
		if [ "$ok" = 1 ]; then
			# the next run's total: what this one compiled (a clean build lists every step,
			# an incremental one the same set again)
			[ -n "$TOTAL_FILE" ] && [ "$done" -gt 0 ] && echo "$done" > "$TOTAL_FILE" 2>/dev/null
			echo "build finished: IMAGE_OK in $(fmt "$el"), $done build steps"
			exit 0
		fi
		echo "build finished without IMAGE_OK - see the end of $LOG"
		exit 1
	fi
	sleep "$INTERVAL"
done
