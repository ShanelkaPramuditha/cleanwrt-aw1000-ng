---
batch: ENH-01
title: "Nikki pages, Vantage row buttons, QModem cell lock"
status: review          # code complete; waiting for the router tests below
started: 2026-11-24
updated: 2026-11-24 19:50 UTC
progress:
  code: 17/17           # tasks whose code or docs are written
  off_device: 17/17     # tasks checked without a router
  on_router: 0/14       # tasks that also need a test on the AW1000
  suggestions_open: 7   # S5, S13-S18
---

# ENH-01: Nikki pages, Vantage row buttons, QModem cell lock

User requests of 2026-11-24, worked in one session: redesign every Nikki page for usability; fix
uneven spacing between row buttons; offer a way to lock the modem to a cell, from a list of the
cells around the router with operator and signal data and a click to lock; tidy the padding on
*Advance Modem Settings*; set up this work log. Then "complete enh-01": the user chose to do the
batch's own suggestions S1 to S12 inside this batch (T7 to T17). S5 needs the router and stays
open.

All code is written and checked off-device. **Nothing has been tested on a router yet, and
nothing is committed.** The batch stays in `review` until the router checks in each task are done.

## Progress

| stage | done | bar |
|---|---|---|
| Code and docs written | 17 of 17 tasks | `████████████████████` 100% |
| Checked off-device (patches apply, syntax, tests, headless page runs) | 17 of 17 tasks | `████████████████████` 100% |
| Tested on the router | 0 of 14 tasks | `░░░░░░░░░░░░░░░░░░░░` 0% |
| Docs site build (`mkdocs build --strict`) | not run here | waits for the `docs` workflow |
| Committed | no | the user has not asked for a commit |

**Where it stands (2026-11-24 19:50 UTC):** every task is implemented and checked off-device.
What is left is testing on the AW1000 (the checklist below), the docs workflow run, and a commit.
When a router check passes, tick it below and in its task, and move that task to `done`.

## Router test checklist

One list of every check that needs the AW1000, in a sensible order. Each line names its task.

- [ ] Build an image with this batch and flash it (all tasks)
- [ ] Incremental rebuild on the same tree: the log shows no `mihomo` compile (T7)
- [ ] *Network → Interfaces*: Edit and ⋯ are 8px apart, desktop and phone width (T2)
- [ ] Every Nikki page in light and dark mode; upload, Use, Edit, Delete, a real subscription
      Update (T1)
- [ ] A subscription with *Update automatically* every 1 hour: it updates, and Nikki restarts only
      when it is the one in use (T15)
- [ ] *Advance Modem Settings*: every tab, buttons clear of the card edge, no "undefined" (T4)
- [ ] Neighbor Cell: the table fills on open, values plausible, operator name shown (T3, T10)
- [ ] Lock to a neighbour, then Unlock; with *Keep after reboot*, reboot and see the lock return
      (T3)
- [ ] *Unlock automatically* at 2 minutes, lock to a cell that cannot serve: `logread -e
      cw-cell-lock-guard` shows the unlock (T11)
- [ ] Auto-refresh at 15 s: sparklines appear, the timer stops on another tab (T12, T14)
- [ ] *Save cell*, reload the page, the chip and the ★ tag are still there (T13)
- [ ] *Modem → 3gInfo-lite* → *Lock…* opens Neighbor Cell with the cell filled in (T16)
- [ ] AT Debug: send a command containing a space; Lock Band and Set IMEI still work (T9)
- [ ] Switch LuCI to 简体中文, 繁體中文 and Русский: Nikki and Advance Modem Settings read in that
      language (T8)
- [ ] In SA mode, capture `AT+QENG="neighbourcell"` and `AT+QNWCFG="nr5g_meas_info"` for S5

## Progress log

Times are UTC on 2026-11-24, taken from the files' write times where a file proves them.

