---
title: "Theme: Vantage"
description: "The web interface of CleanWRT: Vantage, its theme with the Dashboard, light and dark modes, and LuCI's own Bootstrap as the fallback."
updated: 2026-11-23
---

# Theme

CleanWRT ships one third-party LuCI theme, and LuCI's own Bootstrap as the fallback:

| Theme | Licence | In the image |
|---|---|---|
| [Vantage](#vantage) ([`luci-theme-vantage`](https://github.com/anothaDev/luci-theme-vantage) + `luci-app-vantage`) | GPL-3.0-or-later | the default |
| Bootstrap (LuCI's own) | Apache-2.0 | the fallback |

Vantage is pinned to one commit in `configs/local-packages.pin`, like every other out-of-feed
package here.

Footstrap, the default before Vantage, is no longer in the image. With one theme, every layout fix
is made and checked once instead of twice. A router that was on Footstrap moves to Vantage at the
first boot after the upgrade (see [Switching themes](#switching-themes)).

## Vantage

Vantage is a console-style theme: an icon rail with flyout menus, a breadcrumb, page tabs, a
**Ctrl+K** command palette, and light, dark and auto modes from the button in the top bar. Its
companion package `luci-app-vantage` adds the **Dashboard**, the first page after login: live
traffic, the network path, clients and radios. The Appearance settings under the gear button are
saved on the router in `/etc/config/vantage_theme`, so every browser sees the same look.

CleanWRT changes three things in it:

- `patches/packages/luci-theme-vantage/0001-export-tier-for-stock-theme-pages.patch` makes Vantage
  publish the colour tokens LuCI's Bootstrap theme publishes (`--background-color-high`,
  `--text-color-highest` and the rest), mapped onto its own palette. Pages written for the stock
  themes colour themselves from those tokens - *Modem → 3gInfo-lite*, QModem's signal bars, the
  AWvoice phone page - and without them fell back to white tiles and dark text on Vantage's dark
  cards.
- `patches/packages/luci-theme-vantage/0002-legacy-tabs-and-legend-cards.patch` covers two patterns
  of pages that build their own markup: tabs made of bare list items, and cards headed by a
  `<legend>`. QModem's pages use both.
- `patches/packages/luci-theme-vantage/0003-page-actions-without-card.patch` takes the card away
  from behind the *Reset* / *Save* / *Save & Apply* buttons at the bottom of a page. They still
  stay docked at the bottom right while you scroll, each with a soft shadow of its own.

`patches/packages/luci-app-cw-led/0002-lamp-colours-follow-the-theme-switch.patch` makes the lamps on
the LED page follow Vantage's light/dark switch rather than the browser's preference.

Vantage's full documentation, including its own troubleshooting, is in
[its repository](https://github.com/anothaDev/luci-theme-vantage/blob/main/docs/INSTALL.md).

## Switching themes

The interface opens in Vantage. To use LuCI's own Bootstrap instead:

*System → System → Language and Style → Design*

Over SSH:

```sh
uci set luci.main.mediaurlbase=/luci-static/bootstrap   # or /luci-static/vantage
uci commit luci
```

**After an upgrade that keeps the settings**, a router stays on the theme it had as long as that
theme is still installed (`files/etc/uci-defaults/29-cw-keep-chosen-theme` keeps Vantage's own
first-boot script from taking it over). A theme the image no longer carries - Footstrap, or one you
installed yourself with `apk`, which an upgrade removes - would leave the interface with no styles,
so `files/etc/uci-defaults/96-cw-default-theme` moves such a router to Vantage and removes the dead
entry from the design list. The Footstrap settings left behind (`/etc/config/footstrap`,
`/etc/footstrap/`) are removed by `95-cw-drop-removed-apps`.

Bootstrap is the fallback: if the pinned theme did not install, `96-cw-default-theme` leaves the
stock base alone, so the web interface still opens, and Bootstrap is always a choice in the selector.

## Notes for developers

Vantage installs its templates under `/usr/share/ucode/luci/template/themes/vantage/`, its resources
under `/www/luci-static/vantage/` and `/www/luci-static/resources/vantage-theme/`, and the conffile
`/etc/config/vantage_theme`. The Dashboard adds `admin/dashboard` as the first menu entry, the rpcd
ACL `luci-app-vantage` and `/etc/config/vantage` (the names you give devices). Under another theme,
*Dashboard* opens LuCI's Status → Overview instead.

## Common questions

??? question "Does CleanWRT have a dark mode?"
    Yes: the light / dark / auto button in Vantage's top bar.

??? question "A page looks wrong in dark mode"
    Pages from LuCI apps colour themselves; most follow the theme, some carry light colours of their
    own. Reload with Ctrl+Shift+R first (LuCI caches scripts by its own version). If it persists,
    note the page and open an issue.

??? question "Does the theme work on a phone?"
    Yes. Vantage's rail becomes a bottom bar on narrow screens, and its command bar and tabs adapt to
    the width.

??? question "How do I switch back to the default OpenWrt theme?"
    Go to *System → System → Language and Style → Design* and pick Bootstrap. Bootstrap stays
    installed in the image precisely so that this is always possible.

??? question "Where did Footstrap go?"
    It is not in the image any more: one theme means every page is made to look right once. A
    router that used it moves to Vantage when upgraded. To use it anyway, install it from the LuCI
    feed (`apk add luci-theme-footstrap`, an older copy than the image used to carry) and pick it
    under *Design*; an upgrade removes it again.
