#!/bin/bash

# 获取密码
read -p "请输入用户密码: " -r -s password && echo ""
# 测试是否为sudo用户
if echo "${password}" | sudo -S true 2>/dev/null; then
    echo ""
else
    echo "当前用户非SUDO用户"
    exit 1
fi

# 展示系统信息
lsb_release -idcr && echo ""

function change_source() {
    echo "=> 正在换源"
    # 版本代号
    code_name=$(lsb_release -cs)
    # 中科大源
    ustc_source="\
deb https://mirrors.ustc.edu.cn/ubuntu/ ${code_name} main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-security main restricted universe multiverse

# deb-src https://mirrors.ustc.edu.cn/ubuntu/ ${code_name} main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-updates main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-backports main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-security main restricted universe multiverse

## Pre-released source, not recommended.
# deb https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-proposed main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ ${code_name}-proposed main restricted universe multiverse
"
    # 备份先前源
    echo "${password}" | sudo -S cp /etc/apt/sources.list /etc/apt/sources.list.backup-"$(date +%Y.%m.%d.%S)"
    # 设置新源
    echo "${ustc_source}" >>temp
    echo "${password}" | sudo -S cp temp /etc/apt/sources.list
    rm temp

    # 更新
    echo "${password}" | sudo -S apt update
    echo "${password}" | sudo -S apt upgrade -y
}

function add_function() {
    file=$1
    echo "添加proxy_on和proxy_off到$file"中
    if ! grep -q "function proxy_on" "${file}"; then
        # 函数不存在，添加函数到.bashrc文件
        echo "
function proxy_on() {
    echo '命令行代理已开启'
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export ALL_PROXY=socks://127.0.0.1:7890
    git config --global https.proxy http://127.0.0.1:1080
    git config --global https.proxy https://127.0.0.1:1080
}
" >>"${file}"
    fi
    if ! grep -q "function proxy_off" "${file}"; then
        # 函数不存在，添加函数到.bashrc文件
        echo "
function proxy_off() {
    echo '命令行代理已关闭'
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}
" >>"${file}"
    fi
}

function init_clash() {
    echo "=> 正在配置clash"
    # 下载clash
    if [[ ! -e ~/opt/clash/clash ]]; then
        [[ ! -d new ]] && git clone https://gitee.com/jackwangsh/new.git
        gzip -d new/*
        mkdir -p ~/opt/clash && mv new/* ~/opt/clash && rm -rf new
        mv ~/opt/clash/hello ~/opt/clash/clash
        chmod +x ~/opt/clash/clash
    fi
    # 更新订阅链接
    if [[ ! -e ~/opt/clash/config.yaml ]]; then
        read -p "请输入Clash订阅链接: " -r -s subscription && echo ""
        wget -c "${subscription}" -O ~/opt/clash/config.yaml
        # 修改配置信息
        sed -i -e '/^port:/s/^/#/' \
            -e '/^socks-port:/s/^/#/' \
            -e '/^redir-port:/s/^/#/' \
            -e '/^log-level:/s/silent/info/' \
            -e "6a mixed-port: 7890" \
            ~/opt/clash/config.yaml
    fi

    # 测试
    ~/opt/clash/clash -d ~/opt/clash &
    sleep 3
    if ALL_PROXY="socks5://127.0.0.1:7890" curl -# www.google.com >/dev/null; then
        echo "clash配置成功!"
    else
        echo "clash配置失败!"
    fi
    killall clash

    # 开机自启动
    echo "${password}" | sudo cp ~/opt/clash/clash.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable clash.service
    sudo systemctl start clash.service

    # 检查状态
    status=$(systemctl status clash.service --no-pager)
    if [[ $status =~ "Active: active" ]]; then
        echo "已配置clash开机自启动"
    else
        echo "clash开机自启动配置失败"
    fi
    sleep 3
    if ALL_PROXY="socks5://127.0.0.1:7890" curl -# www.google.com >/dev/null; then
        echo "clash已成功在后台运行"
    else
        echo "clash未成功在后台运行"
    fi

    # 向bash中添加代理函数
    add_function ~/.bashrc

}

function zsh_plugin() {
    plugin=$1
    url=$2
    git clone --depth=1 "${url}" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    # 添加插件到.zshrc中
    sed -i "s/plugins=(/plugins=($plugin /" ~/.zshrc
    echo "已添加插件 $plugin"
}

function init_zsh() {
    echo "=> 正在配置zsh"
    export ALL_PROXY=socks5://127.0.0.1:7890
    # 下载zsh
    echo "${password}" | sudo -S apt install zsh
    # 下载ohmyzsh
    # TODO: curl不稳定, 需要确认是否成功
    echo n | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sleep 3
    # 配置powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    echo "\
# To customize prompt, run \$(p10k configure) or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
" >>~/.zshrc
    git clone https://gitee.com/jackwangsh/p10k_config.git ~/p10k_config
    mv ~/p10k_config/.p10k.zsh ~ && rm -rf ~/p10k_config
    # 配置插件
    zsh_plugin zsh-autosuggestions "https://github.com/zsh-users/zsh-autosuggestions"
    zsh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
    # 修改默认终端
    chsh -s "$(which zsh)"
    add_function ~/.zshrc
}

function init_tmux() {
    echo "=> 正在配置tmux"
    echo "${password}" | sudo -S apt install tmux -y
}

function init_vim() {
    echo
}

function init_frp() {
    echo
}

# 流程
#   1. 换源, 更新
#   2. 下载配置 clash
#   3. 下载配置 ZSH

#change_source
#init_clash
init_zsh