| time | what happened |
|---|---|
| 11:31 | T1: Nikki redesign patch written (`nikki/0001`), docs updated |
| 17:38 | T2: Vantage row-button gap patch (`luci-theme-vantage/0004`) |
| before 18:31 | T3, T4: first version of `qmodem/0012` (cell list, lock, tab tidy); T5: all patch sets checked together, no conflicts |
| 18:31 | T6: `AGENTS.md`, `CLAUDE.md`, `docs/enhanced/` created; enh-01 opened with suggestions S1 to S12 |
| 18:39 | T7 (S1): `tools/cw-release-build.sh` cleans only patched packages |
| 18:42 | T9 (S3, S4): `qmodem/0013` shell quoting |
| 18:43 to 18:44 | T11 (S7): `cw-cell-lock-guard`, its service, first-boot script and test (15 cases pass) |
| 19:16 | T15 (S11): `nikki/0002` scheduled subscription updates; T10, T11 page side, T12, T13, T14, T16 page side: `qmodem/0012` regenerated |
| 19:22 to 19:24 | T8 (S2): `nikki/0003`, `qmodem/0014`; T16: `3ginfo/0007` with its translations |
| 19:25 to 19:27 | docs: `docs/modem.md`, reference pages, `docs/building.md`, NOTICE, README, changelog |
| 19:29 | T17: final apply check and tests pass; enh-01 updated with T7 to T17 and S13 to S18 |
| 19:50 | this progress view, the router checklist and this log added; README and AGENTS rules now require updating the log as work happens |

## Summary

| ID | task | status | patch / files |
|---|---|---|---|
| ENH-01-T1 | Redesign all Nikki LuCI pages | review | `patches/feeds/nikki/0001-luci-pages-redesign.patch` |
| ENH-01-T2 | Even spacing between table row buttons (Vantage) | review | `patches/packages/luci-theme-vantage/0004-row-actions-gap.patch` |
| ENH-01-T3 | Cell list and cell lock on QModem's Neighbor Cell tab | review | `patches/feeds/qmodem/0012-neighbor-cell-list-and-lock.patch` |
| ENH-01-T4 | Padding and button rows on every Advance Modem Settings tab | review | same patch as T3 |
| ENH-01-T5 | Check all patch sets apply together | done | none (check only) |
| ENH-01-T6 | Agent-friendly docs and this work log | done | `AGENTS.md`, `CLAUDE.md`, `docs/enhanced/` |
| ENH-01-T7 | Rebuild only packages a patch touches (S1) | review | `tools/cw-release-build.sh` |
| ENH-01-T8 | Translations for the new strings (S2) | review | `patches/feeds/nikki/0003-...`, `patches/feeds/qmodem/0014-...`, strings in `patches/feeds/3ginfo/0007-...` |
| ENH-01-T9 | Quote QModem request values for the shell (S3, S4) | review | `patches/feeds/qmodem/0013-shell-quoting-for-page-requests.patch` |
| ENH-01-T10 | Operator name when `AT+COPS?` is numeric (S6) | review | in `patches/feeds/qmodem/0012-...` |
| ENH-01-T11 | Auto-unlock when the locked cell is lost (S7) | review | `files/usr/sbin/cw-cell-lock-guard` + service, uci-default, test; in `qmodem/0012` |
| ENH-01-T12 | Signal history per cell (S8) | review | in `patches/feeds/qmodem/0012-...` |
| ENH-01-T13 | Saved cells (S9) | review | in `patches/feeds/qmodem/0012-...` |
| ENH-01-T14 | Auto-refresh on the Neighbor Cell tab (S10) | review | in `patches/feeds/qmodem/0012-...` |
| ENH-01-T15 | Scheduled Nikki subscription updates (S11) | review | `patches/feeds/nikki/0002-subscription-auto-update.patch` |
| ENH-01-T16 | Lock link from 3gInfo-lite (S12) | review | `patches/feeds/3ginfo/0007-neighbour-cell-lock-link.patch`; deep link in `qmodem/0012` |
| ENH-01-T17 | Final check: all patches, tests, docs | done | none (check only) |

## Tasks

### ENH-01-T1: Redesign all Nikki LuCI pages

- **Status:** review
- **From:** request ("redesign the whole Nikki part", screenshot of *Services → Nikki → Profile*)
- **Goal:** a first-time user can add a profile, choose it, start Nikki and see whether it runs,
  without knowing mihomo's vocabulary.
- **Files:**
  - `patches/feeds/nikki/0001-luci-pages-redesign.patch` (luci-app-nikki @ feed pin `0c56ba5f`):
    - new `htdocs/luci-static/resources/nikki/nikki.css` (shared page styling)
    - `htdocs/luci-static/resources/tools/nikki.js` (header, status pill, upload, download helpers)
    - `view/nikki/app.js`, `profile.js`, `proxy.js`, `mixin.js`, `editor.js`, `log.js`
    - `root/usr/share/luci/menu.d/luci-app-nikki.json` (menu titles)
  - docs: `docs/features/vpn-proxy.md`, `docs/modem.md`, `docs/included.md`, `docs/changelog.md`,
    `NOTICE.md`, `README.md`
