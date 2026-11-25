# AGENTS.md

Start here if you are an AI coding agent (or a person new to the repo). This file says what the
repository is, where things live, the rules every change follows, and where work is tracked.

## What this repository is

CleanWRT: an OpenWrt firmware build for the Arcadyan AW1000 5G router. The repository does not
carry OpenWrt itself; it carries **pins, patches, configs, files and build scripts**, and the
build assembles an image from them.

| path | what it holds |
|---|---|
| `feeds.conf.default` | the feeds and the commit each one is pinned to (`src-git name url^sha`) |
| `configs/arcadyan_aw1000.seed` | the build seed: every package the image selects |
| `configs/local-packages.pin` | packages cloned outside the feeds (Vantage theme, AWvoice, ...), each pinned to a commit |
| `patches/feeds/<feed>/NNNN-*.patch` | changes to a feed, applied inside `feeds/<feed>` |
| `patches/packages/<name>/NNNN-*.patch` | changes to a locally pinned package, applied to its clone |
| `patches/tree/NNNN-*.patch` | changes to files the OpenWrt tree carries itself |
| `files/` | files copied into the image as they are (`/etc/uci-defaults/...` and more) |
| `tools/` | build, release and check scripts; `tools/tests/*-test.sh` are their tests |
| `docs/` | the public documentation site (MkDocs, `mkdocs.yml`) |
| `docs/enhanced/` | **the work log: enhancement batches, their tasks and progress** (not published) |
| `NOTICE.md`, `README.md` | change tables that list every patch and file this repo adds |

The OpenWrt tree used for local builds sits next to this repo at `../openwrt`; its feeds are
under `../openwrt/feeds/<feed>`. It is not part of this repository.

## Where work is tracked

All enhancement work is logged in [`docs/enhanced/`](docs/enhanced/README.md):

- Read `docs/enhanced/README.md` first: the numbering, statuses and rules.
- The **highest-numbered `enh-NN.md`** is the current batch. Its last section holds the open
  suggestions (bug fixes and features) that a new batch can pick up.
- **Update the batch file while you work, not at the end.** After every step that changes a task,
  update its status, its *Verification* boxes, the *Progress* table, the `progress:` counts, the
  *Progress log* (with the UTC time) and the index row in `docs/enhanced/README.md`.
- Do not mark a task `done` that you did not verify; say what was and was not tested.

## Rules for every change

1. **Patches apply with zero fuzz.** `tools/cw-apply-feed-patches.sh` applies feed and tree
   patches with `patch -p1 -F0`; local package patches are applied the same way by
   `tools/cw-release-build.sh`. A patch that needs fuzz fails the build on purpose.
2. **A new patch goes after the last one** of its set (`0012-...` after `0011-...`) and is made
   against the source *with the earlier patches applied*. Never edit an earlier patch to carry
   an unrelated change.
3. **Every patch starts with a header:** a one-line title, what was wrong, what changes, then
   `Applies to: <repo> @ <short sha>, after <previous patch>.` and
   `Upstream status: local to CleanWRT.` (see any file in `patches/` for the form).
4. **Generate patches from a clean pair of trees**, not by hand: a copy of the pinned source with
   the earlier patches applied (`a/`) and your edited copy (`b/`), diffed with `a/` and `b/`
   prefixes. Then check that the patch applies with `-F0` to a fresh clone, gives a tree identical
   to `b/`, and reverses cleanly.
5. **Every new patch or image file is listed** in the same change:
   - `docs/building.md` (the patch table of its feed or package),
   - `NOTICE.md` (the dated change table, and a licence paragraph for a third-party package),
   - `README.md` (the change table),
   - `docs/changelog.md` (a bullet in user terms),
   - the user page it affects (`docs/modem.md`, `docs/theme.md`, ...), with its `updated:` date.
6. **Do not edit the OpenWrt tree or the feeds as the fix.** Changes there are lost on the next
   `feeds update`; they belong in a patch here.
7. **Nothing is committed or pushed unless the user asks.** `main` is protected: every change is
   a pull request (see `docs/contributing.md`).
8. **Never commit or print secrets.** `keys-release/` holds the private signing keys and is
   git-ignored: do not open, copy or quote it. Wi-Fi keys, tokens and IMEI/IMSI/ICCID numbers
   never go into the repository, a patch or a log.

## Checking a change

| check | how |
|---|---|
| shell syntax | `sh -n file` (`bash -n` for bash scripts); CI runs this on every script |
| tool tests | `for t in tools/tests/*-test.sh; do sh "$t"; done` |
| patches apply | run `tools/cw-apply-feed-patches.sh <openwrt-tree>` on a scratch tree with the pinned feeds; every patch must report `applied` |
| LuCI JavaScript | CI parses every `.js` a patch touches with `new Function(src)` and every `.json` with `JSON.parse`; do the same locally with node |
| docs site | `mkdocs build --strict` (the `docs` workflow does this) |
| on the router | LuCI pages and modem behaviour need a real AW1000; when you could not test there, say so in the task's *Verification* |

## Writing for this repo

- User docs (`docs/`, except `docs/enhanced/`) are for router owners: plain words, the menu path
  in italics (*Modem → QModem*), what to click, what happens, and a warning when something can cut
  the connection.
- Work-log files (`docs/enhanced/`) are for agents and maintainers: exact paths, IDs, statuses,
  commands and what was verified.
- Dates are absolute (`2026-11-24`), never "today" or "last week".
