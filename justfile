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

# Build both topologies
all: wireless dongle

# Remove build symlinks
clean:
    rm -rf build result result-*

# Flash the default firmware to a connected bootloader
flash:
    nix run .#flash
