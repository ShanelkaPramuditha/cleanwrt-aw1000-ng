---
batch: ENH-01
title: "Nikki pages, Vantage row buttons, QModem cell lock"
status: review
started: 2026-11-24
updated: 2026-11-24
---

# ENH-01: Nikki pages, Vantage row buttons, QModem cell lock

User requests of 2026-11-24, worked in one session: redesign every Nikki page for usability; fix
uneven spacing between row buttons; offer a way to lock the modem to a cell, from a list of the
cells around the router with operator and signal data and a click to lock; tidy the padding on
*Advance Modem Settings*; set up this work log.

All code is written and checked off-device. **Nothing has been tested on a router yet, and
nothing is committed.**

## Summary

| ID | task | status | patch / files |
|---|---|---|---|
| ENH-01-T1 | Redesign all Nikki LuCI pages | review | `patches/feeds/nikki/0001-luci-pages-redesign.patch` |
| ENH-01-T2 | Even spacing between table row buttons (Vantage) | review | `patches/packages/luci-theme-vantage/0004-row-actions-gap.patch` |
| ENH-01-T3 | Cell list and cell lock on QModem's Neighbor Cell tab | review | `patches/feeds/qmodem/0012-neighbor-cell-list-and-lock.patch` |
| ENH-01-T4 | Padding and button rows on every Advance Modem Settings tab | review | same patch as T3 |
| ENH-01-T5 | Check all patch sets apply together | done | none (check only) |
| ENH-01-T6 | Agent-friendly docs and this work log | done | `AGENTS.md`, `CLAUDE.md`, `docs/enhanced/` |

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

## Suggestions

### Bug fixes

| ID | suggestion | why (evidence) | size | status |
|---|---|---|---|---|
| ENH-01-S1 | Rebuild only the packages a feed patch touches, not every package of a patched feed | `tools/cw-release-build.sh` step 2a-bis (line 219) invalidates all top-level packages of a patched feed; with the Nikki patch that includes mihomo-meta and mihomo-alpha (Go), so every build recompiles them | M | open |
| ENH-01-S2 | Translate the new and reworded strings (zh_Hans, zh_Hant, ru) | the Nikki and QModem pages now show English for these strings in other languages; the feeds carry `po/zh_Hans`, `po/zh_Hant`, `po/ru` | M | open |
| ENH-01-S3 | Pass QModem `params` to the shell safely | `qmodem.lua` line 76 builds `modem_ctrl.sh <action> <cfg> "<params>"` from a form value; a value with spaces breaks it, and shell metacharacters are interpreted. Admin-only, but still an injection path. Quote with single quotes and escape, or pass through stdin | S | open |
| ENH-01-S4 | Quote `$3` in `modem_ctrl.sh` | `set_neighborcell $3` (line 303), and the other `set_*` calls, word-split their JSON argument | S | open |
| ENH-01-S5 | Verify or fix NR neighbour parsing on the RG500Q-EA | the `*NR*` branch in `get_neighborcell_qualcomm` uses guessed field positions; this firmware may report NR neighbours only through `AT+QNWCFG="nr5g_meas_info"` | M | open |
| ENH-01-S6 | Show the operator name when `AT+COPS?` answers in numeric format | if another tool sets `AT+COPS=3,2`, `operator` is `41302`; the page then falls back to MCC-MNC. A small MCC-MNC to name table, or `AT+QSPN`, would fix it | S | open |

### New features

| ID | suggestion | why | size | status |
|---|---|---|---|---|
| ENH-01-S7 | Auto-unlock safety net: unlock when the locked cell is lost or weak for N minutes | a locked modem never moves, so a cell outage leaves the router offline until someone unlocks by hand | M | open |
| ENH-01-S8 | Signal history per cell (RSRP / SINR over time) on the Neighbor Cell tab or 3gInfo-lite | picking a cell to lock is easier with a trend than with one reading | L | open |
| ENH-01-S9 | Saved cells: name a cell, lock to it from a short list | users who switch between two cells re-enter PCI and ARFCN each time | S | open |
| ENH-01-S10 | Auto-refresh toggle on the Neighbor Cell tab | the tab scans on open and on Scan only | S | open |
| ENH-01-S11 | Nikki subscription auto-update schedule on the Profiles page | subscriptions update only at start (Prefer: Remote) or by hand | M | open |
| ENH-01-S12 | A "Lock this cell" link from 3gInfo-lite's cell list to the Neighbor Cell tab | 3gInfo-lite already shows the cells; the lock is two pages away | S | open |
