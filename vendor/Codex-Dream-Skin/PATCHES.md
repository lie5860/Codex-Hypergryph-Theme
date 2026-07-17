# Vendored Codex Dream Skin

Source: https://github.com/Fei-Away/Codex-Dream-Skin

Pinned commit: `a1c48b3a84cc64532196e624fdf33ee1277cb018`

The `windows` engine scripts, tests, and documentation are a snapshot of that
commit with these downstream changes:

- Removed `-WindowStyle Hidden` from the injector and tray process launches. This
  keeps all child process execution visible and auditable under the repository's
  enterprise endpoint policy.
- Omitted `windows/assets`. This repository supplies its own CSS, renderer,
  configuration, and original background when it assembles the runtime.

The upstream `macos/LICENSE` and `macos/NOTICE.md` files are copied beside this
document. Upstream's root README states that this MIT license applies to its
software source code; the notice excludes its bundled third-party artwork.
