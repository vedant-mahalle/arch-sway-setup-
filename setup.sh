#!/bin/bash

# ============================================================
# Sway setup script for Arch Linux
# Installs sway + all dependencies + 201dreamers/sway-config
# Run as your normal user (NOT root)
# ============================================================

# Do NOT use set -e globally; we handle errors manually
# so services failing mid-install don't kill the whole script

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
sudo pacman -Syu --noconfirm || die "System update failed."

# ── Remove pulseaudio if installed (conflicts with pipewire-pulse) ──

if pacman -Qq pulseaudio &>/dev/null; then
  warn "pulseaudio detected, removing to avoid conflict with pipewire..."
  sudo pacman -Rns --noconfirm pulseaudio pulseaudio-alsa 2>/dev/null || true
fi

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
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  wireplumber \
  playerctl \
  earlyoom \
  iwd \
  git \
  go \
  base-devel \
  xdg-user-dirs \
  polkit \
  dbus \
  notification-daemon || die "Package installation failed."

# ── Directories ──────────────────────────────────────────────

log "Creating required directories..."
mkdir -p ~/Pictures/screenshots
mkdir -p ~/.config
xdg-user-dirs-update

# ── yay (AUR helper) ─────────────────────────────────────────

if ! command -v yay &>/dev/null; then
  log "Installing yay..."
  # Use home dir not /tmp to avoid noexec mount issues
  BUILD_DIR="$HOME/.builds"
  mkdir -p "$BUILD_DIR"
  git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay" || die "Failed to clone yay."
  cd "$BUILD_DIR/yay"
  makepkg -si --noconfirm || die "yay build failed."
  cd ~
else
  warn "yay already installed, skipping."
fi

# ── Clone sway config ────────────────────────────────────────

log "Cloning sway config..."
CLONE_DIR="$HOME/.builds/sway-config"

# Backup existing sway config if present
if [ -d "$HOME/.config/sway" ]; then
  BACKUP="$HOME/.config/sway.bak.$(date +%s)"
  warn "Existing sway config found, backing up to $BACKUP"
  mv "$HOME/.config/sway" "$BACKUP"
fi

git clone https://github.com/201dreamers/sway-config.git "$CLONE_DIR" || die "Failed to clone sway-config."

log "Copying config files to ~/.config/..."
cp -r "$CLONE_DIR/.config/"* ~/.config/

# ── Enable system services ───────────────────────────────────

log "Enabling earlyoom..."
sudo systemctl enable --now earlyoom || warn "earlyoom failed to start, non-critical."

# ── Enable user services (best effort, needs user session) ───

log "Attempting to enable user services..."
systemctl --user enable mako 2>/dev/null || warn "mako user service not enabled now, will auto-start with sway."
systemctl --user enable wireplumber 2>/dev/null || warn "wireplumber will start with pipewire on login."

# ── Done ─────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Reboot first:        sudo reboot"
echo "  Then start sway:     sway"
echo ""
warn "If sway fails: journalctl --user -xe"
warn "Run from TTY, not inside another compositor"
echo ""
