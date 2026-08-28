#!/bin/bash

# 1. Define the Funnel Path
DIR="/home/s1/Pictures/Screenshots/"

# 2. Ensure the directory exists
mkdir -p "$DIR"

# 3. Define the filename with a timestamp
FILE="$DIR/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

# 4. Take the screenshot:
# 'slurp' lets you select the area
# 'grim' captures it to the file
# 'wl-copy' puts it in your clipboard immediately
grim -g "$(slurp)" "$FILE" && wl-copy < "$FILE"

# 5. Visual confirmation (Optional)
notify-send "Screenshot Captured" "Saved to $DIR" -i camera-photo
