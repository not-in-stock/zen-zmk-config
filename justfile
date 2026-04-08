default: (build "crpd")

# Build a firmware configuration.
# Usage: `just build zen` / `just build corne` / `just build crpd`.
#   zen   - standalone Corne-ish Zen (both halves)
#   corne - standalone wireless Corne (central_left + right)
#   crpd  - Corne + Prospector Dongle (dongle + left + right)
build TARGET:
    #!/usr/bin/env bash
    set -e
    mkdir -p build
    case "{{TARGET}}" in
      zen)   nix build .#zen      -o build/zen ;;
      corne) nix build .#wireless -o build/corne ;;
      crpd)  nix build .#dongle   -o build/crpd ;;
      *) echo "usage: just build zen|corne|crpd" >&2; exit 2 ;;
    esac

# Build a settings-reset firmware. The reset image is board-specific, so
# there's one per board rather than per SoC.
# Usage: `just build-reset TARGET` where TARGET is one of:
#   nice-nano - for standalone corne / CRPD halves (nice!nano)
#   xiao      - for the CRPD Prospector dongle (XIAO BLE)
#   zen-left  - for the left Corne-ish Zen half
#   zen-right - for the right Corne-ish Zen half
build-reset TARGET:
    #!/usr/bin/env bash
    set -e
    mkdir -p build
    case "{{TARGET}}" in
      nice-nano) nix build .#nice_nano_reset -o build/reset-nice-nano ;;
      xiao)      nix build .#xiao_reset      -o build/reset-xiao ;;
      zen-left)  nix build .#zen_left_reset  -o build/reset-zen-left ;;
      zen-right) nix build .#zen_right_reset -o build/reset-zen-right ;;
      *) echo "usage: just build-reset nice-nano|xiao|zen-left|zen-right" >&2; exit 2 ;;
    esac

# Build everything
build-all: (build "zen") (build "corne") (build "crpd")

# Remove build symlinks
clean:
    rm -rf build result result-*

# Internal: copy a UF2 to the first /Volumes/<GLOB> that appears (double-tap reset first).
# UF2 bootloaders eject the volume mid-write, so cp errors are expected; success is
# detected by the volume disappearing afterwards.
[private]
_flash-uf2 uf2 glob label:
    #!/usr/bin/env bash
    set -euo pipefail
    uf2='{{uf2}}'
    glob='{{glob}}'
    label='{{label}}'
    if [ ! -e "$uf2" ]; then
      echo "Missing firmware file: $uf2" >&2
      exit 1
    fi
    echo "Waiting for $label bootloader volume matching /Volumes/$glob …"
    echo "(double-tap reset if not already in bootloader mode)"
    vol=""
    for i in $(seq 1 60); do
      for v in /Volumes/$glob; do
        if [ -d "$v" ]; then vol="$v"; break; fi
      done
      if [ -n "$vol" ]; then break; fi
      sleep 1
    done
    if [ -z "$vol" ]; then
      echo "No bootloader volume found after 60s." >&2
      echo "Check /Volumes/ and adjust the glob in justfile if your mount name differs." >&2
      exit 1
    fi
    echo "Flashing $uf2 → $vol/"
    cp "$uf2" "$vol/" || true
    for i in $(seq 1 10); do
      if [ ! -d "$vol" ]; then
        echo "Done — volume ejected, firmware flashed."
        exit 0
      fi
      sleep 1
    done
    echo "Warning: volume still mounted after 10s. Flash may have failed." >&2
    exit 1

# Flash a Corne-ish Zen half. Usage: `just flash-zen left` / `just flash-zen right`.
flash-zen SIDE: (build "zen")
    @just _flash-uf2 build/zen/zen_{{SIDE}}.uf2 'CORNEISHZEN*' 'Corne-ish Zen {{SIDE}}'

# Flash a standalone wireless Corne half (central_left + peripheral right).
# Usage: `just flash-corne central_left` / `just flash-corne right`.
flash-corne SIDE: (build "corne")
    #!/usr/bin/env bash
    set -e
    case "{{SIDE}}" in
      central_left|right) ;;
      *) echo "usage: just flash-corne central_left|right" >&2; exit 2 ;;
    esac
    just _flash-uf2 build/corne/corne_{{SIDE}}.uf2 'NICENANO*' 'Corne {{SIDE}}'

# Flash a CRPD (Corne + Prospector Dongle) part.
# Usage: `just flash-crpd dongle` / `left` / `right`.
flash-crpd PART: (build "crpd")
    #!/usr/bin/env bash
    set -e
    case "{{PART}}" in
      dongle) just _flash-uf2 build/crpd/corne_dongle.uf2 'XIAO-SENSE*' 'CRPD dongle' ;;
      left|right) just _flash-uf2 build/crpd/corne_{{PART}}.uf2 'NICENANO*' 'CRPD {{PART}}' ;;
      *) echo "usage: just flash-crpd dongle|left|right" >&2; exit 2 ;;
    esac

# Flash a settings-reset firmware.
# Usage: `just flash-reset nice-nano|xiao|zen-left|zen-right`.
flash-reset TARGET: (build-reset TARGET)
    #!/usr/bin/env bash
    set -e
    case "{{TARGET}}" in
      nice-nano) just _flash-uf2 build/reset-nice-nano/zmk.uf2  'NICENANO*'    'nice!nano reset' ;;
      xiao)      just _flash-uf2 build/reset-xiao/zmk.uf2       'XIAO-SENSE*'  'XIAO BLE reset' ;;
      zen-left)  just _flash-uf2 build/reset-zen-left/zmk.uf2   'CORNEISHZEN*' 'Zen left reset' ;;
      zen-right) just _flash-uf2 build/reset-zen-right/zmk.uf2  'CORNEISHZEN*' 'Zen right reset' ;;
      *) echo "usage: just flash-reset nice-nano|xiao|zen-left|zen-right" >&2; exit 2 ;;
    esac
