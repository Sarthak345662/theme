#!/usr/bin/env bash
# =====================================================================
#  Orbital Theme Manager - Pterodactyl v2
#  1) Install   2) Uninstall   3) Update
# =====================================================================

# ---- EDIT THESE 3 LINES AFTER UPLOADING TO GITHUB -------------------
GH_USER="YOUR_GITHUB_USERNAME"
GH_REPO="YOUR_REPO_NAME"
GH_BRANCH="main"
# ---------------------------------------------------------------------

THEME_ID="orbital"
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"

R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'
ok()   { echo -e "${G}✔${N} $*"; }
info() { echo -e "${C}➜${N} $*"; }
warn() { echo -e "${Y}!${N} $*"; }
fail() { echo -e "${R}✘ $*${N}"; }

TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    fail "Run this as root (sudo bash install.sh)"; exit 1
  fi
}

find_panel() {
  if [ ! -f "$PANEL_DIR/artisan" ]; then
    warn "Panel not found at $PANEL_DIR"
    read -rp "Enter your panel path: " PANEL_DIR
    [ -f "$PANEL_DIR/artisan" ] || { fail "artisan not found in $PANEL_DIR"; exit 1; }
  fi
  WEB_USER="$(stat -c '%U' "$PANEL_DIR/artisan")"
  WEB_GROUP="$(stat -c '%G' "$PANEL_DIR/artisan")"
}

art() {
  ( cd "$PANEL_DIR" && if command -v runuser >/dev/null 2>&1 && [ "$WEB_USER" != "root" ]; then
      runuser -u "$WEB_USER" -- php artisan "$@"
    else php artisan "$@"; fi )
}

check_v2() {
  if ! art list --raw 2>/dev/null | grep -q '^p:theme:apply'; then
    fail "This panel does not support v2 themes (p:theme:apply missing)."
    fail "Orbital needs Pterodactyl v2 (2.0.0-beta or newer)."
    return 1
  fi
}

# Get theme files into $SRC. $1 = auto | remote
get_source() {
  local mode="${1:-auto}"
  if [ "$mode" = "auto" ] && [ -f "$SCRIPT_DIR/theme/theme.json" ]; then
    SRC="$SCRIPT_DIR/theme"; info "Using local theme files"; return 0
  fi
  if [[ "$GH_USER" == YOUR_* ]]; then
    fail "Set GH_USER / GH_REPO at the top of install.sh first."; return 1
  fi
  command -v curl >/dev/null && command -v tar >/dev/null || { fail "curl and tar are required"; return 1; }
  TMP="$(mktemp -d)"
  info "Downloading from github.com/$GH_USER/$GH_REPO ($GH_BRANCH)"
  if ! curl -fsSL "https://github.com/$GH_USER/$GH_REPO/archive/refs/heads/$GH_BRANCH.tar.gz" | tar -xz -C "$TMP" --strip-components=1; then
    fail "Download failed. Check the repo name, branch and that it is public."; return 1
  fi
  SRC="$TMP/theme"
  [ -f "$SRC/theme.json" ] && [ -f "$SRC/tokens.css" ] || { fail "theme/theme.json or theme/tokens.css missing in repo"; return 1; }
}

ver_of() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1; }

deploy() {
  mkdir -p "$PANEL_DIR/themes"
  rm -rf "$PANEL_DIR/themes/$THEME_ID"
  cp -r "$SRC" "$PANEL_DIR/themes/$THEME_ID"
  chown -R "$WEB_USER:$WEB_GROUP" "$PANEL_DIR/themes/$THEME_ID"
  art p:theme:apply "$THEME_ID" || { fail "p:theme:apply failed"; return 1; }
  art optimize:clear >/dev/null 2>&1 || true
}

do_install() {
  check_v2 || return 1
  if [ -d "$PANEL_DIR/themes/$THEME_ID" ]; then
    warn "Orbital is already installed (v$(ver_of "$PANEL_DIR/themes/$THEME_ID/theme.json")). Use Update instead, or continue to reinstall."
    read -rp "Reinstall? [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]] || return 0
  fi
  get_source auto || return 1
  deploy || return 1
  ok "Orbital v$(ver_of "$SRC/theme.json") installed. Hard-refresh the panel (Ctrl+Shift+R)."
}

do_uninstall() {
  check_v2 || return 1
  if [ ! -d "$PANEL_DIR/themes/$THEME_ID" ]; then warn "Orbital is not installed."; return 0; fi
  read -rp "Remove Orbital and restore the default look? [y/N]: " a
  [[ "$a" =~ ^[Yy]$ ]] || return 0
  art p:theme:reset || warn "p:theme:reset reported an error"
  rm -rf "$PANEL_DIR/themes/$THEME_ID"
  art optimize:clear >/dev/null 2>&1 || true
  ok "Orbital removed. Default theme restored."
}

do_update() {
  check_v2 || return 1
  if [ ! -d "$PANEL_DIR/themes/$THEME_ID" ]; then warn "Orbital is not installed. Use Install first."; return 0; fi
  local cur new
  cur="$(ver_of "$PANEL_DIR/themes/$THEME_ID/theme.json")"
  get_source remote || return 1
  new="$(ver_of "$SRC/theme.json")"
  info "Installed: v$cur   Latest: v$new"
  if [ "$cur" = "$new" ]; then
    read -rp "Already on latest. Reinstall anyway? [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]] || return 0
  fi
  deploy || return 1
  ok "Updated to v$new. Hard-refresh the panel (Ctrl+Shift+R)."
}

banner() {
  clear
  echo -e "${Y}${B}"
  echo "   ___  ____  ____ ___ _____  _    _     "
  echo "  / _ \\|  _ \\| __ )_ _|_   _|/ \\  | |    "
  echo " | | | | |_) |  _ \\| |  | | / _ \\ | |    "
  echo " | |_| |  _ <| |_) | |  | |/ ___ \\| |___ "
  echo "  \\___/|_| \\_\\____/___| |_/_/   \\_\\_____|"
  echo -e "${N}${C}   Pterodactyl v2 Theme Manager${N}"
  echo "   Panel: $PANEL_DIR"
  if [ -d "$PANEL_DIR/themes/$THEME_ID" ]; then
    echo -e "   Status: ${G}installed v$(ver_of "$PANEL_DIR/themes/$THEME_ID/theme.json")${N}"
  else
    echo -e "   Status: ${R}not installed${N}"
  fi
  echo
}

need_root
find_panel
while true; do
  banner
  echo "   1) Install the theme"
  echo "   2) Uninstall the theme"
  echo "   3) Update the theme"
  echo "   0) Exit"
  echo
  read -rp "   Choose [0-3]: " ch
  echo
  case "$ch" in
    1) do_install ;;
    2) do_uninstall ;;
    3) do_update ;;
    0) echo "Bye!"; exit 0 ;;
    *) warn "Invalid choice" ;;
  esac
  echo; read -rp "Press Enter to continue..." _
done
