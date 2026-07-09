#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# Kết nối VNC tới VPS và hiển thị trên Termux-X11
# Sử dụng: bash vnc_phone.sh
# ============================================

# ---------- Cấu hình (sửa cho đúng VPS của bạn) ----------
VPS_IP="192.168.1.100"          # Địa chỉ IP của VPS (công cộng hoặc LAN)
VNC_PORT="5901"                 # Cổng VNC (thường là 5901)
VNC_PASSWORD="123456"           # Mật khẩu VNC đã đặt trên VPS

# ---------- Kiểm tra Termux-X11 ----------
if ! pgrep -f "com.termux.x11" > /dev/null; then
    echo -e "\033[31m[LỖI]\033[0m Termux-X11 chưa được mở!"
    echo "Hãy mở ứng dụng Termux-X11 trước, sau đó quay lại và chạy script này."
    exit 1
fi

# ---------- Cài đặt công cụ nếu thiếu ----------
if ! command -v vncviewer &> /dev/null; then
    echo "⏳ Đang cài tigervnc-viewer..."
    pkg install -y tigervnc
fi

if ! command -v vncpasswd &> /dev/null; then
    echo "⏳ Đang cài vncpasswd..."
    pkg install -y tigervnc
fi

# ---------- Tạo file mật khẩu (để tự động đăng nhập) ----------
PASSWD_FILE="$HOME/.vnc_passwd"
if [ ! -f "$PASSWD_FILE" ]; then
    echo "🔐 Tạo file mật khẩu VNC..."
    mkdir -p "$(dirname "$PASSWD_FILE")"
    echo "$VNC_PASSWORD" | vncpasswd -f > "$PASSWD_FILE"
    chmod 600 "$PASSWD_FILE"
fi

# ---------- Xuất DISPLAY để hiển thị lên Termux-X11 ----------
export DISPLAY=:0

# ---------- Kết nối VNC ----------
echo "🚀 Đang kết nối đến $VPS_IP:$VNC_PORT ..."
vncviewer "$VPS_IP:$VNC_PORT" --passwd "$PASSWD_FILE" &

# Giữ màn hình Termux nếu muốn (tùy chọn)
# wait