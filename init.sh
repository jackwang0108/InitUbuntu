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

# 脚本目录
dir=$(dirname "$(readlink -f "$0")")

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

    # 安装必要工具
    echo "${password}" | sudo -S apt install curl dialog
}

function dialog_input() {
    msg=$1
    filename=$2
    height=$3
    width=$4
    dialog --inputbox "${msg}" "${height}" "${width}" 2>"${filename}"
    clear
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
    git config --global https.proxy http://127.0.0.1:7890
    git config --global https.proxy https://127.0.0.1:7890
    alias wget="wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890"
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
    unalias wget
}
" >>"${file}"
    fi
}

function init_clash() {
    echo "=> 正在配置clash"
    # 下载clash
    if [[ ! -e ~/opt/clash/clash ]]; then
        [[ ! -d new ]] && git clone https://gitee.com/jackwangsh/new.git
        gzip -d new/hello.gz
        gzip -d new/GeoLite2-Country.mmdb.gz
        mkdir -p ~/opt/clash && mv new/* ~/opt/clash && rm -rf new
        mv ~/opt/clash/hello ~/opt/clash/clash
        mv ~/opt/clash/GeoLite2-Country.mmdb ~/opt/clash/Country.mmdb
        chmod +x ~/opt/clash/clash
    fi
    # 更新订阅链接
    if [[ ! -e ~/opt/clash/config.yaml ]]; then
        # read -p "请输入Clash订阅链接: " -r subscription && echo ""
        cs_file="$dir"/clash_subscription.txt
        dialog_input "请输入Clash订阅链接: " "${cs_file}" 10 100
        subscription=$(cat "${cs_file}")
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
    sleep 5
    if HTTP_PROXY="http://127.0.0.1:7890" HTTPS_PROXY="http://127.0.0.1:7890" ALL_PROXY="socks5://127.0.0.1:7890" curl -# www.google.com >/dev/null; then
        echo "clash配置成功!"
    else
        echo "clash配置失败!"
    fi
    killall clash

    # 开机自启动
    echo "${password}" | sudo -S cp "${dir}"/clash.service /etc/systemd/system/
    echo "${password}" | sudo -S systemctl daemon-reload
    echo "${password}" | sudo -S systemctl enable clash.service
    echo "${password}" | sudo -S systemctl start clash.service

    # 检查状态
    sleep 3
    status=$(systemctl status clash.service --no-pager)
    if [[ $status =~ "Active: active" ]]; then
        echo "已配置clash开机自启动"
    else
        echo "clash开机自启动配置失败"
    fi
    sleep 3
    if HTTP_PROXY="http://127.0.0.1:7890" HTTPS_PROXY="http://127.0.0.1:7890" ALL_PROXY="socks5://127.0.0.1:7890" curl -# www.google.com >/dev/null; then
        echo "clash已成功在后台运行"
    else
        echo "clash未成功在后台运行"
    fi

    # 向bash中添加代理函数
    add_function ~/.bashrc

    # 配置dashboard
    echo "配置Clash Dashboard"
    echo "由于DNS污染问题, 可能需要等待较长的一段时间"
    attempt=1
    if ! (wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 -P ~/opt/clash -c https://github.com/haishanh/yacd/releases/download/v0.3.7/yacd.tar.xz); then
        attempt+=1
        rm ~/opt/clash/yacd.tar.xz
    fi
    if [[ $attempt -gt 5 ]]; then
        echo "yacd下载失败"
    fi
    if [[ -e ~/opt/clash/yacd.tar.xz ]]; then
        tar -xJf ~/opt/clash/yacd.tar.xz -C ~/opt/clash
        mv ~/opt/clash/public ~/opt/clash/dashboard
    fi
    sed -i -e "s/^secret:.*/secret: '123456'/" \
        -e "/^secret:.*/a external-ui: dashboard" \
        ~/opt/clash/config.yaml
    # 重启 clash 服务
    echo "${password}" | sudo systemctl restart clash.service
    echo "浏览器访问 http://localhost:9090/ui 或 http://$(curl ifconfig.me)/ui 以登录dashboard"
    echo "用户名为主机地址:9090, 密码默认123456"
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
    echo "${password}" | sudo -S apt install -y zsh
    # 下载ohmyzsh
    attempt=1
    while [ $attempt -le 5 ]; do
        # 检查curl的退出状态码
        if ! (echo n | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"); then
            # 删除下载到一半的文件
            echo "重试... ${attempt}"
            rm -rf ~/.oh-my-zsh
            attempt+=1
        else
            break
        fi
        # 等待一段时间再进行下一次尝试
        sleep 1
    done
    if [[ $attempt -gt 5 ]]; then
        echo "oh my zsh下载失败"
    fi

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
    # zsh自带插件
    sed -i "s/plugins=(/plugins=(copypath copyfile copybuffer sudo /" ~/.zshrc
    # github下载插件
    zsh_plugin zsh-autosuggestions "https://github.com/zsh-users/zsh-autosuggestions"
    zsh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
    zsh_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search
    # 修改默认终端
    echo "${password}" | chsh --shell "$(which zsh)" "$(whoami)"
    add_function ~/.zshrc

    # 下载字体
    echo "正在配置字体"
    echo "由于DNS污染问题, 可能需要等待较长的一段时间"
    attempt=1
    while [ $attempt -le 5 ]; do
        if ! (wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 -P "${dir}" -c https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Agave.zip); then
            attempt+=1
        else
            break
        fi
    done
    # 安装字体
    echo "${password}" | sudo -S mkdir -p /usr/share/fonts/Agave
    echo "${password}" | sudo -S unzip -q "${dir}"/Agave.zip -d /usr/share/fonts/Agave
    sudo chmod 744/usr/share/fonts/Agave/*.ttf
    echo "${password}" | sudo mkfontscale
    echo "${password}" | sudo mkfontdir
    echo "${password}" | sudo fc-cache -fv
}

function init_tmux() {
    echo "=> 正在配置tmux"
    echo "${password}" | sudo -S apt install tmux -y
    mkdir -p ~/opt/tmux
    cp "${dir}"/.tmux.conf ~/
}

function init_vim() {
    echo
}

function init_frp() {
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export ALL_PROXY=socks5://127.0.0.1:7890
    echo "=> 正在配置frp"
    input=""
    while [[ "$input" != "c" && "$input" != "s" ]]; do
        read -p "配置frpc客户端/服务端[c/s]: " -r input
    done

    if [[ "$input" == "c" ]]; then
        echo "配置frp客户端"
        git clone https://gitee.com/jackwangsh/frp.git ~/opt/frpc && rm -rf ~/opt/frp/.git
        tar xzvf ~/opt/frpc/frp_0.51.0_linux_amd64.tar.gz -C ~/opt/frpc
        rm ~/opt/frpc/frp_0.51.0_linux_amd64/frps*
        cp "${dir}"/frpc.ini ~/opt/frpc/
        ln -s ~/opt/frpc/frp_0.51.0_linux_amd64 ~/opt/frpc/bin
        # 配置systemd服务
        echo "${password}" | sudo -S cp "${dir}"/frpc.service /etc/systemd/system/frpc.service
        echo "${password}" | sudo -S systemctl daemon-reload
        echo "${password}" | sudo -S systemctl enable frpc.service
        echo "${password}" | sudo -S systemctl start frpc.service
        echo "编辑 ~/opt/frpc/frpc.ini 文件添加规则, 别忘了systemctrl restart frpc.service"
    elif [[ "$input" == "s" ]]; then
        echo "配置frp服务端"
        git clone https://gitee.com/jackwangsh/frp.git ~/opt/frps && rm -rf ~/opt/frp/.git
        tar xzvf ~/opt/frps/frp_0.51.0_linux_amd64.tar.gz -C ~/opt/frps
        rm ~/opt/frps/frp_0.51.0_linux_amd64/frpc*
        cp "${dir}"/frps.ini ~/opt/frps/
        ln -s ~/opt/frps/frp_0.51.0_linux_amd64 ~/opt/frps/bin
        # 配置systemd服务
        echo "${password}" | sudo -S cp "${dir}"/frps.service /etc/systemd/system/frps.service
        echo "${password}" | sudo -S systemctl daemon-reload
        echo "${password}" | sudo -S systemctl enable frps.service
        echo "${password}" | sudo -S systemctl start frps.service
    fi
}

function init_nodejs() {
    echo "=> 正在配置NodeJS"
    mkdir ~/opt/nodejs/
    wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 -c -P ~/opt/nodejs https://nodejs.org/dist/v20.9.0/node-v20.9.0-linux-x64.tar.xz
    tar xJvf ~/opt/nodejs/node-v20.9.0-linux-x64.tar.xz -C ~/opt/nodejs
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/bin ~/opt/nodejs/bin
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/include ~/opt/nodejs/include
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/lib ~/opt/nodejs/lib
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/share ~/opt/nodejs/share

    # shellcheck disable=SC2016
    echo 'export PATH=/home/jack/opt/nodejs/node-v20.9.0-linux-x64/bin:${PATH}' >>~/.zshrc
}

function init_rust() {
    echo "$1" # arguments are accessible through $1, $2,...
}

function init_yarn() {
    echo "$1" # arguments are accessible through $1, $2,...
}

function init_lunarvim() {
    echo "$1" # arguments are accessible through $1, $2,...
}

function init_gptnextweb() {
    echo "=> 正在配置ChatGPT NetWeb"
}

# TODO: 增加dialog menu菜单
# 主循环
while true; do
    # 使用dialog创建菜单
    choice=$(dialog --menu "选择一个选项：" 30 50 5 \
        1 "换源USTC" \
        2 "配置Clash" \
        3 "配置ZSH" \
        4 "配置TMUX" \
        5 "配置FRP" \
        6 "配置NodeJS" \
        7 "退出" 2>&1 >/dev/tty)
    clear
    # 根据用户的选择执行相应的操作
    case $choice in
    1)
        change_source
        ;;
    2)
        init_clash
        ;;
    3)
        init_zsh
        ;;
    4)
        init_tmux
        ;;
    5)
        init_frp
        ;;
    6)
        init_nodejs
        ;;
    7)
        break # 退出循环，结束应用
        ;;
    *)
        echo "无效的选项"
        ;;
    esac

done

echo "Have a good day and enjoy your Ubuntu :)"
