#!/usr/bin/env bash
# Restores last used wallpaper on Hyprland login

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
exec &> /tmp/restore-wallpaper.log

THEMES_DIR="$HOME/.config/themes"
CURRENT_THEME_FILE="$HOME/.config/current-theme"
LAST_WALL_FILE="$HOME/.cache/current_wallpaper"

# Verify awww is available
if ! command -v awww &>/dev/null; then
    echo "Error: awww not found in PATH"
    exit 1
fi

# Wait for awww-daemon (launched via exec-once in hyprland.conf)
sleep 1

# Ensure the daemon is actually up
if ! awww query &>/dev/null; then
    awww-daemon &
    sleep 1
    if ! awww query &>/dev/null; then
        echo "Error: awww-daemon failed to start"
        exit 1
    fi
fi

# ── 1. Try the saved wallpaper path first ─────────────────────
if [ -f "$LAST_WALL_FILE" ]; then
    WALL=$(cat "$LAST_WALL_FILE")
    if [ -f "$WALL" ]; then
        awww img "$WALL" --transition-type fade --transition-duration 1.5
        echo "Restored last wallpaper: $WALL"
        exit 0
    fi
fi

# ── 2. Fallback: pick from the current theme's wallpaper folder ─
if [ -f "$CURRENT_THEME_FILE" ]; then
    THEME=$(cat "$CURRENT_THEME_FILE")
    WALLPAPER_PATH=$(eval echo "$(cat "$THEMES_DIR/$THEME/wallpaper-path.txt" 2>/dev/null)")
    if [ -d "$WALLPAPER_PATH" ]; then
        WALL=$(find "$WALLPAPER_PATH" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
        if [ -n "$WALL" ]; then
            awww img "$WALL" --transition-type fade --transition-duration 1.5
            echo "$WALL" > "$LAST_WALL_FILE"
            echo "Restored theme wallpaper: $WALL"
            exit 0
        fi
    fi
fi

# ── 3. Last resort: any wallpaper in ~/Pictures/Wallpapers ─────
WALL=$(find "$HOME/Pictures/Wallpapers" -type f \( \
    -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \
\) | head -n 1)
if [ -n "$WALL" ]; then
    awww img "$WALL" --transition-type fade --transition-duration 1.5
    echo "Restored fallback wallpaper: $WALL"
else
    echo "Error: No wallpapers found anywhere"
fi
