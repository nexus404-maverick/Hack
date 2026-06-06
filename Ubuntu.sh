#!/data/data/com.termux/files/usr/bin/bash
# Lightweight Termux Linux Desktop (XFCE + VS Code + Firefox, không Wine, không hacking tools)

set -euo pipefail

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Biến
PROGRESS=0
TOTAL_STEPS=10

# Hàm hiển thị thanh tiến trình
update_progress() {
    PROGRESS=$((PROGRESS + 1))
    PERCENT=$((PROGRESS * 100 / TOTAL_STEPS))
    echo -e "${GREEN}[${PROGRESS}/${TOTAL_STEPS}]${NC} ${1} - ${PERCENT}%"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

install_pkg() {
    for pkg in "$@"; do
        echo -e "${BLUE}→ Cài đặt $pkg...${NC}"
        pkg install -y "$pkg" || { echo -e "${RED}Lỗi khi cài $pkg${NC}"; return 1; }
    done
}

# Bắt đầu
clear
echo -e "${GREEN}=== Termux Light Desktop (XFCE + VS Code + Firefox) ===${NC}"
echo -e "${YELLOW}Script sẽ cài đặt môi trường desktop nhẹ, không có Wine hay hacking tools.${NC}"
sleep 2

# Bước 0: Phát hiện GPU
update_progress "Phát hiện phần cứng đồ họa"
if grep -qi "Adreno" /system/build.prop 2>/dev/null; then
    GPU_DRIVER="turnip"
    echo -e "${GREEN}✓ Phát hiện GPU Adreno → dùng Turnip${NC}"
else
    GPU_DRIVER="software"
    echo -e "${YELLOW}⚠ Không phát hiện Adreno → dùng Software Rendering${NC}"
fi

# Bước 1: Cập nhật hệ thống
update_progress "Cập nhật Termux"
pkg update -y && pkg upgrade -y

# Bước 2: Thêm kho lưu trữ cần thiết
update_progress "Thêm kho x11-repo và tur-repo"
pkg install -y x11-repo tur-repo

# Bước 3: Cài Termux-X11 (phiên bản nightly)
update_progress "Cài Termux-X11"
install_pkg termux-x11-nightly

# Bước 4: Cài desktop XFCE4 + trình quản lý cửa sổ
update_progress "Cài XFCE4 (môi trường desktop)"
install_pkg xfce4 xfce4-terminal thunar mousepad

# Bước 5: Cài GPU acceleration
update_progress "Cài đặt tăng tốc đồ họa"
if [ "$GPU_DRIVER" == "turnip" ]; then
    install_pkg mesa-zink-turnip
else
    install_pkg mesa-software-rendering
fi

# Bước 6: Cài âm thanh PulseAudio
update_progress "Cài đặt âm thanh"
install_pkg pulseaudio

# Bước 7: Cài VS Code và Firefox
update_progress "Cài VS Code và Firefox"
install_pkg code-oss firefox

# Bước 8: Cài các gói cơ bản (git, wget, curl...)
update_progress "Cài các công cụ cơ bản"
install_pkg git wget curl htop neofetch

# Bước 9: Tạo script khởi chạy desktop
update_progress "Tạo script start-hacklab.sh và stop-hacklab.sh"
cat > ~/start-hacklab.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Khởi động Termux-X11 và XFCE4
pkill -f termux-x11 || true
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
xfce4-session &
echo "Desktop đã khởi động. Mở ứng dụng Termux-X11 để xem giao diện."
EOF
chmod +x ~/start-hacklab.sh

cat > ~/stop-hacklab.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f xfce4-session
pkill -f termux-x11
echo "Đã dừng desktop."
EOF
chmod +x ~/stop-hacklab.sh

# Bước 10: Tạo shortcut trên desktop cho VS Code và Firefox
update_progress "Tạo shortcut trên màn hình XFCE"
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/code.desktop << EOF
[Desktop Entry]
Name=VS Code
Comment=Code Editing
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

# Cấu hình GPU (nếu dùng turnip)
if [ "$GPU_DRIVER" == "turnip" ]; then
    mkdir -p ~/.config
    echo "export MESA_LOADER_DRIVER_OVERRIDE=zink" > ~/.config/hacklab-gpu.sh
    echo "export TU_DEBUG=noforbus" >> ~/.config/hacklab-gpu.sh
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cài đặt hoàn tất!${NC}"
echo -e "${YELLOW}Hướng dẫn sử dụng:${NC}"
echo "1. Chạy ~/start-hacklab.sh để khởi động desktop"
echo "2. Mở ứng dụng Termux-X11 (tải riêng từ F-Droid hoặc GitHub)"
echo "3. Trong desktop, bạn có thể đổi hình nền bằng chuột phải → Desktop Settings"
echo "4. VS Code và Firefox có sẵn trong menu hoặc shortcut trên màn hình"
echo "5. Để dừng: ~/stop-hacklab.sh"
echo -e "${GREEN}========================================${NC}"