#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/satori.sh"

echo ""
echo "#################################################"
echo "#               Installing Satori               #"
echo "#################################################"
echo ""
echo "安装成功请等待半小时初始化后 前往Dashboard链接【http://ip:24601】设置Vault密码 并且开启MINE-TO-VAULT====ENABLED模式"
echo ""
function install_satori() {
    # Step -1: Install Docker
    echo "Step -1: Installing Docker..."

    # Check if Docker is installed
    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker is already installed."
    fi

    # Step 0: Download and unzip Satori
    echo "Step 0: Downloading and unzipping Satori..."

        # 检查并安装zip
    if ! dpkg -l | grep -q zip; then
    echo "Installing zip..."
    sudo apt-get install -y zip
    else
    echo "zip is already installed"
    fi

    # 检查并安装unzip
    if ! dpkg -l | grep -q unzip; then
    echo "Installing unzip..."
    sudo apt-get install -y unzip
    else
    echo "unzip is already installed"
    fi

    # 检查并安装wget
    if ! dpkg -l | grep -q wget; then
    echo "Installing wget..."
    sudo apt-get install -y wget
    else
    echo "wget is already installed"
    fi

    # 检查并安装curl
    if ! dpkg -l | grep -q curl; then
    echo "Installing curl..."
    sudo apt-get install -y curl
    else
    echo "curl is already installed"
    fi

    cd ~
    wget -P ~/ https://satorinet.io/static/download/linux/satori.zip
    unzip ~/satori.zip
    rm ~/satori.zip
    cd ~/.satori

    # Manual Step: Add referral code
    echo "Creating config directory and adding referral code..."
    mkdir -p ./config
    # 设置默认推荐码
    default_referral_code="0236ff9f79b4cfed36f703ddb4a58dd3fa0e22cad5517f40be05a038fe09e719ab"
    
    # 提示用户输入推荐码
    read -p "输入邀请码(回车默认): " referral_code
    
    # 如果用户没有输入任何内容，则使用默认推荐码
    referral_code=${referral_code:-$default_referral_code}
    
    # 将推荐码写入到文件中
    echo $referral_code >> ./config/referral.txt

    # Step 1: Install dependencies
    echo "Step 1: Installing dependencies..."

    # 检查 python3-venv 是否已经安装
    if dpkg -l | grep -qw python3-venv; then
        echo "python3-venv 已经安装，跳过安装步骤。"
    else
        echo "正在安装 python3-venv..."
        sudo apt-get update
        sudo apt-get install python3-venv -y
        echo "python3-venv 安装完成。"
    fi

    # Run the install script
    chmod +x install.sh
    bash install.sh

    # Step 2: Set up a service to keep Satori running
    chmod +x install_service.sh
    bash install_service.sh

    echo "Satori installation and setup complete!"
}

function check_service_status() {
    echo "Checking Satori service status..."
    sudo systemctl status satori.service
}

function watch_service_logs() {
    echo "Watching Satori service logs..."
    journalctl -fu satori.service
}

function unistall(){
    rm -rf /root/.satori /root/satorienv
    
    # 获取所有基于 satorinet/satorineuron:latest 镜像的容器 ID
    containers=$(docker ps -a -q --filter ancestor=satorinet/satorineuron:latest)
    
    # 停止这些容器
    if [ -n "$containers" ]; then
      docker stop $containers
      docker rm $containers
    fi
    
    # 删除镜像
    docker rmi satorinet/satorineuron:latest
}

function config(){
    cd $HOME/.satori
    pip install -r "./requirements.txt"
    deactivate

    # Step 2: Set up a service to keep Satori running
    echo "Step 2: Setting up service to keep Satori running..."
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    sed -i "s/#User=.*/User=$USER/" "$(pwd)/satori.service"
    sed -i "s|WorkingDirectory=.*|WorkingDirectory=$(pwd)|" "$(pwd)/satori.service"
    sudo cp satori.service /etc/systemd/system/satori.service
    sudo systemctl daemon-reload
    sudo systemctl enable satori.service
    sudo systemctl start satori.service

    echo "Satori installation and setup complete!"
}

echo "请选择要执行的功能:"
echo "1) 安装 Satori"
echo "2) 检查 Satori 服务状态"
echo "3) 查看 Satori 服务日志"
echo "4) 卸载Satori"
read -p "请输入你选择的功能 (1~5): " func

case $func in
    1)
        install_satori
        ;;
    2)
        check_service_status
        ;;
    3)
        watch_service_logs
        ;;
    4)
        unistall
        ;;
    *)
        echo "无效选项，请输入 1, 2, 3 或 4."
        ;;
esac