- **Changes:**
  - Every page has a header with a live status (Running, Stopped or Disabled), **Restart** and
    **Open Dashboard**. Open Dashboard is disabled while the core is down.
  - *Overview* (was App Config): a 3-step "Get started" checklist; tiles for the profile in use,
    traffic mode, dashboard port and versions; option descriptions throughout; the procd limits
    moved to an "Advanced" section.
  - *Profiles*: a file list (size, date, "In use", Use / Edit / Download / Delete), drag-and-drop
    upload accepting only `.yaml` / `.yml`, and a subscription table with usage meter, expiry
    warning and failed-update badge. The placeholder `default` subscription is flagged
    "No URL set" and cannot be used or updated.
  - *Proxy*: tabs LAN Devices / Router Itself / Bypass / Advanced, and an explanation of how the
    access-control rules match (first match wins; an empty rule matches all).
  - *Mixin*: what "Unmodified" means, the merge order, and the DNS tab split in two.
  - *Editor*: files grouped by kind, a note on which files get regenerated, unsaved-change
    tracking, Ctrl+S, Revert, Download, and `?file=` deep links.
  - *Logs*: one viewer for the app and core logs with time / level / message columns, a text
    filter, an errors-only view, follow-the-tail, Download and Clear.
  - Option keys are unchanged, so existing configs keep working.
- **Verification:**
  - [x] patch applies with `-F0` to a fresh clone of the pin and gives a tree identical to the
        working copy; reverse-applies (off-device)
  - [x] every touched `.js` parses with `new Function`, the menu JSON parses (off-device)
  - [x] all six pages rendered with real LuCI JS in jsdom against mocked ubus, `cgi-upload` and
        `cgi-download`. Exercised: delete with confirm, upload (`bad.txt` refused), Use, Update
        on the placeholder, log filters and Clear, editor save and deep link, the stopped and
        disabled states (off-device)
  - [ ] look at every page on the router, light and dark mode (on the router)
  - [ ] a real subscription update and a real profile switch (on the router)
- **Remaining:** the router checks above; see ENH-01-S1 and ENH-01-S2.

### ENH-01-T2: Even spacing between table row buttons (Vantage)

- **Status:** review
- **From:** request (screenshot of *Network → Interfaces*: Edit and ⋯ looked joined)
- **Goal:** row buttons are spaced like every other group of buttons in the theme.
- **Files:**
  - `patches/packages/luci-theme-vantage/0004-row-actions-gap.patch` (one CSS rule in
    `vantage.css`)
  - docs: `docs/building.md`, `docs/theme.md`, `docs/changelog.md`, `NOTICE.md`, `README.md`
- **Changes:** `.td.cbi-section-actions > div` gap from `4px` to `var(--sp-2)` (8px), the gap the
  theme uses for the Save bar, dialogs and headers. Applies to every table's row buttons.
- **Verification:**
  - [x] 0001 to 0004 apply with `-F0` to a fresh clone of the pinned theme `a7ff63b7`
        (off-device)
  - [ ] *Network → Interfaces* and another table with Edit / Delete, desktop and phone width
        (on the router)
- **Remaining:** the router check.

### ENH-01-T3: Cell list and cell lock on QModem's Neighbor Cell tab

- **Status:** review
- **From:** request ("an option to show cells (towers) with ISP name and other data, and click
  on it")
- **Goal:** see every cell the modem hears and lock to one with a click; unlock; optionally keep
  the lock after a reboot.
- **Files:**
  - `patches/feeds/qmodem/0012-neighbor-cell-list-and-lock.patch` (QModem @ `0988085b`, after
    0011):
    - `luci/luci-app-qmodem/luasrc/view/qmodem/modem_debug.htm` (the `NeighborCell` class
      rewritten, styles)
    - `application/qmodem/files/usr/share/qmodem/vendor/quectel.sh`
      (`get_neighborcell_qualcomm`, new `get_neighborcell_serving_qualcomm`, `_nc_serving`)
  - docs: new section "Locking to a cell" in `docs/modem.md`; `docs/building.md`,
    `docs/changelog.md`, `NOTICE.md`, `README.md`
- **Changes:**
  - One table: the serving cell(s) first (both legs of an EN-DC link), then neighbours by RSRP.
    Columns: signal bars, 4G or 5G, network (operator and MCC-MNC), band and MHz from the ARFCN,
    ARFCN, PCI, RSRP, RSRQ, SINR, and the cell ID and TAC for the serving cell.
  - A click on a row fills in the lock form; **Lock** on a row confirms and locks. For a 5G
    neighbour whose band is only a guess from the ARFCN, Lock fills in the form and asks the user
    to check the band and SCS first.
  - **Unlock** (shown while locked), **Scan**, a lock-status chip per RAT; the tab scans on open.
  - **Keep after reboot** drives QModem's existing boot hook (`lockcell_boot_hook_*` in
    `/etc/config/qmodem`, replayed by `modem_hook.sh`). The old page never sent it, so every
    lock cleared the saved command.
  - Backend bug fixed: neighbour RSRQ and RSRP were swapped (`AT+QENG="neighbourcell"` gives
    RSRQ in field 5, RSRP in field 6). RSSI and SINR added; values reset per line. The reply
    gains `operator` (from `AT+COPS?`) and `serving[]` (from `AT+QENG="servingcell"`). Existing
    keys are unchanged.
  - Input checks before sending: PCI 0 to 1007, ARFCN digits, NR band digits.
