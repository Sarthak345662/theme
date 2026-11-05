#!/usr/bin/env bash
# =====================================================================
#  Orbital Theme Manager - Pterodactyl v2 (extension based)
#  1) Install   2) Uninstall   3) Update
# =====================================================================

GH_USER="Sarthak345662"
GH_REPO="theme"
GH_BRANCH="main"

EXT_ID="orbital"
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
STAGE="/var/tmp/orbital-ext-stage"   # kept after install on purpose (panel may link to it)

R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'
ok()   { echo -e "${G}✔${N} $*"; }
info() { echo -e "${C}➜${N} $*"; }
warn() { echo -e "${Y}!${N} $*"; }
fail() { echo -e "${R}✘ $*${N}"; }

TMP=""
cleanup() { if [ -n "$TMP" ]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

need_root() { [ "$(id -u)" -eq 0 ] || { fail "Run as root (sudo bash install.sh)"; exit 1; }; }

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

ver_of() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1; }

check_v2() {
  local out rc
  out="$(art list --raw 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then
    fail "php artisan failed (exit $rc). Real error:"; echo "$out" | head -n 8
    return 1
  fi
  if ! echo "$out" | grep -q '^p:extension:install'; then
    fail "This panel has no extension system (p:extension:install missing) - not Pterodactyl v2."
    return 1
  fi
}

is_installed() { art p:extension:list 2>/dev/null | grep -qiw "$EXT_ID"; }

installed_ver() {
  local f="$PANEL_DIR/extensions/$EXT_ID/extension.json"
  if [ -f "$f" ]; then ver_of "$f"; else echo "?"; fi
}

# Put extension files into $SRC. $1 = auto | remote
get_source() {
  local mode="${1:-auto}"
  if [ "$mode" = "auto" ] && [ -f "$SCRIPT_DIR/extension/extension.json" ]; then
    SRC="$SCRIPT_DIR/extension"; info "Using local extension files"; return 0
  fi
  command -v curl >/dev/null && command -v tar >/dev/null || { fail "curl and tar are required"; return 1; }
  TMP="$(mktemp -d)"
  info "Downloading github.com/$GH_USER/$GH_REPO ($GH_BRANCH)"
  if ! curl -fsSL "https://github.com/$GH_USER/$GH_REPO/archive/refs/heads/$GH_BRANCH.tar.gz" | tar -xz -C "$TMP" --strip-components=1; then
    fail "Download failed. Check repo name/branch and that the repo is public."; return 1
  fi
  SRC="$TMP/extension"
  [ -f "$SRC/extension.json" ] && [ -f "$SRC/dist/client.js" ] || { fail "extension/extension.json or extension/dist/client.js missing in repo"; return 1; }
}

# Copy to a path the web user can read
stage_source() {
  rm -rf "$STAGE"; mkdir -p "$STAGE"
  cp -r "$SRC/." "$STAGE/"
  chown -R "$WEB_USER:$WEB_GROUP" "$STAGE"; chmod -R a+rX "$STAGE"
}

remove_existing() {
  art p:extension:disable "$EXT_ID" >/dev/null 2>&1 || true
  art p:extension:remove "$EXT_ID" 2>&1 | tail -n 3 || true
}

install_from_stage() {
  local out rc a
  info "Checking package (p:extension:doctor)"
  out="$(art p:extension:doctor "$STAGE" 2>&1)"; rc=$?
  echo "$out" | tail -n 15
  if [ $rc -ne 0 ]; then
    fail "doctor reported problems."
    read -rp "Continue anyway? [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]] || return 1
  fi
  info "Installing and enabling Orbital"
  out="$(art p:extension:install "$STAGE" --enable 2>&1)"; rc=$?
  echo "$out"
  if [ $rc -ne 0 ]; then fail "p:extension:install failed (see output above)."; return 1; fi
  art optimize:clear >/dev/null 2>&1 || true
}

do_install() {
  check_v2 || return 1
  get_source auto || return 1
  if is_installed; then
    warn "Orbital is already installed (v$(installed_ver))."
    read -rp "Reinstall? [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]] || return 0
    remove_existing
  fi
  stage_source
  install_from_stage || return 1
  ok "Orbital v$(ver_of "$SRC/extension.json") installed. Hard-refresh the panel (Ctrl+Shift+R)."
}

do_uninstall() {
  check_v2 || return 1
  if ! is_installed; then warn "Orbital is not installed."; return 0; fi
  read -rp "Remove Orbital and restore the stock look? [y/N]: " a
  [[ "$a" =~ ^[Yy]$ ]] || return 0
  art p:extension:disable "$EXT_ID" 2>&1 | tail -n 3
  art p:extension:remove "$EXT_ID" 2>&1 | tail -n 3
  rm -rf "$STAGE"
  art optimize:clear >/dev/null 2>&1 || true
  ok "Orbital removed."
}

do_update() {
  check_v2 || return 1
  if ! is_installed; then warn "Orbital is not installed. Use Install first."; return 0; fi
  local cur new
  cur="$(installed_ver)"
  get_source remote || return 1
  new="$(ver_of "$SRC/extension.json")"
  info "Installed: v$cur   Latest: v$new"
  if [ "$cur" = "$new" ]; then
    read -rp "Already on latest. Reinstall anyway? [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]] || return 0
  fi
  remove_existing
  stage_source
  install_from_stage || return 1
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
  if is_installed; then
    echo -e "   Status: ${G}installed (v$(installed_ver))${N}"
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
