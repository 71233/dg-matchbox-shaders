# dg-matchbox-shaders

**DIGITAL GARDEN** Matchbox shaders for **Autodesk Flame** (target: **2025.2.7**, Rocky Linux and macOS).

This public repository distributes **encrypted `.mx` packages** and a **generic installer** only. Shader sources are not published.

## Install

```bash
git clone https://github.com/71233/dg-matchbox-shaders.git
cd dg-matchbox-shaders
./install/install.sh
```

The installer copies `.mx` files into:

`/opt/Autodesk/presets/<Flame-version>/matchbox/shaders/DG/`

It targets Flame versions that support the 2025.2.7 Matchbox feature set used by this package. Older presets are skipped.

Run as a user that can write to those paths. If permission is denied, re-run with the account your site uses for Flame preset maintenance (often an elevated shell). Do not paste passwords into scripts.

## Layout (public)

| Path | Contents |
|------|----------|
| `dist/` | Released encrypted `.mx` files and `manifest.json` |
| `install/` | Cross-platform installer |
| `LICENSE` | Terms (redistribution prohibited) |

## License

DIGITAL GARDEN proprietary — **redistribution prohibited**. See [LICENSE](./LICENSE).

## Status

Repository scaffolding is in place. Shaders will be published to `dist/` as each effect is validated on Flame 2025.2.7 (Linux and macOS).
