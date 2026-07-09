#!/bin/bash
# ============================================
# Script cài môi trường đồ họa + VNC trên VPS
# Dành cho Ubuntu 20.04 / 22.04
# Chạy với quyền root: sudo bash setup_vps.sh
# ============================================

set -e

# ---------- Biến cấu hình ----------
VNC_PASSWORD="123456"          # Đổi mật khẩu này
VNC_DISPLAY="1"                # Cổng VNC = 5900 + display (5901)
VNC_GEOMETRY="1280x720"        # Độ phân giải màn hình
LOG_FILE="/var/log/vps_setup.log"

# ---------- Màu sắc ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "[$(date)] $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[OK] $1${NC}"; }
log_info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }

# Kiểm tra root
if [[ $EUID -ne 0 ]]; then log_error "Phải chạy với sudo hoặc root"; fi

# ---------- Cập nhật hệ thống ----------
log_info "Cập nhật hệ thống..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >> "$LOG_FILE" 2>&1
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" >> "$LOG_FILE" 2>&1
log_success "Hệ thống cập nhật xong."

# ---------- Cài các gói cơ bản ----------
log_info "Cài gói cơ bản..."
apt-get install -y curl wget git vim htop net-tools software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release ufw fail2ban \
    unzip tar build-essential x11-utils xauth dbus-x11 >> "$LOG_FILE" 2>&1
log_success "Gói cơ bản xong."

# ---------- Cài môi trường đồ họa XFCE ----------
log_info "Cài XFCE và TigerVNC..."
apt-get install -y xfce4 xfce4-goodies tigervnc-standalone-server >> "$LOG_FILE" 2>&1
log_success "XFCE và VNC đã cài."

# ---------- Cấu hình VNC ----------
log_info "Thiết lập VNC server..."
mkdir -p /root/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

cat > /root/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF
chmod +x /root/.vnc/xstartup

# Dừng VNC nếu đang chạy, rồi khởi động
vncserver -kill :$VNC_DISPLAY 2>/dev/null || true
vncserver :$VNC_DISPLAY -geometry $VNC_GEOMETRY -depth 24 -localhost no
log_success "VNC đang chạy trên cổng 590$VNC_DISPLAY"

# ---------- Firewall ----------
log_info "Cấu hình UFW..."
ufw default deny incoming >> "$LOG_FILE" 2>&1
ufw default allow outgoing >> "$LOG_FILE" 2>&1
ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1
ufw allow 80/tcp comment 'HTTP' >> "$LOG_FILE" 2>&1
ufw allow 443/tcp comment 'HTTPS' >> "$LOG_FILE" 2>&1
ufw allow 5901/tcp comment 'VNC' >> "$LOG_FILE" 2>&1   # Điều chỉnh nếu VNC_PORT khác
echo "y" | ufw enable >> "$LOG_FILE" 2>&1
log_success "Tường lửa đã bật, các cổng đã mở."

# ---------- (Tùy chọn) Cài Docker ----------
log_info "Cài Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y >> "$LOG_FILE" 2>&1
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >> "$LOG_FILE" 2>&1
systemctl enable docker >> "$LOG_FILE" 2>&1
systemctl start docker >> "$LOG_FILE" 2>&1
log_success "Docker sẵn sàng."

# ---------- (Tùy chọn) Cài Nginx ----------
log_info "Cài Nginx..."
apt-get install -y nginx >> "$LOG_FILE" 2>&1
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1
log_success "Nginx đang chạy."

# ---------- Cài đặt "spirit" (bạn thay đổi tại đây) ----------
log_info "Cài đặt 'spirit'..."
# Ví dụ clone từ git:
# git clone https://github.com/your/spirit.git /opt/spirit
# cd /opt/spirit && ./install.sh
# Hoặc chạy script cài đặt của bạn:
# bash /path/to/install_spirit.sh
echo "Chưa có lệnh cài spirit. Bạn hãy bổ sung ở phần này." >> "$LOG_FILE"

# ---------- Dọn dẹp ----------
apt-get autoremove -y >> "$LOG_FILE" 2>&1
apt-get autoclean -y >> "$LOG_FILE" 2>&1

# ---------- Thông báo hoàn tất ----------
PUBLIC_IP=$(curl -s ifconfig.me || echo "Không lấy được")
log_success "🎉 Cài đặt hoàn tất!"
echo -e "${GREEN}========================================${NC}"
echo -e "Địa chỉ VPS: $PUBLIC_IP"
echo -e "Cổng VNC: 590$VNC_DISPLAY"
echo -e "Mật khẩu VNC: $VNC_PASSWORD"
echo -e "Log chi tiết: $LOG_FILE"
echo -e "Bây giờ bạn có thể kết nối từ điện thoại qua VNC."
echo -e "${GREEN}========================================${NC}"