- **Verification:**
  - [x] backend run on canned replies for LTE, EN-DC and NR5G-SA under bash; the serving-cell
        parser also under dash; `sh -n` and `dash -n` clean (off-device)
  - [x] page script extracted and parsed; the tab driven in jsdom: table contents, row click
        fills the form, Lock sends the right values, locked-cell marking, Unlock visibility,
        PCI 2000 refused (off-device)
  - [x] the lock and unlock parameters checked through the exact shell command
        `qmodem.lua` builds, then `jq` (off-device)
  - [ ] scan, lock, unlock and keep-after-reboot on the RG500Q-EA (on the router)
  - [ ] whether the RG500Q-EA reports any NR neighbours through `AT+QENG="neighbourcell"`; the NR
        field positions are unverified (on the router)
- **Remaining:** the router checks; see ENH-01-S3 to ENH-01-S6.

### ENH-01-T4: Padding and button rows on every Advance Modem Settings tab

- **Status:** review
- **From:** request (screenshot: Scan / Submit on the card edge, "undefined" boxes)
- **Files:** `patches/feeds/qmodem/0012-neighbor-cell-list-and-lock.patch`
  (`modem_debug.htm`)
- **Changes:**
  - Vantage pulls a card's last table into the card's bottom padding, so a button row in it sat
    on the edge: `td.qm-btn-row` gets the padding back, and a new `createActions()` row sits
    outside the table.
  - Rat Prefer, Set IMEI, Reboot Modem and AT Debug use button rows. Set IMEI has a labelled
    field, and Reboot Modem explains soft vs hard reboot. The AT console's buttons start at the
    left, 8px apart.
  - `createInput()` no longer writes "undefined" as a value or placeholder.
- **Verification:**
  - [x] page script parses; the Neighbor Cell tab renders in jsdom (off-device)
  - [ ] every tab looked at under Vantage, desktop and phone width (on the router)
- **Remaining:** the router check.

### ENH-01-T5: Check all patch sets apply together

- **Status:** done
- **From:** question "what are the conflicting things to fix?"
- **Changes:** none. A scratch tree was built from the pinned feeds (3ginfo, diskman, luci, nikki,
  qmodem) and the tree files, and `tools/cw-apply-feed-patches.sh` was run on it.
- **Verification:**
  - [x] every tree and feed patch reported `applied` (or `already applied` for the two
        mode-only 3ginfo patches) and the script exited 0 (off-device)
  - [x] Vantage 0001 to 0004 apply to the pinned theme (off-device, see T2)
- **Result:** no conflicts.

### ENH-01-T6: Agent-friendly docs and this work log

- **Status:** done
- **From:** request (an `docs/enhanced/enh-NN.md` log with tasks, progress and suggestions)
- **Files:** `AGENTS.md` (entry point: repo map, rules, checks), `CLAUDE.md` (imports
  `AGENTS.md`), `docs/enhanced/README.md` (how the log works, index), `docs/enhanced/_template.md`,
  this file, and `mkdocs.yml` (`exclude_docs: enhanced/`, so the log is not published).
- **Verification:**
  - [x] files written; `mkdocs.yml` change reviewed (off-device)
  - [ ] `mkdocs build --strict` (not run: MkDocs and pip are not installed in this workspace;
        the `docs` workflow runs it). `exclude_docs` needs MkDocs 1.5 or later;
        `requirements-docs.txt` pins `>=1.6`

### ENH-01-T7: Rebuild only packages a patch touches (S1)

