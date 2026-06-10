#!/data/data/com.termux/files/usr/bin/bash
# Termux Lightweight Desktop (XFCE + VS Code + Firefox + VNC Server)
# Hỗ trợ remote qua VNC, tối ưu cho TV RAM thấp

set -euo pipefail

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Biến
PROGRESS=0
TOTAL_STEPS=11

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
echo -e "${YELLOW}Hỗ trợ VNC Server để truy cập từ TV Android trong cùng mạng LAN${NC}"
echo -e "${YELLOW}Không có Wine, không có công cụ hacking.${NC}"
sleep 2

# Bước 1: Cập nhật hệ thống
update_progress "Cập nhật Termux"
pkg update -y && pkg upgrade -y

# Bước 2: Thêm kho lưu trữ
update_progress "Thêm kho x11-repo và tur-repo"
pkg install -y x11-repo tur-repo

# Bước 3: Cài Termux-X11 (cho hiển thị local, không bắt buộc với VNC)
update_progress "Cài Termux-X11 (máy chủ hiển thị local)"
install_pkg termux-x11-nightly

# Bước 4: Cài XFCE4 và các ứng dụng cơ bản
update_progress "Cài XFCE4 và các ứng dụng cơ bản"
install_pkg xfce4 xfce4-terminal thunar mousepad

# Bước 5: Cài tăng tốc đồ họa
update_progress "Cài đặt tăng tốc đồ họa (Mesa)"
if grep -qi "Adreno" /system/build.prop 2>/dev/null; then
    echo -e "${GREEN}✓ Phát hiện GPU Adreno → cài driver turnip${NC}"
    install_pkg mesa-zink-turnip
else
    echo -e "${YELLOW}⚠ GPU không phải Adreno → cài Mesa chuẩn${NC}"
    install_pkg mesa
fi

# Bước 6: Cài âm thanh
update_progress "Cài đặt PulseAudio"
install_pkg pulseaudio

# Bước 7: Cài VS Code và Firefox
update_progress "Cài VS Code và Firefox"
install_pkg code-oss firefox

# Bước 8: Cài các công cụ cơ bản
update_progress "Cài các tiện ích cơ bản"
install_pkg git wget curl htop neofetch

# Bước 9: Cài TigerVNC (cho remote)
update_progress "Cài TigerVNC Server"
install_pkg tigervnc

# Bước 10: Tạo script khởi động local và remote + tối ưu XFCE
update_progress "Tạo script start-desktop.sh, start-remote.sh, stop-remote.sh và tối ưu hiệu năng"

# Script start local (Termux-X11)
cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Khởi động Termux-X11 và XFCE4 (hiển thị local)
pkill -f termux-x11 2>/dev/null || true
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
xfce4-session &
echo "✓ Desktop local đã khởi động (Termux-X11)."
echo "  Mở ứng dụng Termux-X11 để xem giao diện."
EOF
chmod +x ~/start-desktop.sh

# Script dừng local (giữ nguyên từ gốc)
cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f xfce4-session 2>/dev/null || true
pkill -f termux-x11 2>/dev/null || true
echo "✓ Đã dừng desktop local."
EOF
chmod +x ~/stop-desktop.sh

# Script khởi động VNC server (remote)
cat > ~/start-remote.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Khởi động VNC server với display :1, độ phân giải 1280x720, màu 16-bit
# Tự động lấy IP LAN và hiển thị địa chỉ truy cập

# Dừng VNC server nếu đang chạy
vncserver -kill :1 2>/dev/null || true

# Xóa mật khẩu cũ nếu chưa có, tạo mới
if [ ! -f ~/.vnc/passwd ]; then
    echo -e "\n=== LẦN ĐẦU CHẠY VNC ==="
    echo "Bạn cần đặt mật khẩu để truy cập từ xa (tối đa 8 ký tự)."
    echo "Nhập mật khẩu:"
    vncpasswd
fi

# Khởi động VNC server với thông số tối ưu
vncserver :1 -geometry 1280x720 -depth 16 -pixelformat rgb565 -localhost no -Xvnc-args "-MaxDisconnectionTime 0"

# Lấy địa chỉ IP LAN
IP_LAN=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$IP_LAN" ]; then
    IP_LAN="192.168.1.x (không xác định được, hãy tự kiểm tra)"
fi

echo "========================================="
echo -e "${GREEN}✓ VNC Server đang chạy trên display :1${NC}"
echo -e "${YELLOW}→ Địa chỉ truy cập từ TV hoặc máy tính khác: ${IP_LAN}:5901${NC}"
echo "  (cổng 5901 tương ứng display :1)"
echo "  Độ phân giải: 1280x720, màu 16-bit (tối ưu độ trễ)"
echo "  Hãy dùng ứng dụng VNC Viewer (RealVNC, bVNC, ...) để kết nối."
echo "  Mật khẩu: (bạn đã đặt ở bước trên)"
echo "========================================="
EOF
chmod +x ~/start-remote.sh

# Script dừng VNC server
cat > ~/stop-remote.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver -kill :1 2>/dev/null && echo "✓ Đã dừng VNC server." || echo "⚠ Không có VNC server đang chạy (display :1)."
EOF
chmod +x ~/stop-remote.sh

# Bước 11: Tối ưu XFCE để chạy mượt trên RAM thấp (tắt compositor, hiệu ứng không cần thiết)
update_progress "Tối ưu XFCE cho TV/thiết bị RAM thấp (tắt hiệu ứng)"

# Tạo file cấu hình xfconf để tắt compositing
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="vblank_mode" type="string" value="off"/>
    <property name="sync_to_vblank" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="popup_opacity" type="int" value="100"/>
  </property>
</channel>
EOF

# Tắt các service không cần thiết trong XFCE (ví dụ: không khởi động xscreensaver, không kiểm tra bàn phím)
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/disable-compositing.desktop << EOF
[Desktop Entry]
Type=Application
Name=Disable Compositing
Exec=xfconf-query -c xfwm4 -p /general/use_compositing -s false
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

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

# Thông báo hoàn tất
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cài đặt hoàn tất thành công!${NC}"
echo -e "${YELLOW}Hướng dẫn sử dụng:${NC}"
echo ""
echo "1. Dùng DESKTOP TRỰC TIẾP TRÊN ĐIỆN THOẠI:"
echo "   - Chạy: ~/start-desktop.sh"
echo "   - Mở ứng dụng Termux-X11 (tải riêng từ F-Droid hoặc GitHub)"
echo "   - Để dừng: ~/stop-desktop.sh"
echo ""
echo "2. Dùng REMOTE QUA VNC (từ TV Android hoặc máy khác cùng mạng Wi-Fi):"
echo "   - Chạy: ~/start-remote.sh"
echo "   - Trên TV, cài ứng dụng VNC Viewer, kết nối tới địa chỉ IP:5901"
echo "   - Mật khẩu bạn đã đặt khi chạy lần đầu"
echo "   - Để dừng VNC: ~/stop-remote.sh"
echo ""
echo "3. Đổi hình nền XFCE: chuột phải trên màn hình → Desktop Settings"
echo "4. Các hiệu ứng XFCE đã bị vô hiệu hóa để tăng tốc trên RAM 1-2GB"
echo -e "${GREEN}========================================${NC}"