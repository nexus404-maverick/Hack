#!/data/data/com.termux/files/usr/bin/bash
# Termux Lightweight Desktop (XFCE + VS Code + Firefox)
# Không Wine, không hacking tools, đã sửa lỗi gói mesa

set -euo pipefail

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Biến
PROGRESS=0
TOTAL_STEPS=9

# Hàm thanh tiến trình
update_progress() {
    PROGRESS=$((PROGRESS + 1))
    PERCENT=$((PROGRESS * 100 / TOTAL_STEPS))
    echo -e "${GREEN}[${PROGRESS}/${TOTAL_STEPS}]${NC} ${1} - ${PERCENT}%"
}

# Hàm cài gói an toàn
install_pkg() {
    for pkg in "$@"; do
        echo -e "${BLUE}→ Cài đặt $pkg...${NC}"
        pkg install -y "$pkg" || { echo -e "${RED}Lỗi khi cài $pkg${NC}"; return 1; }
    done
}

clear
echo -e "${GREEN}=== Cài đặt môi trường desktop nhẹ trên Termux ===${NC}"
echo -e "${YELLOW}Bao gồm: XFCE4 (cửa sổ nổi, đổi hình nền), VS Code, Firefox${NC}"
echo -e "${YELLOW}Không có Wine, không có công cụ hacking.${NC}"
sleep 2

# Bước 1: Cập nhật hệ thống
update_progress "Cập nhật Termux"
pkg update -y && pkg upgrade -y

# Bước 2: Thêm kho lưu trữ
update_progress "Thêm kho x11-repo và tur-repo"
pkg install -y x11-repo tur-repo

# Bước 3: Cài Termux-X11
update_progress "Cài Termux-X11 (máy chủ hiển thị)"
install_pkg termux-x11-nightly

# Bước 4: Cài XFCE4 (desktop)
update_progress "Cài XFCE4 và các ứng dụng cơ bản"
install_pkg xfce4 xfce4-terminal thunar mousepad

# Bước 5: Cài tăng tốc đồ họa (sửa lỗi gói không tồn tại)
update_progress "Cài đặt tăng tốc đồ họa (Mesa)"
# Kiểm tra GPU Adreno để dùng turnip (tối ưu hơn)
if grep -qi "Adreno" /system/build.prop 2>/dev/null; then
    echo -e "${GREEN}✓ Phát hiện GPU Adreno → cài driver turnip${NC}"
    install_pkg mesa-zink-turnip
else
    echo -e "${YELLOW}⚠ GPU không phải Adreno (hoặc không xác định) → cài Mesa chuẩn${NC}"
    # Gói mesa thông thường đã bao gồm software rendering (llvmpipe)
    install_pkg mesa
fi

# Bước 6: Cài âm thanh
update_progress "Cài đặt PulseAudio"
install_pkg pulseaudio

# Bước 7: Cài VS Code và Firefox
update_progress "Cài VS Code và Firefox"
install_pkg code-oss firefox

# Bước 8: Cài các công cụ cơ bản (không liên quan đến hacking)
update_progress "Cài các tiện ích cơ bản"
install_pkg git wget curl htop neofetch

# Bước 9: Tạo script khởi động và dừng desktop
update_progress "Tạo script start-desktop.sh và stop-desktop.sh"

cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Khởi động Termux-X11 và XFCE4
pkill -f termux-x11 2>/dev/null || true
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
xfce4-session &
echo "✓ Desktop đã khởi động."
echo "  Mở ứng dụng Termux-X11 để xem giao diện."
EOF
chmod +x ~/start-desktop.sh

cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f xfce4-session 2>/dev/null || true
pkill -f termux-x11 2>/dev/null || true
echo "✓ Đã dừng desktop."
EOF
chmod +x ~/stop-desktop.sh

# Tạo shortcut cho VS Code và Firefox trên màn hình XFCE
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/code.desktop << EOF
[Desktop Entry]
Name=VS Code
Comment=Code Editor
Exec=code-oss
Icon=code
Terminal=false
Type=Application
Categories=Development;
EOF

cat > ~/.local/share/applications/firefox.desktop << EOF
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Terminal=false
Type=Application
Categories=Network;
EOF

# Hoàn tất
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cài đặt hoàn tất thành công!${NC}"
echo -e "${YELLOW}Hướng dẫn sử dụng:${NC}"
echo "  1. Chạy: ~/start-desktop.sh"
echo "  2. Mở ứng dụng Termux-X11 (tải riêng từ F-Droid hoặc GitHub)"
echo "  3. Để đổi hình nền: chuột phải trên màn hình → Desktop Settings"
echo "  4. Để dừng: ~/stop-desktop.sh"
echo -e "${GREEN}========================================${NC}"