- **Status:** review
- **From:** ENH-01-S1
- **Goal:** a build on a kept tree does not recompile mihomo (Go) because luci-app-nikki is patched.
- **Files:** `tools/cw-release-build.sh` (step 2a-bis); `docs/building.md` (*What the build script
  guarantees*).
- **Changes:**
  - The loop that cleaned every top-level package of a patched feed is gone. Packages are found by
    walking up from each patched path to its package Makefile, now also from `diff --git` lines,
    so a mode-only diff names its package.
  - The set cleaned is written to `<tree>/.cw-patched-packages`; the next build cleans the union of
    that set and its own, so removing a patch still rebuilds the package it touched.
- **Verification:**
  - [x] `sh -n`, `bash -n` (off-device)
  - [x] the block run on a scratch tree with `make` stubbed: 15 packages, mihomo-meta not among
        them; a mihomo-meta entry in an old state file is cleaned once and dropped (off-device)
  - [ ] an incremental build with the real tree confirms mihomo is not rebuilt (build machine)
- **Remaining:** the build-machine check.

### ENH-01-T8: Translations for the new strings (S2)

- **Status:** review
- **From:** ENH-01-S2
- **Files:**
  - `patches/feeds/nikki/0003-translations-for-the-new-pages.patch`: 254 strings in zh_Hans,
    zh_Hant, ru
  - `patches/feeds/qmodem/0014-translations-for-advance-modem-settings.patch`: 77 strings (75
    from 0012, 2 never translated upstream) in zh_Hans, zh-cn, ru
  - `patches/feeds/3ginfo/0007-neighbour-cell-lock-link.patch`: its 3 strings in de, it, pl, ru,
    zh_Hans
  - working files: the numbered translation lists and the merge script live in the session
    scratchpad only (`tr/merge.py` checks one line per msgid and identical placeholders)
- **Verification:**
  - [x] every translation keeps its msgid's placeholders (script) (off-device)
  - [x] every catalog compiles with LuCI's `po2lmo`; Nikki's with `msgfmt --check-format`. The
        QModem and 3ginfo catalogs already had duplicate entries upstream (26 / 26 / 8 / 2 each);
        none added (off-device)
  - [ ] pages viewed in Chinese and Russian (on the router)
- **Remaining:** the router check; a native speaker's review would help (the translations were
  written for CleanWRT, and Russian has no plural forms through LuCI's `_()`).

### ENH-01-T9: Quote QModem request values for the shell (S3, S4)

- **Status:** review
- **From:** ENH-01-S3, ENH-01-S4
- **Files:** `patches/feeds/qmodem/0013-shell-quoting-for-page-requests.patch`
  (`luci/luci-app-qmodem/luasrc/controller/qmodem.lua`,
  `application/qmodem/files/usr/share/qmodem/modem_ctrl.sh`)
- **Changes:**
  - `shq()` single-quotes every request value; `action` and `cfg` must match `^[%w_%-]+$` or the
    request gets a 400; `sendATCommand`'s `at()` quotes port and command.
  - The pages send `params` JSON-encoded twice; the old double quotes stripped one level by
    accident. The controller now unwraps it: a `params` that parses as a JSON string becomes that
    string. Every caller (Lock Band, Rat Prefer, Dial Mode, Set IMEI, Neighbor Cell, Reboot,
    AT Debug) sends the script exactly what it did before.
  - `modem_ctrl.sh`: `"$3"` quoted for the seven `set_*` calls and the reboot, send_at
    (`at "$port" "$cmd"`) and send_sms branches.
- **Verification:**
  - [x] `shq` and the unwrap ported to Python and run through `sh -c` for each request shape: the
        lock JSON, IMEI, reboot, Rat Prefer array, an AT command with spaces and `;`, and an
        injection attempt (`$(touch /tmp/pwned)`, backticks, quotes): all arrive intact, nothing
        runs (off-device; no Lua interpreter in the workspace)
  - [ ] every Advance Modem Settings tab used once, and an AT command with a space sent (on the
        router)
- **Remaining:** the router check. `luci.jsonc.parse` of a bare JSON string is assumed to return
  the string (json-c accepts scalars); confirm on the router.

### ENH-01-T10: Operator name when `AT+COPS?` is numeric (S6)

- **Status:** review
- **From:** ENH-01-S6
- **Files:** `vendor/quectel.sh` `get_neighborcell_serving_qualcomm`, in `qmodem/0012`
- **Changes:** when the COPS operator is all digits, take the first non-empty of the full name,
  short name and SPN from `AT+QSPN`.
