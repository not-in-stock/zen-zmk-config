[![Build ZMK firmware](https://github.com/not-in-stock/zen-zmk-config/actions/workflows/build.yml/badge.svg)](https://github.com/not-in-stock/zen-zmk-config/actions/workflows/build.yml)

# zen-zmk-config

Personal ZMK firmware configuration for Corne-style split keyboards. Inspired by [urob's timeless homerow mods](https://github.com/urob/zmk-config) and [Miryoku](https://github.com/manna-harbour/miryoku) layout principles.

**Compatible with 36 and 42 key layouts** — the outer pinky columns contain only secondary functions (Caps Lock, brackets, backslash), so 36-key boards work too.

![Keymap](keymap/base.svg)

## Features

### Timeless Homerow Mods

Traditional homerow mods suffer from accidental activations during fast typing. This config uses urob's "timeless" approach with aggressive `require-prior-idle-ms` settings:

```
tapping-term-ms = <5000>;        // effectively infinite
require-prior-idle-ms = <260>;   // key won't act as modifier unless idle
hold-trigger-on-release;         // wait until key release to decide
hold-trigger-key-positions = ... // only trigger from opposite hand
```

This means the modifier only activates when:
1. You paused typing for at least 260ms before pressing the key
2. The next keypress comes from the opposite hand

Result: virtually no misfires during normal typing, while still allowing comfortable modifier access.

### Miryoku-Inspired Layer Structure

**Homerow modifiers** (Ctrl-Alt-Cmd-Shift pattern):
- Left hand: `A`=Ctrl, `S`=Alt, `D`=Cmd, `F`=Shift
- Right hand: mirrored — `J`=Shift, `K`=Cmd, `L`=Alt, `;`=Ctrl

**Thumb keys** use layer-tap for one-shot layer access:
| Key | Tap | Hold |
|-----|-----|------|
| Left outer | Esc | Mouse |
| Left middle | Tab | Nav |
| Left inner | Space | Symbols |
| Right inner | Return | Numbers |
| Right middle | Backspace | Fn |
| Right outer | Delete | Config |

**Mirrored modifiers on every layer** — each layer has the same modifier positions, so you can combine modifiers with layer actions using only one hand.

### Layers

| Layer | Purpose |
|-------|---------|
| **BASE** | QWERTY with homerow mods |
| **SYM** | Symbols with shift-morphing (one key = two symbols) |
| **NUM** | Numbers 1-9, 0 on the left side |
| **FN** | Function keys F1-F12 |
| **NAV** | Arrow keys, Home/End, Page Up/Down |
| **MOUSE** | Mouse emulation (movement + scroll + clicks) |
| **CONF** | Bluetooth, media controls, brightness, system reset |
| **GAME** | Gaming mode without homerow mods |

### Shift-Morphing Symbols

The SYM layer uses `mod-morph` to pack two symbols per key. Tap for primary, Shift+tap for secondary:

| Tap | Shifted |
|-----|---------|
| `?` | `!` |
| `[` | `{` |
| `'` | `"` |
| `]` | `}` |
| `-` | `+` |
| `(` | `<` |
| `/` | `\` |
| `)` | `>` |
| `#` | `*` |
| `^` | `%` |
| `\|` | `_` |
| `$` | `` ` `` |
| `=` | `~` |
| `@` | `&` |
| `:` | `;` |

### macOS Globe Key

The `V` and `M` keys have Globe (🌐) on hold for quick access to macOS features like Emoji picker, Dictation, etc.

### Gaming Mode

Press both inner thumb keys simultaneously to toggle gaming mode. This layer disables homerow mods for uninterrupted WASD gameplay. Same combo switches back to normal mode.

### Bluetooth Controls

The CONF layer provides Bluetooth profile selection (0-4). Hold Shift while selecting a profile to clear its pairing — no separate "clear" keys needed.

## Building

Firmware is built automatically via GitHub Actions. Download the latest artifacts from the [Actions tab](https://github.com/not-in-stock/zen-zmk-config/actions).

## Credits

- [urob/zmk-config](https://github.com/urob/zmk-config) — timeless homerow mods concept and helper macros
- [urob/zmk-helpers](https://github.com/urob/zmk-helpers) — ZMK convenience macros
- [Miryoku](https://github.com/manna-harbour/miryoku) — layer structure inspiration
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) — keymap visualization
