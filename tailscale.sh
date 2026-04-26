# 适用与 code server 的 tailscale 自动安装脚本

# 获取二进制文件
wget https://dl.tailscale.com/stable/tailscale_1.96.4_amd64.tgz

# 解压
tar -xf tailscale_1.96.4_amd64.tgz

# 加入环境变量
echo "alias tailscale='sudo /home/coder/workspace/tailscale_1.96.4_amd64/tailscale'" >> ~/.bashrc
echo "alias tailscaled='sudo /home/coder/workspace/tailscale_1.96.4_amd64/tailscaled'" >> ~/.bashrc

# 删除压缩包
rm tailscale_1.96.4_amd64.tgz

# 完成后记得 source ~/.bashrc
echo 'Please run "source ~/.bashrc"'
