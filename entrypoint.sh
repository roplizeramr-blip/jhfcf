#!/bin/bash
set -e

# Remove any stale lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Target user home directory
USER_HOME="${HOME:-/home/kasm_user}"

# Create required directories
mkdir -p "$USER_HOME/Desktop"
mkdir -p "$USER_HOME/.config/gtk-3.0"
mkdir -p "$USER_HOME/.config/tint2"
mkdir -p "$USER_HOME/.config/pcmanfm/default"
mkdir -p "$USER_HOME/.config/xfce4/terminal"
mkdir -p "$USER_HOME/.config/openbox"

# GTK 3 Theme (Greybird-dark + Papirus-Dark)
cat << 'EOF' > "$USER_HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name = Greybird-dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Noto Sans 10
gtk-application-prefer-dark-theme = true
EOF

# GTK 2 Theme
cat << 'EOF' > "$USER_HOME/.gtkrc-2.0"
gtk-theme-name="Greybird-dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 10"
EOF

# PCManFM Desktop background (Deep sleek dark charcoal)
cat << 'EOF' > "$USER_HOME/.config/pcmanfm/default/desktop-items-0.conf"
[*]
wallpaper_mode=color
desktop_bg=#1a1d24
desktop_fg=#ffffff
desktop_shadow=#000000
show_wm_menu=1
sort_type=0
sort_by=0
EOF

# Tint2 Modern Dark Taskbar
cat << 'EOF' > "$USER_HOME/.config/tint2/tint2rc"
# Backgrounds
rounded = 0
border_width = 0
background_color = #181b20 100
border_color = #282c34 100

rounded = 3
border_width = 1
background_color = #282c34 100
border_color = #3e4451 100

rounded = 3
border_width = 1
background_color = #3a3f4b 100
border_color = #61afef 100

# Panel
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 36
panel_margin = 0 0
panel_padding = 4 2 4
panel_background_id = 1
panel_dock = 0
panel_layer = normal
strut_policy = follow_size
panel_window_name = tint2
disable_transparency = 1

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 4 0 4
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 0
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_always_show_all_desktop_tasks = 1
taskbar_sort_order = none

# Tasks
task_icon = 1
task_text = 1
task_centered = 0
task_maximum_size = 180 30
task_padding = 6 3
task_background_id = 2
task_active_background_id = 3
task_urgent_background_id = 2
task_iconified_background_id = 2
task_font = Noto Sans 9
task_font_color = #abb2bf 100
task_active_font_color = #ffffff 100

# Clock
time1_format = %H:%M  |  %d %b %Y
time1_font = Noto Sans Bold 9
time1_font_color = #e0e0e0 100
clock_padding = 10 2
clock_background_id = 2

# Tooltip
tooltip_padding = 4 4
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.1
tooltip_font = Noto Sans 9
tooltip_font_color = #ffffff 100
tooltip_background_id = 2
EOF

# Terminal OneDark theme with Noto Sans Mono (Full Arabic BiDi & HarfBuzz)
cat << 'EOF' > "$USER_HOME/.config/xfce4/terminal/terminalrc"
[Configuration]
FontName=Noto Sans Mono 11
ColorBackground=#1e2227
ColorForeground=#abb2bf
ColorCursor=#528bff
ColorPalette=#1e2227;#e06c75;#98c379;#d19a66;#61afef;#c678dd;#56b6c2;#abb2bf;#5c6370;#e06c75;#98c379;#e5c07b;#61afef;#c678dd;#56b6c2;#ffffff
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscDefaultGeometry=95x26
MiscShowToolbar=FALSE
MiscShowMenubar=FALSE
MiscScrollbarDefault=TERMINAL_SCROLLBAR_RIGHT
TitleMode=TERMINAL_TITLE_PREPEND
EOF

# Language switcher script
cat << 'EOF' > "$USER_HOME/switch-lang.sh"
#!/bin/bash
current=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
if [[ "$current" == *"ar"* ]]; then
  setxkbmap -layout us,ar -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "Keyboard Layout" "Switched to English (US)" 2>/dev/null || true
else
  setxkbmap -layout ar,us -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "Keyboard Layout" "Switched to Arabic" 2>/dev/null || true
fi
EOF
chmod +x "$USER_HOME/switch-lang.sh" 2>/dev/null || true

# Desktop Shortcuts
cat << 'EOF' > "$USER_HOME/Desktop/Terminal.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal (الطرفية)
Comment=Modern Terminal with Arabic Support
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
StartupNotify=true
EOF

cat << 'EOF' > "$USER_HOME/Desktop/Files.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Files (مدير الملفات)
Comment=File Manager
Exec=pcmanfm
Icon=system-file-manager
Terminal=false
StartupNotify=true
EOF

cat << 'EOF' > "$USER_HOME/Desktop/TextEditor.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Text Editor (محرر النصوص)
Comment=Text Editor
Exec=mousepad
Icon=accessories-text-editor
Terminal=false
StartupNotify=true
EOF

cat << 'EOF' > "$USER_HOME/Desktop/SwitchLanguage.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Switch Language (US / Arabic)
Comment=Toggle between Arabic and English (US)
Exec=/home/kasm_user/switch-lang.sh
Icon=preferences-desktop-keyboard
Terminal=false
StartupNotify=false
EOF
chmod +x "$USER_HOME/Desktop/"*.desktop 2>/dev/null || true

# Aliases in .bashrc
cat << 'EOF' >> "$USER_HOME/.bashrc"
alias ar='setxkbmap -layout ar,us -option grp:alt_shift_toggle && echo "Language: Arabic"'
alias en='setxkbmap -layout us,ar -option grp:alt_shift_toggle && echo "Language: US English"'
alias us='setxkbmap -layout us,ar -option grp:alt_shift_toggle && echo "Language: US English"'
EOF

# Launch KasmVNC directly on port 3000
Xvnc :1 \
  -geometry 1280x720 \
  -depth 24 \
  -interface 0.0.0.0 \
  -websocketPort 3000 \
  -httpd /usr/share/kasmvnc/www \
  -sslOnly 0 \
  -SecurityTypes None \
  -disableBasicAuth &

# Wait for Xvnc display to initialize
sleep 2
export DISPLAY=:1

# Configure keyboard layout: US and Arabic with Alt+Shift toggle
setxkbmap -display :1 -layout us,ar -option grp:alt_shift_toggle 2>/dev/null || true

# Start desktop background and icons
pcmanfm --desktop &

# Start modern taskbar
tint2 &

# Open modern terminal with Arabic BiDi support
(sleep 1 && xfce4-terminal --geometry=95x26+80+50) &

# Run Openbox window manager as the persistent foreground session
exec openbox