- **Verification:**
  - [x] under dash with stubs: `41302` + QSPN full name gives "Dialog Axiata"; an empty full name
        falls back to the short name (off-device)
  - [ ] on the router with `AT+COPS=3,2` set (on the router)

### ENH-01-T11: Auto-unlock when the locked cell is lost (S7)

- **Status:** review
- **From:** ENH-01-S7
- **Goal:** a modem locked to a cell that goes away is unlocked after N minutes, so the router
  comes back online by itself.
- **Files:**
  - new `files/usr/sbin/cw-cell-lock-guard`, `files/etc/init.d/cw-cell-lock-guard` (procd,
    START=99), `files/etc/uci-defaults/57-cw-cell-lock-guard` (enables it)
  - new `tools/tests/cw-cell-lock-guard-test.sh`
  - `qmodem/0012`: the lock request saves `lockcell_guard_enabled` / `lockcell_guard_minutes`;
    the reply reports them and the registration `state`; the form has *Unlock automatically* with
    minutes; the summary shows a chip while it is on
  - docs: `docs/modem.md#unlock-automatically`, `docs/reference/options.md`,
    `docs/reference/uci-defaults.md`, `docs/reference/files-and-ports.md`
- **Changes:** once a minute, per modem with the guard on: read `modem_ctrl.sh get_neighborcell`;
  when locked and (no serving cell, or state `SEARCH` / `LIMSRV`) for N checks in a row, send the
  page's own unlock request (which also clears the boot hook) and log it. No answer from the
  modem is not counted.
- **Verification:**
  - [x] `tools/tests/cw-cell-lock-guard-test.sh`: 15 cases pass under sh and dash (off-device)
  - [x] the build script's init-script checks pass for the new service (off-device)
  - [ ] lock to a cell, then make it unusable (or lock to a PCI that is not there) and watch the
        guard unlock after N minutes in `logread` (on the router)
- **Remaining:** the router check. The guard runs `get_neighborcell` once a minute while enabled,
  which also queries neighbours; see ENH-01-S15.

### ENH-01-T12: Signal history per cell (S8)

- **Status:** review
- **From:** ENH-01-S8
- **Files:** `modem_debug.htm`, in `qmodem/0012`
- **Changes:** each successful scan appends the RSRP of every listed cell (40 points at most,
  cells unheard for an hour dropped) to `sessionStorage`; rows with two or more points draw a
  56x16 SVG sparkline (-125 to -60 dBm) with min / max in its tooltip.
- **Scope cut:** the history lives in the browser tab, not on the router; a router-side history is
  ENH-01-S16.
- **Verification:**
  - [x] jsdom: after two scans every row has a sparkline and the tooltip reads "RSRP over the last
        2 scans: -88 to -86 dBm" (off-device)
  - [ ] on the router

### ENH-01-T13: Saved cells (S9)

- **Status:** review
- **From:** ENH-01-S9
- **Files:** `modem_debug.htm`, in `qmodem/0012`
- **Changes:** *Save cell* asks for a name and stores the form's cell in `localStorage`
  (`qm-nc-saved`); saved cells show as chips above the form (click fills the form, × forgets) and
  as a ★ tag on their row.
- **Scope cut:** kept per browser, not on the router (ENH-01-S17).
- **Verification:**
  - [x] jsdom: saved as "Home tower", chip shown, the row tagged (off-device)
  - [ ] on the router

### ENH-01-T14: Auto-refresh on the Neighbor Cell tab (S10)

- **Status:** review
- **From:** ENH-01-S10
- **Files:** `modem_debug.htm`, in `qmodem/0012`
- **Changes:** a select next to Scan (off, 15, 30, 60 s, remembered in `localStorage`); the timer
  runs only while the tab is shown and the page is visible, and stops when another tab opens.
- **Verification:**
  - [x] jsdom: timer set and stored; cleared after switching to Lock Band (off-device)
  - [ ] on the router

### ENH-01-T15: Scheduled Nikki subscription updates (S11)

- **Status:** review
- **From:** ENH-01-S11
- **Files:** `patches/feeds/nikki/0002-subscription-auto-update.patch` (`nikki/files/nikki.init`,
  `view/nikki/profile.js`); docs `docs/features/vpn-proxy.md`, `docs/reference/options.md`
