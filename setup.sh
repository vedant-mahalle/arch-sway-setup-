#!/bin/bash

# ============================================================
# Sway setup script for Arch Linux
# Installs sway + all dependencies + 201dreamers/sway-config
# Run as your normal user (NOT root)
# ============================================================

set -e  # exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
die()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

# ── Sanity checks ────────────────────────────────────────────

if [ "$EUID" -eq 0 ]; then
  die "Do not run this as root. Run as your normal user with sudo access."
fi

if ! command -v pacman &>/dev/null; then
  die "This script is for Arch Linux only."
fi

log "Starting Sway environment setup..."

# ── System update ────────────────────────────────────────────

log "Updating system..."
sudo pacman -Syu --noconfirm

# ── Core packages ────────────────────────────────────────────

log "Installing core packages..."
sudo pacman -S --noconfirm --needed \
  sway \
  waybar \
  wofi \
  foot \
  mako \
  swaylock \
  swayidle \
  grim \
  slurp \
  wl-clipboard \
  jq \
  imagemagick \
  pulseaudio \
  pulseaudio-alsa \
  playerctl \
  earlyoom \
  iwd \
  git \
  base-devel \
  xdg-user-dirs \
  polkit \
  dbus \
  pipewire \
  pipewire-pulse \
  wireplumber

# ── Directories ──────────────────────────────────────────────

log "Creating required directories..."
mkdir -p ~/Pictures/screenshots
xdg-user-dirs-update

# ── yay (AUR helper) ─────────────────────────────────────────

if ! command -v yay &>/dev/null; then
  log "Installing yay..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
else
  warn "yay already installed, skipping."
fi

# ── Clone sway config ────────────────────────────────────────

log "Cloning sway config..."
TMPDIR=$(mktemp -d)
git clone https://github.com/201dreamers/sway-config.git "$TMPDIR/sway-config"

log "Copying config files to ~/.config/..."
mkdir -p ~/.config
cp -r "$TMPDIR/sway-config/.config/"* ~/.config/
rm -rf "$TMPDIR"

# ── Enable services ──────────────────────────────────────────

log "Enabling user services..."
systemctl --user enable --now mako || warn "mako service not available yet, start manually after login."

log "Enabling earlyoom..."
sudo systemctl enable --now earlyoom || warn "earlyoom failed, continue anyway."

# ── Done ─────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  To start sway, log in and type:  sway"
echo ""
warn "If sway fails to start, check: journalctl --user -xe"
warn "Make sure you are on a TTY (not inside another compositor)"
echo ""
