#!/bin/bash
# Script setup terminal giống Kali trên Termux (ZSH + Oh My Zsh + Powerlevel10k)

echo "▶️  Cập nhật Termux..."
pkg update -y && pkg upgrade -y

echo "▶️  Cài các gói cần thiết..."
pkg install zsh git curl nano -y

echo "▶️  Cài Oh My Zsh..."
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "▶️  Cài Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

echo "▶️  Thiết lập theme Powerlevel10k..."
sed -i 's|ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|g' ~/.zshrc

echo "▶️  Thiết lập prompt kiểu Kali (cố định hiển thị kali㉿kali)..."
# Xoá dòng PROMPT cũ nếu có để tránh trùng lặp
sed -i '/^PROMPT=/d' ~/.zshrc
echo "PROMPT='(kali㉿kali)-[%~] '" >> ~/.zshrc

echo "▶️  Thêm các alias thường dùng..."
{
  echo "alias ll='ls -alF'"
  echo "alias la='ls -A'"
  echo "alias l='ls -CF'"
} >> ~/.zshrc

echo "▶️  Đổi shell mặc định thành ZSH..."
chsh -s zsh

echo "▶️  Áp dụng cấu hình cho phiên hiện tại..."
source ~/.zshrc

echo "✅ Hoàn tất! Hãy thoát hoàn toàn Termux và mở lại để thấy giao diện mới."