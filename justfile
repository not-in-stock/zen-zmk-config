default: dongle

# Classic wireless Corne: central left + peripheral right
wireless:
    mkdir -p build
    nix build .#wireless -o build/wireless

# Wired USB dongle + two peripheral halves
dongle:
    mkdir -p build
    nix build .#dongle -o build/dongle

# Settings-reset firmwares (nice_nano + xiao)
reset:
    mkdir -p build
    nix build .#reset -o build/reset

# Corne-ish Zen halves (both)
zen:
    mkdir -p build
    nix build .#zen -o build/zen

# Build both topologies
all: wireless dongle

# Remove build symlinks
clean:
    rm -rf build result result-*

# Flash the default firmware to a connected bootloader
flash:
    nix run .#flash

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
flash-zen SIDE: zen
    @just _flash-uf2 build/zen/zen_{{SIDE}}.uf2 'CORNEISHZEN*' 'Corne-ish Zen {{SIDE}}'

# Flash a standalone wireless Corne half (central_left + peripheral right).
# Usage: `just flash-corne central_left` / `just flash-corne right`.
flash-corne SIDE: wireless
    #!/usr/bin/env bash
    set -e
    case "{{SIDE}}" in
      central_left|right) ;;
      *) echo "usage: just flash-corne central_left|right" >&2; exit 2 ;;
    esac
    just _flash-uf2 build/wireless/corne_{{SIDE}}.uf2 'NICENANO*' 'Corne {{SIDE}}'

# Flash a CRPD (Corne + Prospector Dongle) part.
# Usage: `just flash-crpd dongle` / `left` / `right`.
flash-crpd PART: dongle
    #!/usr/bin/env bash
    set -e
    case "{{PART}}" in
      dongle) just _flash-uf2 build/dongle/corne_dongle.uf2 'XIAO-SENSE*' 'CRPD dongle' ;;
      left|right) just _flash-uf2 build/dongle/corne_{{PART}}.uf2 'NICENANO*' 'CRPD {{PART}}' ;;
      *) echo "usage: just flash-crpd dongle|left|right" >&2; exit 2 ;;
    esac

# Flash a settings-reset firmware. Split by SoC since the reset image is
# board-specific (nice!nano for zen/corne halves, XIAO BLE for the CRPD dongle).
# Usage: `just flash-reset nice-nano` / `just flash-reset xiao`.
flash-reset SOC: reset
    #!/usr/bin/env bash
    set -e
    case "{{SOC}}" in
      nice-nano) just _flash-uf2 build/reset/nice_nano_reset.uf2 'NICENANO*' 'nice!nano reset' ;;
      xiao)      just _flash-uf2 build/reset/xiao_reset.uf2      'XIAO-SENSE*' 'XIAO BLE reset' ;;
      *) echo "usage: just flash-reset nice-nano|xiao" >&2; exit 2 ;;
    esac
