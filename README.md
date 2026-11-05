# Orbital - Pterodactyl v2 Theme

Amber-on-charcoal theme for **Pterodactyl v2 (2.0 beta+)**. No build step needed.

## Repo layout
```
install.sh        <- menu: 1 Install, 2 Uninstall, 3 Update
theme/
  theme.json      <- id, name, version (bump version on every update)
  tokens.css      <- all colours / radius / console colours
  assets/         <- images and fonts (published to /assets/theme/)
```

## Setup (once)
1. Upload this whole folder to a **public** GitHub repo.
2. Open `install.sh` and set `GH_USER`, `GH_REPO`, `GH_BRANCH` at the top.

## Install on the panel server (one command)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/install.sh)
```
Menu: **1** Install, **2** Uninstall, **3** Update. Default panel path is `/var/www/pterodactyl`
(override: `PANEL_DIR=/path bash install.sh`).

## Updating the theme
Edit `theme/tokens.css`, change `"version"` in `theme/theme.json`, push to GitHub,
then run the command again and pick **3**.

## Manual commands (what the script runs)
```bash
php artisan p:theme:list
php artisan p:theme:apply orbital
php artisan p:theme:reset
```