- **Changes:**
  - per subscription `auto_update` and `auto_update_interval` (1, 3, 6, 12, 24 h) in its dialog;
    the Last update column shows "Auto: every N h" / "Auto: daily"
  - `nikki.init` writes one `#nikki` cron line per such subscription at start (stop removes them,
    as for the scheduled restart) running the new `auto_update_subscription`: not in use →
    download only; in use → download, restart only on success; in use with Prefer Remote →
    restart only (it downloads on start)
- **Verification:**
  - [x] the two functions run with stubs: cron lines for 6 h and daily; the four in-use / prefer /
        success cases behave as above (off-device)
  - [x] `profile.js` parses; the patch applies after 0001 (off-device)
  - [ ] a real scheduled update, in use and not in use (on the router)

### ENH-01-T16: Lock link from 3gInfo-lite (S12)

- **Status:** review
- **From:** ENH-01-S12
- **Files:** `patches/feeds/3ginfo/0007-neighbour-cell-lock-link.patch` (`3gdetail.js`,
  `radio.css`, five catalogs); `qmodem/0012` (`TabMenu` reads `?tab=`, `NeighborCell.prefill`)
- **Changes:** every neighbour (table and card layout) has *Lock…* linking to
  `admin/modem/qmodem/modem_debug?tab=NeighborCell&rat=&pci=&arfcn=`; that tab opens with the
  form filled and a note to check and press Lock. A cell without PCI or channel gets a dash.
- **Verification:**
  - [x] `lockLink` URLs for LTE and NR, and the dash case (off-device)
  - [x] jsdom: the real `TabMenu` opens Neighbor Cell from the URL, the form holds PCI 197 / ARFCN
        1725 and that row is selected after the scan (off-device)
  - [ ] on the router

### ENH-01-T17: Final check: all patches, tests, docs

- **Status:** done
- **Verification:**
  - [x] `tools/cw-apply-feed-patches.sh` on a scratch tree of the pinned feeds: every tree and
        feed patch applies (3ginfo 0002 to 0007, diskman, luci 0001 to 0011, nikki 0001 to 0003,
        qmodem 0002 to 0014), exit 0; every patched file is identical to the working copy
        (off-device)
  - [x] the JS and JSON files the Nikki and 3ginfo patches touch parse as CI parses them
        (off-device)
  - [x] all 12 `tools/tests/*-test.sh` pass (off-device)
  - [ ] `mkdocs build --strict` (not installed here; the `docs` workflow runs it)
- **Note:** `patches/feeds/luci/0010-tailscale-service-switch.patch` appeared during the session
  (not part of this batch); it applies cleanly with the rest.

## Notes

- **Theme tokens for page styles:** Vantage's `--v-*` tier first, then the Bootstrap export
  tokens from Vantage patch 0001, then literal fallbacks. Both the Nikki CSS and the QModem
  styles use this order.
- **LuCI Lua templates:** `<%:text%>` HTML-escapes (`'` becomes `&#39;`). For a string used in
  JavaScript and set with `textContent`, use `<%_text%>`, which escapes only quotes and
  backslashes. `|` in a msgid starts a translation context; avoid it.
- **QModem parameter passing:** the page sends `params` JSON-stringified twice; `qmodem.lua`
  wraps it in double quotes in a shell command, and the shell removes one level. It works only
  for values without spaces (see ENH-01-S3).
- **Vantage folds row buttons** (Edit + ⋯) only when a row has Edit and at least two other
  foldable buttons; Nikki's tables have Edit and Delete only, so they never fold.
- The Nikki debug script (`debug.sh`) enables and restarts Nikki when it is disabled; the Logs page
  asks first.
- **QModem catalogs:** LuCI loads every `*.<lang>.lmo`, so QModem's Russian file being
  `po/ru/modem.po` (not `qmodem.po`) still works; `po/zh-cn` is a copy of `po/zh_Hans` and gets
  the same entries.
- **Fragments:** QModem's page builds sentences from pieces around numbers; their translations are
  written for that order. Before reusing such a msgid elsewhere, check its translation still fits.
- **Testing the page in jsdom:** `window.onload` creates a `TabMenu`; a harness that also creates
  one gets two tab bars. That is a harness artefact, not a page bug.

## Suggestions

### Bug fixes

