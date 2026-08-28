#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  WALLPAPER PICKER — awww + rofi
# ─────────────────────────────────────────────────────────────

# Ensure user binaries are available (Hyprland keybinds don't source .bashrc)
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
exec &> /tmp/wallpaper-picker.log

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
ROFI_CONFIG="$HOME/.config/rofi/wallpaper.rasi"

mkdir -p "$CACHE_DIR"

# ── Verify dependencies ──────────────────────────────────────
for cmd in awww convert hyprctl rofi; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Wallpaper Picker" "Error: '$cmd' not found in PATH"
        exit 1
    fi
done

# ── Ensure awww daemon is running ────────────────────────────
if ! awww query &>/dev/null; then
    awww-daemon &>/dev/null &
    sleep 1
    if ! awww query &>/dev/null; then
        notify-send "Wallpaper Picker" "Error: awww-daemon failed to start"
        exit 1
    fi
fi

# ── Gather images ────────────────────────────────────────────
mapfile -t IMAGES < <(find "$WALLPAPER_DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.gif" -o -iname "*.webp" \
\) | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
  notify-send "Wallpaper Picker" "No images found in $WALLPAPER_DIR"
  exit 1
fi

# ── Generate thumbnails ─────────────────────────────────────
for IMG in "${IMAGES[@]}"; do
  HASH=$(echo "$IMG" | md5sum | cut -d' ' -f1)
  THUMB="$CACHE_DIR/$HASH.png"
  if [ ! -f "$THUMB" ]; then
    convert "$IMG" -thumbnail 500x281^ -gravity center -extent 500x281 "$THUMB"
  fi
done

# ── Build rofi input ────────────────────────────────────────
ROFI_INPUT=""
for IMG in "${IMAGES[@]}"; do
  HASH=$(echo "$IMG" | md5sum | cut -d' ' -f1)
  THUMB="$CACHE_DIR/$HASH.png"
  THEME=$(basename "$(dirname "$IMG")")
  NAME=$(basename "$IMG")
  ROFI_INPUT+="${THEME}/${NAME}\x00icon\x1f${THUMB}\n"
done

# ── Write rofi theme if missing ─────────────────────────────
mkdir -p "$HOME/.config/rofi"
if [ ! -f "$ROFI_CONFIG" ]; then
cat > "$ROFI_CONFIG" << 'ROFI'
* {
  bg:          rgba(26, 27, 38, 0.95);
  bg-alt:      rgba(41, 46, 66, 0.85);
  fg:          #c0caf5;
  accent:      #7aa2f7;
  border-col:  rgba(122, 162, 247, 0.3);
  font:        "Iosevka Nerd Font 12";
}

window {
  background-color: @bg;
  border:           2px;
  border-color:     @border-col;
  border-radius:    12px;
  width:            900px;
  height:           600px;
}

mainbox {
  background-color: transparent;
  children: [inputbar, listview];
  spacing: 8px;
  padding: 12px;
}

inputbar {
  background-color: @bg-alt;
  border-radius:    8px;
  padding:          8px 12px;
  border:           1px;
  border-color:     @border-col;
  children:         [prompt, entry];
}

prompt {
  background-color: transparent;
  text-color:       @accent;
  padding:          0 6px 0 0;
}

entry {
  background-color: transparent;
  text-color:       @fg;
  placeholder:      "Search wallpapers...";
  placeholder-color: rgba(192, 202, 245, 0.3);
}

listview {
  background-color: transparent;
  columns:          4;
  lines:            2;
  spacing:          8px;
  cycle:            true;
}

element {
  background-color: @bg-alt;
  border-radius:    8px;
  padding:          6px;
  border:           1px;
  border-color:     transparent;
  orientation:      vertical;
  cursor:           pointer;
}

element selected {
  background-color: rgba(122, 162, 247, 0.15);
  border-color:     @accent;
}

element-icon {
  size:             200px;
  border-radius:    6px;
}

element-text {
  background-color: transparent;
  text-color:       @fg;
  font:             "Iosevka Nerd Font 10";
  padding:          4px 2px 0 2px;
  horizontal-align: 0.5;
}
ROFI
fi

# ── Launch rofi ─────────────────────────────────────────────
SELECTED=$(printf '%b' "$ROFI_INPUT" | rofi \
  -dmenu \
  -theme "$ROFI_CONFIG" \
  -p "󰋩  Wallpapers" \
  -show-icons \
  -i \
  -format i)

# ── Apply wallpaper ─────────────────────────────────────────
if [ -n "$SELECTED" ]; then
  WALL="${IMAGES[$SELECTED]}"
  CURSOR_POS=$(hyprctl cursorpos | tr -d ' ')
  
  if awww img "$WALL" \
    --transition-type grow \
    --transition-pos "$CURSOR_POS" \
    --transition-duration 1.5 \
    --transition-fps 60; then
    
    echo "$WALL" > "$HOME/.cache/current_wallpaper"
    notify-send "Wallpaper" "$(basename "$WALL")" -i "$WALL" -t 2000
  else
    notify-send "Wallpaper Picker" "Failed to set wallpaper with awww"
    exit 1
  fi
fi
