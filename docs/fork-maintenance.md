---
title: "Maintaining this fork"
description: "How this fork of CleanWRT stays in step with upstream: merging Pr0Luci's changes, the version label, signing keys, pinned packages and the rules for credits."
---

# Maintaining this fork

This repository is a fork of [Pr0Luci/cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000).
It follows upstream and carries its own changes on top (the list is in the README, under
*Changes in this fork*, and in `NOTICE.md`). This page is for whoever maintains the fork.

## Never push to upstream

All work goes to this fork. In a local clone, `origin` is the fork and `upstream` is Pr0Luci's
repository, which is only fetched from. Disable pushing to it once per clone:

```sh
git remote add upstream https://github.com/Pr0Luci/cleanwrt-aw1000.git   # if missing
git remote set-url --push upstream DISABLED-do-not-push-to-upstream
```

GitHub's *Compare & pull request* button on a fork picks **upstream** as the base. If you open a
pull request at all, change the base repository to `ShanelkaPramuditha/cleanwrt-aw1000-ng` first.

## Taking upstream's changes

Merge small and often: one upstream release at a time is far easier than six.

```sh
git fetch upstream
git switch main
git merge upstream/main
```

Expect conflicts where the fork differs on purpose, and resolve them in the fork's favour:

| Where | What the fork keeps |
|---|---|
| `configs/arcadyan_aw1000.seed` | no Passwall, Passwall 2, HomeProxy, AdGuard Home or Adblock; Nikki, `mihomo-meta`, `nikki-zashboard`; `TOOLCHAINOPTS` on and `GDB` off; the fork's version label and URLs |
| `feeds.conf.default` | no Passwall feeds; the `nikki` feed |
| `configs/local-packages.pin` | no HomeProxy pin |
| `tools/cw-release-build.sh` | `CW_VERSION` with the `-SP<n>` suffix; the os-release URLs; no xray gate; the clean-on-fresh-tree skip |
| `patches/feeds/luci/0007-upgrade-check-cdn-no-asu.patch` | the fork's version feed URL and the full-label version comparison |
| `files/etc/apk/keys/public-key.pem` | the fork's own key, never upstream's |
| README, `NOTICE.md`, docs | the fork notice, the fork's links, the change tables, the credits |

If upstream adds something back that the fork removed, keep it out and note it in the change
tables. If upstream fixes a bug in code the fork also carries, take the fix.

After the merge, run `cw-dev tests` and `cw-dev check` before pushing.

## The version label

Fork builds are named after the upstream release they are based on, plus `-SP<n>`:
`25.12.5-R2.2-SP1` is the first fork build on upstream `25.12.5-R2.2`, `-SP2` the next. After
merging a new upstream release, start again at `-SP1` (for example `25.12.5-R2.3-SP1`).

The label lives in two places that must agree, and the build fails if they do not:

- `CW_VERSION` in `tools/cw-release-build.sh`
- `CONFIG_VERSION_NUMBER` in `configs/arcadyan_aw1000.seed`

A release tag is `v<label>`, e.g. `v25.12.5-R2.2-SP1`. The router's newer-version notice compares
every number of the label, so `-SP2` is offered to a router on `-SP1`.

**The `-SP<n>` number moves by itself.** When the release workflow publishes `v<label>`, its last
step runs `tools/cw-bump-version.sh --released <label>` on the default branch and pushes the result
as `github-actions[bot]`:

- `CW_VERSION` and the seed move to the next `-SP<n>` together;
- in `docs/changelog.md`, the released section loses its "(this fork, not yet released)" and an
  empty section for the next label opens above it;
- `docs/index.md`, the site's `softwareVersion` and the issue templates name the release as the
  current version.

So `main` is always one label ahead of the newest tag. Write each change into the open changelog
section as you make it: the build's release checks refuse a draft whose section is empty, before
the two-hour build starts. If the push is refused (branch protection) or a release was published
some other way, run the same command by hand, commit and push. After merging a new upstream release,
set the label to the upstream one plus `-SP1` by hand, as before.

## Signing keys

The fork signs with its own keys. The private halves never enter the repository: `keys-release/`
is in `.gitignore`.

| Key | File (local) | Repository secret | Used for |
|---|---|---|---|
| apk feed key (EC P-256) | `keys-release/apk-private-key.pem`, also `<tree>/private-key.pem` | `APK_PRIVATE_KEY` | signs the package index; routers trust its public half, `files/etc/apk/keys/public-key.pem` |
| usign image key (ed25519) | `keys-release/key-build`, `key-build.pub` | `USIGN_KEY_BUILD`, `USIGN_KEY_BUILD_PUB` | signs sysupgrade images |

Back both up offline. A lost apk key means routers can no longer verify the fork's feed; a leaked
one means rotating it and shipping a new public key in an image.

`tools/cw-check-release-keys.sh <tree>` proves a build tree signs with the key the image ships.

## When the draft release is refused

`HTTP 403: Resource not accessible by integration` in the build's *Draft release* step, or in
the release workflow's *Publish* step, means GitHub refused the workflow's own token. The
workflows ask for `contents: write`, so the refusal has one of these causes:

1. **The commit changes a workflow file.** A release aimed at a commit that changes anything
   under `.github/workflows/` (and, once published, the tag on it) needs the **Workflows**
   permission, which the workflow token can never hold. The asset uploads still succeed, and
   then `gh release edit --target` fails. This is the usual cause after a workflow change.
2. *Settings → Actions → General → Workflow permissions*: **Read and write permissions**. A
   repository created new (rather than renamed) starts read-only. Every workflow here declares its
   own narrower permissions, so this widens nothing else.
3. *Settings → Rules → Rulesets*: a rule on `v*` tags or on releases blocks the workflow token too.

The fix for all three is a token of the step's own: create a fine-grained personal access token
(*GitHub → Settings → Developer settings → Fine-grained tokens*) for **this repository only**,
with **Contents: Read and write** and **Workflows: Read and write**, and save it as the
repository secret `RELEASE_TOKEN`. The build's *Draft release* step and the release workflow's
*Publish* step use it when it exists, and the workflow token otherwise. Give it an expiry and
renew it when GitHub warns you.

## Pinned packages to bump now and then

| What | Where | How |
|---|---|---|
| Nikki + mihomo | `feeds.conf.default`, the `nikki` line | move the commit after `^`; `cw-dev check` |
| Zashboard | `feeds-src/cwfeed/net/nikki-zashboard/Makefile` | `PKG_VERSION` and `PKG_HASH` (the sha256 of that release's `dist-no-fonts.zip`), and `files/LICENSE` from the same tag |

Upstream's own pins (OpenWrt, LuCI, QModem, AWvoice, the LED app, the theme) come with upstream
merges; leave them to upstream unless something breaks.

## Credits

Upstream's copyright lines, `LICENSE`, `NOTICE.md` credits and the README *Thanks* stay as they
are. Every file the fork adds or changes gets a dated row in `NOTICE.md` (*This fork*), as GPL-2.0
section 2(a) asks, and a row in the README's *Changes in this fork*. A third-party component the
image ships is credited in *Thanks* and listed with its licence in `NOTICE.md`; one that leaves
the image leaves those lists too.
