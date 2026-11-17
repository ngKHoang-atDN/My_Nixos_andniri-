#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config-backup-$TIMESTAMP"

DOTFILES=(
  "colorschemes"
  "fastfetch"
  "fish"
  "hypr"
  "niri"
  "noctalia"
  "palettes"
  "rofi"
  "starship.toml"
  "swaync"
  "waybar"
)

INSTALL_DOTFILES=true
INSTALL_NIXOS=true
USE_COPY=false
DO_REBUILD=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Auto-install dotfiles and NixOS configuration from this repository.
Safe for migrating to a new machine (preserves target hardware-configuration.nix).

Options:
  --dotfiles-only   Only install dotfiles to $CONFIG_DIR
  --nixos-only      Only install NixOS config to /etc/nixos
  --copy            Copy dotfiles instead of creating symlinks
  --rebuild         Run 'sudo nixos-rebuild switch' after installing NixOS config
  -h, --help        Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dotfiles-only)
      INSTALL_NIXOS=false
      shift
      ;;
    --nixos-only)
      INSTALL_DOTFILES=false
      shift
      ;;
    --copy)
      USE_COPY=true
      shift
      ;;
    --rebuild)
      DO_REBUILD=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

log() {
  printf "\033[1;34m==>\033[0m %s\n" "$1"
}

warn() {
  printf "\033[1;33m[!]\033[0m %s\n" "$1"
}

install_dotfiles() {
  log "Installing dotfiles to $CONFIG_DIR (mode: $([[ "$USE_COPY" == true ]] && echo "copy" || echo "symlink"))"
  mkdir -p "$CONFIG_DIR"

  local backed_up=false
  for item in "${DOTFILES[@]}"; do
    local src="$REPO_DIR/$item"
    local dst="$CONFIG_DIR/$item"

    if [[ ! -e "$src" ]]; then
      warn "Skipping missing repo item: $src"
      continue
    fi

    # Skip if already symlinked to the right target
    if [[ "$USE_COPY" == false && -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
      echo "  [ok] $item (already linked)"
      continue
    fi

    # Backup existing file/directory/symlink
    if [[ -e "$dst" || -L "$dst" ]]; then
      if [[ "$backed_up" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        backed_up=true
      fi
      mv "$dst" "$BACKUP_DIR/"
      echo "  [backup] $dst -> $BACKUP_DIR/$item"
    fi

    if [[ "$USE_COPY" == true ]]; then
      cp -a "$src" "$dst"
      echo "  [copy] $item"
    else
      ln -s "$src" "$dst"
      echo "  [link] $dst -> $src"
    fi
  done

  if [[ "$backed_up" == true ]]; then
    log "Old dotfiles backed up to: $BACKUP_DIR"
  fi
}

install_nixos() {
  if [[ ! -d /etc/nixos ]]; then
    warn "/etc/nixos not found. Are you running on NixOS? Skipping NixOS config."
    return
  fi

  log "Installing NixOS config to /etc/nixos"

  # Preserve target machine's hardware-configuration.nix (critical for new hardware like ThinkPad P1 Gen 5)
  if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
    warn "/etc/nixos/hardware-configuration.nix not found. Generating one for this machine..."
    sudo nixos-generate-config
  else
    log "Keeping existing /etc/nixos/hardware-configuration.nix"
  fi

  local nix_backup="/etc/nixos/backup-$TIMESTAMP"
  sudo mkdir -p "$nix_backup"

  if [[ -f /etc/nixos/configuration.nix ]]; then
    sudo cp -a /etc/nixos/configuration.nix "$nix_backup/"
  fi
  if [[ -d /etc/nixos/npins ]]; then
    sudo cp -a /etc/nixos/npins "$nix_backup/"
  fi
  log "Backed up existing /etc/nixos files to $nix_backup"

  sudo cp -a "$REPO_DIR/configuration.nix" /etc/nixos/configuration.nix
  sudo rm -rf /etc/nixos/npins
  sudo cp -a "$REPO_DIR/npins" /etc/nixos/npins

  # Ensure unstable channel exists (required by `unstable = import <unstable> {};` in configuration.nix)
  if ! sudo nix-channel --list | grep -q '^unstable[[:space:]]'; then
    log "Adding 'unstable' nix-channel..."
    sudo nix-channel --add https://nixos.org/channels/nixos-unstable unstable
    sudo nix-channel --update unstable
  else
    echo "  [ok] 'unstable' nix-channel already configured"
  fi

  if [[ "$DO_REBUILD" == true ]]; then
    log "Running nixos-rebuild switch..."
    sudo nixos-rebuild switch
  else
    log "NixOS config copied. Run 'sudo nixos-rebuild switch' when ready to apply."
  fi
}

if [[ "$INSTALL_DOTFILES" == true ]]; then
  install_dotfiles
fi

if [[ "$INSTALL_NIXOS" == true ]]; then
  install_nixos
fi

log "Done!"
