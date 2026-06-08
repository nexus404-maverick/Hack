#!/data/data/com.termux/files/usr/bin/bash
# Termux Lightweight Desktop (XFCE minimal + VS Code + Midori + Audio)
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROGRESS=0
TOTAL_STEPS=8

update_progress() {
    PROGRESS=$((PROGRESS + 1))
    PERCENT=$((PROGRESS * 100 / TOTAL_STEPS))
    echo -e "${GREEN}[${PROGRESS}/${TOTAL_STEPS}]${NC} ${1} - ${PERCENT}%"
}

install_pkg() {
    for pkg in "$@"; do
        echo -e "${BLUE}→ Cài $pkg...${NC}"
        pkg install -y "$pkg" || { echo -e "${RED}Lỗi cài $pkg${NC}"; return 1; }
    done
}

clear
echo -e "${GREEN}=== Cài desktop tối giản (XFCE + VS Code + Midori + Âm thanh) ===${NC}"
sleep 1

update_progress "Cập nhật Termux"
pkg update -y && pkg upgrade -y

update_progress "Thêm x11-repo và tur-repo"
pkg install -y x11-repo tur-repo

update_progress "Cài Termux-X11"
install_pkg termux-x11-nightly

update_progress "Cài XFCE core (cửa sổ nổi, đổi nền) + thunar + xterm"
install_pkg xfce4-session xfwm4 xfdesktop xfce4-panel thunar xterm

update_progress "Cài tăng tốc đồ họa (Mesa)"
if grep -qi "Adreno" /system/build.prop 2>/dev/null; then
    echo -e "${GREEN}✓ GPU Adreno → dùng turnip${NC}"
    install_pkg mesa-zink-turnip
else
    install_pkg mesa
fi

update_progress "Cài PulseAudio (âm thanh) và VS Code + Midori"
# Bổ sung gói pulseaudio và virgl (có thể cần cho tăng tốc âm thanh/đồ họa)
install_pkg pulseaudio virglrenderer-android code-oss midori

update_progress "Tạo script khởi động/dừng"
cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# 1. Dọn dẹp các file lock cũ để tránh lỗi "Display already in use"
rm -rf /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null || true

# 2. Khởi động máy chủ âm thanh PulseAudio (cho phép kết nối TCP)
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
# 3. Khởi động máy chủ ảo hóa để tăng tốc đồ họa
virgl_test_server_android &

# 4. Khởi động máy chủ hiển thị Termux-X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

# 5. Khởi động môi trường desktop XFCE
xfce4-session &
echo "✓ Desktop đã khởi động. (Âm thanh đã được kích hoạt)"
echo "  Mở ứng dụng Termux-X11 để xem giao diện."
EOF
chmod +x ~/start-desktop.sh

cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f xfce4-session 2>/dev/null || true
pkill -f termux-x11 2>/dev/null || true
pkill -f pulseaudio 2>/dev/null || true
pkill -f virgl_test_server 2>/dev/null || true
echo "✓ Đã dừng desktop và các dịch vụ âm thanh."
EOF
chmod +x ~/stop-desktop.sh

# Tạo shortcut cho VS Code và Midori (hiển thị trong menu XFCE)
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/code.desktop << EOF
[Desktop Entry]
Name=VS Code
Exec=code-oss
Icon=code
Terminal=false
Type=Application
Categories=Development;
EOF

cat > ~/.local/share/applications/midori.desktop << EOF
[Desktop Entry]
Name=Midori
Exec=midori
Icon=midori
Terminal=false
Type=Application
Categories=Network;
EOF

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cài đặt hoàn tất!${NC}"
echo -e "${YELLOW}Hướng dẫn:${NC}"
echo "  ~/start-desktop.sh → khởi động (có âm thanh)"
echo "  Mở Termux-X11 app → thấy màn hình nền"
echo "  Chuột phải → Desktop Settings → đổi hình nền"
echo "  ~/stop-desktop.sh → tắt (tắt cả âm thanh)"
echo -e "${GREEN}========================================${NC}"