| ID | suggestion | why (evidence) | size | status |
|---|---|---|---|---|
| ENH-01-S1 | Rebuild only the packages a feed patch touches, not every package of a patched feed | `tools/cw-release-build.sh` step 2a-bis (line 219) invalidates all top-level packages of a patched feed; with the Nikki patch that includes mihomo-meta and mihomo-alpha (Go), so every build recompiles them | M | moved → ENH-01-T7 |
| ENH-01-S2 | Translate the new and reworded strings (zh_Hans, zh_Hant, ru) | the Nikki and QModem pages now show English for these strings in other languages; the feeds carry `po/zh_Hans`, `po/zh_Hant`, `po/ru` | M | moved → ENH-01-T8 |
| ENH-01-S3 | Pass QModem `params` to the shell safely | `qmodem.lua` line 76 builds `modem_ctrl.sh <action> <cfg> "<params>"` from a form value; a value with spaces breaks it, and shell metacharacters are interpreted. Admin-only, but still an injection path. Quote with single quotes and escape, or pass through stdin | S | moved → ENH-01-T9 |
| ENH-01-S4 | Quote `$3` in `modem_ctrl.sh` | `set_neighborcell $3` (line 303), and the other `set_*` calls, word-split their JSON argument | S | moved → ENH-01-T9 |
| ENH-01-S5 | Verify or fix NR neighbour parsing on the RG500Q-EA | the `*NR*` branch in `get_neighborcell_qualcomm` uses guessed field positions; this firmware may report NR neighbours only through `AT+QNWCFG="nr5g_meas_info"` | M | open: needs the AW1000 (capture `AT+QENG="neighbourcell"` and `AT+QNWCFG="nr5g_meas_info"` in SA mode first) |
| ENH-01-S6 | Show the operator name when `AT+COPS?` answers in numeric format | if another tool sets `AT+COPS=3,2`, `operator` is `41302`; the page then falls back to MCC-MNC. A small MCC-MNC to name table, or `AT+QSPN`, would fix it | S | moved → ENH-01-T10 |

### New features

| ID | suggestion | why | size | status |
|---|---|---|---|---|
| ENH-01-S7 | Auto-unlock safety net: unlock when the locked cell is lost or weak for N minutes | a locked modem never moves, so a cell outage leaves the router offline until someone unlocks by hand | M | moved → ENH-01-T11 |
| ENH-01-S8 | Signal history per cell (RSRP / SINR over time) on the Neighbor Cell tab or 3gInfo-lite | picking a cell to lock is easier with a trend than with one reading | L | moved → ENH-01-T12 |
| ENH-01-S9 | Saved cells: name a cell, lock to it from a short list | users who switch between two cells re-enter PCI and ARFCN each time | S | moved → ENH-01-T13 |
| ENH-01-S10 | Auto-refresh toggle on the Neighbor Cell tab | the tab scans on open and on Scan only | S | moved → ENH-01-T14 |
| ENH-01-S11 | Nikki subscription auto-update schedule on the Profiles page | subscriptions update only at start (Prefer: Remote) or by hand | M | moved → ENH-01-T15 |
| ENH-01-S12 | A "Lock this cell" link from 3gInfo-lite's cell list to the Neighbor Cell tab | 3gInfo-lite already shows the cells; the lock is two pages away | S | moved → ENH-01-T16 |

### Added while completing the batch

| ID | suggestion | why (evidence) | size | status |
|---|---|---|---|---|
| ENH-01-S13 | Translate the 3gInfo-lite radio page | 185 to 189 of its 205 strings have no translation in zh_Hans, ru, pl, de, it (3ginfo patch 0004 added most of them) | M | open |
| ENH-01-S14 | Remove the duplicate entries in QModem's catalogs | `msgfmt` reports 26 duplicates in `po/zh_Hans/qmodem.po` and `po/zh-cn/qmodem.po`, 8 in `po/ru/modem.po`; `po2lmo` keeps one silently, possibly the wrong one | S | open |
| ENH-01-S15 | A light "lock status" action for the guard | `cw-cell-lock-guard` calls `get_neighborcell` once a minute, which also runs `AT+QENG="neighbourcell"`, `AT+COPS?` and maybe `AT+QSPN`; a `get_lock_status` action (QNWLOCK queries and servingcell only) would halve the AT traffic shared with the LED daemon and 3gInfo-lite | S | open |
| ENH-01-S16 | Router-side signal history | the sparkline history (T12) lives in one browser tab; a small collector (or 3gInfo-lite's snapshot) could keep hours of RSRP / SINR per cell | L | open |
| ENH-01-S17 | Saved cells on the router | saved cells (T13) are per browser; storing them in `/etc/config/qmodem` would share them between devices and survive a browser reset | S | open |
| ENH-01-S18 | Russian plural forms | LuCI's `_()` has no plural forms, so "%d строк", "Осталось дней: %d" read awkwardly for some numbers; `N_()` could be used where counts are shown | S | open |
