#!/bin/bash
set -e

# Remove any stale lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Create config directories
mkdir -p /home/kasm_user/Desktop
mkdir -p /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/kasm_user/.config/xfce4/terminal

# Write XFCE config files
cat << 'EOF' > /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Noto Sans Mono 10"/>
  </property>
</channel>
EOF

cat << 'EOF' > /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Greybird-dark"/>
    <property name="title_font" type="string" value="Noto Sans Bold 9"/>
  </property>
</channel>
EOF

cat << 'EOF' > /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="keyboard-layout" version="1.0">
  <property name="Default" type="empty">
    <property name="XkbDisable" type="bool" value="false"/>
    <property name="XkbLayout" type="string" value="us,ar"/>
    <property name="XkbVariant" type="string" value=","/>
    <property name="XkbOptions" type="empty">
      <property name="Group" type="string" value="grp:alt_shift_toggle"/>
    </property>
  </property>
</channel>
EOF

cat << 'EOF' > /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0.14"/>
            <value type="double" value="0.16"/>
            <value type="double" value="0.20"/>
            <value type="double" value="1.0"/>
          </property>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

cat << 'EOF' > /home/kasm_user/.config/xfce4/terminal/terminalrc
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

# Create desktop language switcher script
cat << 'EOF' > /home/kasm_user/switch-lang.sh
#!/bin/bash
current=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
if [[ "$current" == *"ar"* ]]; then
  setxkbmap -layout us,ar -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "Keyboard Layout" "Switched to English (US)" 2>/dev/null || true
else
  setxkbmap -layout ar,us -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "لوحة المفاتيح" "تم التبديل إلى العربية" 2>/dev/null || true
fi
EOF
chmod +x /home/kasm_user/switch-lang.sh 2>/dev/null || true

cat << 'EOF' > /home/kasm_user/Desktop/switch-language.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=تبديل اللغة / Switch Language
Comment=Toggle between Arabic and English (US)
Exec=/home/kasm_user/switch-lang.sh
Icon=preferences-desktop-keyboard
Terminal=false
StartupNotify=false
EOF
chmod +x /home/kasm_user/Desktop/switch-language.desktop 2>/dev/null || true

# Add convenient aliases in .bashrc
cat << 'EOF' >> /home/kasm_user/.bashrc
alias ar='setxkbmap -layout ar,us -option grp:alt_shift_toggle && echo "لوحة المفاتيح: عربي (Arabic)"'
alias en='setxkbmap -layout us,ar -option grp:alt_shift_toggle && echo "Keyboard: US English"'
alias us='setxkbmap -layout us,ar -option grp:alt_shift_toggle && echo "Keyboard: US English"'
EOF

# Start KasmVNC directly in background
Xvnc :1 \
  -geometry 1280x720 \
  -depth 24 \
  -interface 0.0.0.0 \
  -websocketPort 3000 \
  -httpd /usr/share/kasmvnc/www \
  -sslOnly 0 \
  -SecurityTypes None \
  -disableBasicAuth &

XVNC_PID=$!

# Wait for Xvnc display to become available
sleep 2
export DISPLAY=:1

# Initialize D-Bus session
eval $(dbus-launch --sh-syntax 2>/dev/null || true)
export DBUS_SESSION_BUS_ADDRESS

# Configure keyboard layouts
setxkbmap -display :1 -layout us,ar -option grp:alt_shift_toggle 2>/dev/null || true

# Launch XFCE desktop components
xfsettingsd --replace &
xfwm4 &
xfce4-panel &
xfdesktop &

# Launch modern terminal
(sleep 2 && xfce4-terminal --geometry=95x26+120+80) &

# Keep container alive by waiting for Xvnc
wait $XVNC_PID
