# Orbital - Pterodactyl v2 theme

Amber-on-charcoal theme for Pterodactyl v2 (extension based, no Node needed).

## Repo layout (upload all of this to github.com/Sarthak345662/theme, branch main)
```
install.sh                 menu: 1 Install, 2 Uninstall, 3 Update
build.sh                   rebuilds extension/dist/client.js from src/theme.css
src/theme.css              <- edit colours here
extension/extension.json   id, name, version  (bump version on every update)
extension/dist/client.js   generated
```

## Install on the panel server
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Sarthak345662/theme/main/install.sh)
```

## Update workflow
1. Edit `src/theme.css`
2. `bash build.sh`
3. Bump `"version"` in `extension/extension.json`
4. Push to GitHub, then run the command above and choose **3**

## Manual commands (what the menu runs)
```bash
php artisan p:extension:install /path/to/extension --enable
php artisan p:extension:disable orbital
php artisan p:extension:remove orbital
```
Disable or remove Orbital to get the stock look back.
