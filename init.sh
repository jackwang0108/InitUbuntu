#!/bin/bash

# 检查dialog工具是否已安装
if ! command -v dialog &>/dev/null; then
    echo "dialog工具未安装，请先安装，运行sudo apt install dialog -y以安装"
    exit 1
fi

# 检查用户是否具有sudo权限
if sudo -l 2>/dev/null; then
    echo "当前用户是SUDO用户"
    password=$(dialog --title "输入密码" --clear --passwordbox "请输入你的密码" 10 30 2>&1 >/dev/tty)
    clear && echo "=> 正在安装必要工具"
    echo "${password}" | sudo -S apt install curl wget
else
    # 使用dialog工具显示消息框
    dialog --title "警告" --msgbox "当前用户非SUDO用户，该工具仅能以SUDO用户运行！" 10 50
    exit 1
fi

# 脚本目录
dir=$(dirname "$(readlink -f "$0")")
# 配置文件
temp_file="${dir}"/tempfile
config_file="${dir}"/config.cfg
if [ ! -f "$config_file" ]; then
    # 使用dialog创建输入框，并将结果保存在临时文件中
    dialog --inputbox "请输入代理端口:" 10 30 2>"${temp_file}"
    proxy_port=$(<"${temp_file}")
    echo "proxy_port=${proxy_port}" >"${config_file}"
    rm "${temp_file}"
else
    # shellcheck source=/dev/null
    source "${config_file}"
    dialog --title "通知" --msgbox "正在使用${proxy_port}作为代理端口\n编辑${config_file}以修改端口" 10 50
fi

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
    export HTTP_PROXY=http://127.0.0.1:${proxy_port}
    export HTTPS_PROXY=http://127.0.0.1:${proxy_port}
    export ALL_PROXY=socks://127.0.0.1:${proxy_port}
    git config --global https.proxy http://127.0.0.1:${proxy_port}
    git config --global https.proxy https://127.0.0.1:${proxy_port}
    alias wget=\"wget -e http_proxy=127.0.0.1:${proxy_port} -e https_proxy=127.0.0.1:${proxy_port}\"
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

function choose_shell() {
    msg=$1
    choice=$(
        dialog --title "${msg}" --menu "请选择一个Shell：" 10 40 2 \
            1 "zsh" \
            2 "bash" \
            2>&1 >/dev/tty
    )
    clear
    case $choice in
    1)
        echo "zsh"
        ;;
    2)
        echo "bash"
        ;;
    esac
}

function init_clash() {
    echo "=> 正在配置clash"
    # 下载clash
    clash_home="$HOME"/opt/clash
    mkdir -p "$clash_home"
    if [[ ! -f ~/opt/clash/clash ]]; then
        [[ ! -d new ]] && git clone https://gitee.com/jackwangsh/new.git
        gzip -d new/hello.gz
        gzip -d new/GeoLite2-Country.mmdb.gz
        mv new/* "$clash_home" && rm -rf new
        mv "$clash_home"/hello "$clash_home"/clash
        mv "$clash_home"/GeoLite2-Country.mmdb "$clash_home"/Country.mmdb
        chmod +x "$clash_home"/clash
    fi
    # 更新订阅链接
    if [[ ! -e "$clash_home"/config.yaml ]]; then
        # read -p "请输入Clash订阅链接: " -r subscription && echo ""
        cs_file="$dir"/clash_subscription.txt
        dialog --inputbox "请输入Clash订阅链接" 10 100 2>"${dir}/clash_subscription.txt" && clear
        subscription=$(cat "${cs_file}")
        wget -c "${subscription}" -O "$clash_home"/config.yaml
        # 修改配置信息
        sed -i -e '/^port:/s/^/#/' \
            -e '/^socks-port:/s/^/#/' \
            -e '/^redir-port:/s/^/#/' \
            -e '/^log-level:/s/silent/info/' \
            -e "6a mixed-port: 7890" \
            ~/opt/clash/config.yaml
    fi

    # 测试
    "$clash_home"/clash -d "$clash_home" &
    sleep 5
    if HTTP_PROXY="http://127.0.0.1:${proxy_port}" HTTPS_PROXY="http://127.0.0.1:${proxy_port}" ALL_PROXY="socks5://127.0.0.1:${proxy_port}" curl -# www.google.com >/dev/null; then
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
    if HTTP_PROXY="http://127.0.0.1:${proxy_port}" HTTPS_PROXY="http://127.0.0.1:${proxy_port}" ALL_PROXY="socks5://127.0.0.1:${proxy_port}" curl -# www.google.com >/dev/null; then
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
    if ! (wget -e "http_proxy=127.0.0.1:${proxy_port}" -e "https_proxy=127.0.0.1:${proxy_port}" -P "$clash_home" -c https://github.com/haishanh/yacd/releases/download/v0.3.7/yacd.tar.xz); then
        attempt+=1
    fi
    if [[ $attempt -gt 5 ]]; then
        echo "yacd下载失败"
    fi
    if [[ -e $clash_home/yacd.tar.xz ]]; then
        tar -xJf "$clash_home"/yacd.tar.xz -C "$clash_home"
        mv "$clash_home"/public "$clash_home"/dashboard
    fi
    sed -i -e "s/^secret:.*/secret: '123456'/" \
        -e "/^secret:.*/a external-ui: dashboard" \
        "$clash_home"/config.yaml
    # 重启 clash 服务
    echo "${password}" | sudo systemctl restart clash.service
    echo "浏览器访问 http://localhost:9090/ui 或 http://$(curl ifconfig.me)/ui 以登录dashboard"
    echo "用户名为主机地址:9090, 密码默认123456"
}

function init_qv2ray() {
    echo "=> 正在配置Qv2ray"
    mkdir -p ~/opt/qv2ray/v2ray
    # 下载qv2ray
    git clone https://gitee.com/jackwangsh/newnew.git ~/opt/qv2ray && rm -rf ~/opt/v2ray/.git
    chmod +x ~/opt/qv2ray/Qv2ray-v2.7.0-linux-x64.AppImage
    unzip -d ~/opt/qv2ray/v2ray ~/opt/qv2ray/new.zip
    mkdir -p ~/.config/qv2ray/plugins
    cp ~/opt/qv2ray/QvPlugin-* ~/.config/qv2ray/plugins
    # 配置libfuse2
    echo "${password}" | sudo -S apt install libfuse2
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
    mv "${dir}/.p10k.zsh" "${HOME}"
    # 配置插件
    # zsh自带插件
    sed -i "s/plugins=(/plugins=(copypath copyfile copybuffer sudo /" ~/.zshrc
    # github下载插件
    zsh_plugin zsh-autosuggestions "https://github.com/zsh-users/zsh-autosuggestions"
    zsh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
    zsh_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search
    echo "
# zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey \"\$terminfo[kcuu1]\" history-substring-search-up
bindkey \"\$terminfo[kcud1]\" history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(bg=red,fg=magenta,bold)
" >>~/.zshrc
    zsh_plugin zsh-vi-mode https://github.com/jeffreytse/zsh-vi-mode.git
    echo "
ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
" >>~/.zshrc

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
    choice=$(
        dialog --title "${msg}" --menu "请选择使用的Tmux配置：" 10 40 2 \
            1 "MyConfig" \
            2 "Oh-my-Tmux" \
            2>&1 >/dev/tty
    )
    clear
    tmux_home="${HOME}"/opt/tmux
    if [[ $choice == "Myconfig" ]]; then
        mkdir -p "${tmux_home}"
        cp "${dir}"/.tmux.conf "${tmux_home}"
        ln -s -f "${tmux_home}"/.tmux.conf ~/.tmux.conf
    else
        git clone https://github.com/gpakosz/.tmux.git "${tmux_home}"/oh-my-tmux
        ln -s -f "${tmux_home}"/oh-my-tmux/.tmux.conf "${HOME}"
        cp "${dir}"/.tmux.conf.local "${tmux_home}"/oh-my-tmux/.tmux.conf.local
        ln -s -f "${tmux_home}"/oh-my-tmux/.tmux.conf.local "${HOME}"
    fi
}

function init_vim() {
    echo "=> 正在配置VIM"
    # 首先复制默认vim设置
    cp "${dir}"/.vimrc ~/
    # 创建分区
    mkdir -p ~/.vim/.backup
    mkdir -p ~/.vim/.swp
    mkdir -p ~/.vim/.undo
    # 设置默认编辑器为VIM
    echo '
export EDITOR=vim
'
    # 设置root使用的vim
    echo "${password}" | sudo -S cp "${dir}"/.vimrc /root
    echo "${password}" | sudo -S mkdir -p root/.vim/.backup
    echo "${password}" | sudo -S mkdir -p root/.vim/.swp
    echo "${password}" | sudo -S mkdir -p root/.vim/.undo
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
    # 用户的NodeJS安装在~/opt下
    mkdir ~/opt/nodejs/
    wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 -c -P ~/opt/nodejs https://nodejs.org/dist/v20.9.0/node-v20.9.0-linux-x64.tar.xz
    tar xJvf ~/opt/nodejs/node-v20.9.0-linux-x64.tar.xz -C ~/opt/nodejs
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/bin ~/opt/nodejs/bin
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/include ~/opt/nodejs/include
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/lib ~/opt/nodejs/lib
    ln -s ~/opt/nodejs/node-v20.9.0-linux-x64/share ~/opt/nodejs/share

    shell=$(choose_shell "选择初始化NodeJS的Shell")
    if [[ "$shell" == "bash" ]]; then
        file=~/.bashrc
    else
        file=~/.zshrc
    fi
    if ! grep -q "nodejs" "${file}"; then
        # shellcheck disable=SC2016
        echo '
# NodeJS, NPM
export PATH=/home/jack/opt/nodejs/node-v20.9.0-linux-x64/bin:${PATH}' >>"${file}"
    fi

    # root的NodeJS需要重新配置源
    echo "${password}" | sudo -S apt install -y ca-certificates curl gnupg
    echo "${password}" | sudo -S mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    # 安装最新的NodeJS版本为20
    NODE_MAJOR=20
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    echo "${password}" sudo apt-get update
    echo "${password}" sudo apt-get install nodejs -y
}

function init_nginx() {
    echo "=> 正在配置Nginx"

}

function init_rust() {
    echo "=> 正在配置Rust" # arguments are accessible through $1, $2,...
    HTTP_PROXY="http://127.0.0.1:7890" HTTPS_PROXY="http://127.0.0.1:7890" ALL_PROXY="socks5://127.0.0.1:7890" curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    shell=$(choose_shell "选择初始化Rust的Shell")
    if [[ "$shell" == "bash" ]]; then
        file=~/.bashrc
    else
        file=~/.zshrc
    fi
    # shellcheck disable=SC2016
    echo '
# rust
export PATH="$HOME/.cargo/bin:${PATH}"
    ' >>"${file}"
}

function init_yarn() {
    echo "=> 正在配置Yarn"
    npm install --global yarn
}

function init_lunarvim() {
    echo "=> 正在配置LunarVim"
    # 首先配置VIM
    init_vim
    # 先安装依赖neovim
    mkdir -p ~/opt/neovim
    wget -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 -c -P ~/opt/neovim https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz
    tar xzvf ~/opt/neovim/nvim-linux64.tar.gz -C ~/opt/neovim/
    mv ~/opt/neovim/nvim-linux64 ~/opt/neovim/nvim-linux64-9.4.0
    ln -s ~/opt/neovim/nvim-linux64-9.4.0/bin ~/opt/neovim/bin
    ln -s ~/opt/neovim/nvim-linux64-9.4.0/lib ~/opt/neovim/lib
    ln -s ~/opt/neovim/nvim-linux64-9.4.0/man ~/opt/neovim/man
    ln -s ~/opt/neovim/nvim-linux64-9.4.0/share ~/opt/neovim/share
    shell=$(choose_shell "选择初始化NeoVIM的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    if ! (grep -q "neovim" "${rc}"); then
        # shellcheck disable=SC2016
        echo '
# NeoVIM
export PATH=/home/jack/opt/neovim/bin:${PATH}' >>"${rc}"
    fi
    export PATH=/home/jack/opt/neovim/bin:${PATH}
    # 安装 lunarvim
    echo "${password}" | sudo -S apt install -y python-is-python3 python3-pip
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)
    export PATH=${HOME}/.local/bin
    if ! (grep -q "lvim" "${rc}"); then
        # shellcheck disable=SC2016
        echo '
# LunarVIM
export PATH=${HOME}/.local/bin:$PATH
export EDITOR=lvim
alias vim="lvim"
' >>"${rc}"
    fi
    # 安装字体
    git clone https://github.com/ronniedroid/getnf.git
    bash getnf/install.sh
    bash getnf/getnf.sh
    # 卸载lunarvim
    # bash ~/.local/share/lunarvim/lvim/utils/installer/uninstall.sh

    # 安装Lua静态检查工具
    echo "${password}" | sudo -S apt install -y luarocks
    echo "${password}" | sudo -S luarocks install luacheck
    # 安装Lua格式化工具
    cargo install stylua
    # 安装shell检查工具
    echo "${password}" | sudo apt install -y shellcheck
    # 安装typescript格式化工具
    npm install -g prettier
    # 安装python检查工具
    echo "${password}" | sudo apt install -y flake8
    # 安装python格式化工具
    echo "${password}" | sudo -S apt install -y python3-pip python-is-python3
    python -m pip install black
    # 安装C/C++格式化工具
    python -m pip install cpplint
    cp config.lua ~/.config/lvim
}

function init_ssh() {
    echo "=> 正在配置SSH"
}

function init_gptnextweb() {
    echo "=> 正在配置ChatGPT NetWeb"
    # 需要安装全局的nodejs, 需要给全局的nodejs添加源, 在init_nodejs中完成
    input=""
    while [[ "$input" != "w" && "$input" != "a" ]]; do
        read -p "配置网页版/桌面应用版[w/a]: " -r input
    done
    if [[ $input == "w" ]]; then
        echo "=> 正在配置网页版ChatGPT"
        init_yarn
        git clone https://github.com/Yidadaa/ChatGPT-Next-Web.git ~/opt/ChatGPT-Next-Web
        # 安装yarn依赖
        cd ~/opt/ChatGPT-Next-Web && $(which yarn) install
        # 发布网页应用
        read -p "请输入OPENAI_API_KEY: " -r OPENAI_API_KEY
        read -p "请输入访问密码: " -r CODE
        read -p "请输入启动端口: " -r PORT
        OPENAI_API_KEY=$OPENAI_API_KEY CODE=$CODE PORT=$PORT $(which yarn) build
        cd "${dir}" || return
        # 配置开机自启动
        echo "${password}" | sudo -S cp "${dir}"/ChatGPT.service /etc/systemd/system/ChatGPT.service
        echo "${password}" | sudo -S systemctl daemon-reload
        echo "${password}" | sudo -S systemctl enable ChatGPT.service
        echo "${password}" | sudo -S systemctl start ChatGPT.service
    elif [[ $input == 'a' ]]; then
        # TODO: 完成桌面应用版本ChatGPT
        echo "=> 暂时未实现"
    fi
}

function init_qemu() {
    echo "=> 正在配置QEMU"
    echo "${password}" | sudo -S apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git libglib2.0-dev libfdt-dev libpixman-1-dev libncurses5-dev libncursesw5-dev
    mkdir -p ~/opt/qemu
    wget -c -P ~/opt/qemu https://download.qemu.org/qemu-7.2.0.tar.xz
    tar xvJf qemu-7.2.0.tar.xz -C ~/opt/qemu
    cd ~/opt/qemu/qemu-7.2.0 && export PREFIX="${HOME}/opt/qemu"
    cd ~/opt/qemu/qemu-7.2.0 && ./configure --prefix="${PREFIX}" --target-list=riscv64-softmmu,riscv64-linux-user
    make -j$(($(nproc) - 2))
    make install
    shell=$(choose_shell "选择初始化QEMU的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    # shellcheck disable=SC2016
    printf 'export PATH=%s:"${PATH}"' "${PREFIX}"/bin >>"${rc}"
}

function init_riscvtools() {
    echo "=> 正在配置RISCV-Tools"
    mkdir -p ~/opt/riscv-tools
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git ~/opt/riscv-tools/src
    cd ~/opt/riscv-tools/src && git submodule init
    cd ~/opt/riscv-tools/src && git -c submodule.qemu.update=none submodule update --recursive --progress
    echo "${password}" | sudo -S apt install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build
    export PREFIX="${HOME}/opt/riscv-tools"
    cd ~/opt/riscv-tools/src && ./configure --prefix="${PREFIX}" --enable-gdb --enable-gcc-checkin
    make -j$(($(nproc) - 2))
    echo "${password}" | sudo -S apt install -y gdb-multiarch
    shell=$(choose_shell "选择初始化RISCV-Tools的Shell")
    if [[ $shell == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    # shellcheck disable=SC2016
    printf 'export PATH=%s:"${PATH}"' "${PREFIX}"/bin >>"${rc}"
}

function init_miniconda() {
    echo "=> 正在配置Miniconda"
    miniconda_home="${HOME}"/opt/miniconda
    mkdir -p "${miniconda_home}"
    # 下载miniconda
    HTTP_PROXY=127.0.0.1:${proxy_port} HTTPS_PROXY=127.0.0.1:${proxy_port} ALL_PROXY=127.0.0.1:${proxy_port} wget -c -P "${miniconda_home}" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash "${miniconda_home}"/Miniconda3-latest-Linux-x86_64.sh -b -u -p ~/miniconda3
    # 初始化miniconda
    shell=$(choose_shell "选择初始化Miniconda的Shell")
    "${HOME}"/miniconda3/bin/conda init "${shell}"
}

function init_bottom() {
    echo "=> 正在配置Bottom"
    export HTTP_PROXY=127.0.0.1:${proxy_port} HTTPS_PROXY=127.0.0.1:${proxy_port} ALL_PROXY=127.0.0.1:${proxy_port}
    rustup update stable
    cargo install bottom --locked
}

function init_glances() {
    echo "=> 正在配置Glances"
    python -m pip install --user 'glances[all]' -i https://pypi.tuna.tsinghua.edu.cn/simple
    cp "${dir}"/glances.service "${dir}"/glances.service.backup
    sed -i "s,#USERHOME,$HOME,g" glances.service
    cp "${dir}"/glances.sh "${dir}"/glances.sh.backup
    read -p "请输入登录用户名: " -r username
    read -p "请输入登录密码: " -r password
    sed -i "s,#GLANCES,$(which glances),g" glances.sh
    sed -i "s,#USER,${username},g" glances.sh
    sed -i "s,#PASS,${password},g" glances.sh
    echo "${password}" | sudo -S cp "${dir}"/glances.service /etc/systemd/system
    echo "${password}" | sudo -S systemctl daemon-reload
    echo "${password}" | sudo -S systemctl enable glances.service
    echo "${password}" | sudo -S systemctl start glances.service
}

function init_zoxide() {
    echo "=> 正在配置Zoxide"
    export HTTP_PROXY=127.0.0.1:${proxy_port} HTTPS_PROXY=127.0.0.1:${proxy_port} ALL_PROXY=127.0.0.1:${proxy_port}
    shell=$(choose_shell "选择初始化Zoxide的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    echo "
# Zoxide
eval '\$(zoxide init \"${shell}\" --cmd cd)'
" >>"${rc}"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
}

function init_bat() {
    echo "=> 正在配置Bat"
    export HTTP_PROXY=127.0.0.1:${proxy_port} HTTPS_PROXY=127.0.0.1:${proxy_port} ALL_PROXY=127.0.0.1:${proxy_port}
    # 安装bat
    cargo install --locked bat

    shell=$(choose_shell "选择初始化Zoxide的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    echo "
# Bat
export BAT_CONFIG_PATH=${HOME}/.config/bat.conf
export MANPAGER=\"sh -c 'col -bx | bat -l man -p'\"
alias fzf="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    " >>"${rc}"
    cp "${dir}"/bat.conf ~/.config
    # bat-extras安装
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
    git clone https://github.com/eth-p/bat-extras.git ~/projects/bat-extras
    ~/projects/bat-extras/build.sh --install --prefix="${HOME}/opt/bat-extras"
    echo "
# Bat-extras
export MANPATH=$(manpath -g):/home/jack/opt/bat-extras/share/man
    " >>"${rc}"
    # shellcheck disable=SC2016
    echo 'export PATH=${HOME}/opt/bat-extras/bin:${PATH}' >>"${rc}"
}

function init_go() {
    echo "=> 正在配置Go"
    go_home=${HOME}/opt/go
    mkdir -p "${go_home}"
    wget -e "http_proxy=127.0.0.1:${proxy_port}" -e "https_proxy=127.0.0.1:${proxy_port}" -P "$go_home" -c https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
    echo "$password" | sudo -S sudo rm -rf /usr/local/go
    echo "$password" | sudo -S tar -C /usr/local -xzf "${go_home}"/go1.21.4.linux-amd64.tar.gz
    shell=$(choose_shell "选择初始化Zoxide的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    # shellcheck disable=SC2016
    echo 'export PATH=${PATH}:/usr/local/go/bin' >>"${rc}"
}

function init_eza() {
    echo "=> 正在配置eza"
    export HTTP_PROXY=127.0.0.1:${proxy_port} HTTPS_PROXY=127.0.0.1:${proxy_port} ALL_PROXY=127.0.0.1:${proxy_port}
    eza_home="${HOME}/opt/eza"
    mkdir -p "${eza_home}"
    cargo install eza
    shell=$(choose_shell "选择初始化Zoxide的Shell")
    if [[ "$shell" == "bash" ]]; then
        rc=~/.bashrc
    else
        rc=~/.zshrc
    fi
    clear
    echo "
# eza
alias ls=\"eza --icons\"          # 默认显示 icons
alias ll=\"eza --icons --long --header\"    # 显示文件目录详情
alias la=\"eza --icons --long --header --all\"      # 显示全部文件目录，包括隐藏文件
alias lg=\"eza --icons --long --header --all --git\"      # 显示详情的同时，附带 git 状态信息
alias tree=\"eza --tree --icons\"   # 替换 tree 命令
    " >>${rc}
    git clone https://github.com/eza-community/eza.git "${eza_home}"
    # shellcheck disable=SC2016
    echo 'export FPATH="'"${eza_home}"'/completions/zsh:$FPATH"' >>~/.zshrc
}

function init_fd() {
    echo "=> 正在配置fd"
    cargo install fd-find
}

function init_ripgrep() {
    echo "=> 正在配置ripgrep"
    cargo install ripgrep
}

function init_todo() {
    echo "=> 正在初始化todo.sh"
    todo_home="${HOME}/opt/todo"
    mkdir -p "${todo_home}"

    wget -e "http_proxy=127.0.0.1:${proxy_port}" -e "https_proxy=127.0.0.1:${proxy_port}" -P "${todo_home}" -c https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz
    tar xzvf "${todo_home}/todo.txt_cli-2.12.0.tar.gz" -C "${todo_home}"
    # 安装可执行文件
    mkdir -p "${todo_home}"/bin
    mv "${todo_home}"/todo.txt_cli-2.12.0/todo.sh "${todo_home}"/bin
    # 配置
    mkdir -p "${HOME}"/.todo
    mv "${todo_home}"/todo.txt_cli-2.12.0/todo.cfg "${HOME}"/.todo/config
    # shellcheck disable=SC2016
    sed -i '1s/export TODO_DIR=$(dirname "$0")/export TODO_DIR="\/home\/jack\/opt\/todo\/bin\/"/' "${HOME}"/.todo/config
    # 命令行配置
    shell=$(choose_shell "选择初始化todo的Shell")
    if [[ "$shell" == "bash" ]]; then
        file=~/.bashrc
    else
        file=~/.zshrc
    fi
    # shellcheck disable=SC2140
    echo "
# todo
export PATH=\${PATH}:${todo_home}/bin
alias todo="todo.sh"
" >>"${rc}"
}

function init_typora() {
    echo "=> 正在配置Typora"
}

# 展示系统信息
lsb_info=$(lsb_release -idcr 2>/dev/null)
dialog --title "系统信息" --msgbox "$lsb_info" 20 60

# 主循环
# TODO: 自动扫描代理端口, 或者用户手动添加代理地址
while true; do
    # 使用dialog创建菜单
    choice=$(
        dialog --menu "选择一个选项：" 30 50 20 \
            1 "退出" \
            2 "换源USTC" \
            3 "配置Clash" \
            4 "配置Qv2ray" \
            5 "配置ZSH" \
            6 "配置TMUX" \
            7 "配置FRP" \
            8 "配置NodeJS" \
            9 "配置Rust" \
            10 "配置VIM" \
            11 "配置LunarVIM" \
            12 "配置QEMU" \
            13 "配置RISCV-Tools" \
            14 "配置Miniconda" \
            15 "配置Bottom" \
            16 "配置Glances" \
            17 "配置Zoxide" \
            18 "配置Bat" \
            19 "配置Go" \
            20 "配置eza" \
            21 "配置fd" \
            22 "配置ripgrep" \
            23 "配置todo" \
            2>&1 >/dev/tty
    )
    clear
    # 根据用户的选择执行相应的操作
    case $choice in
    1 | 255)
        break # 退出循环，结束应用
        ;;
    2)
        change_source
        ;;
    3)
        init_clash
        ;;
    4)
        init_qv2ray
        ;;
    5)
        init_zsh
        ;;
    6)
        init_tmux
        ;;
    7)
        init_frp
        ;;
    8)
        init_nodejs
        ;;
    9)
        init_rust
        ;;
    10)
        init_vim
        ;;
    11)
        init_lunarvim
        ;;
    12)
        init_qemu
        ;;
    13)
        init_riscvtools
        ;;
    14)
        init_miniconda
        ;;
    15)
        init_bottom
        ;;
    16)
        init_glances
        ;;
    17)
        init_zoxide
        ;;
    18)
        init_bat
        ;;
    19)
        init_go
        ;;
    20)
        init_eza
        ;;
    21)
        init_fd
        ;;
    22)
        init_ripgrep
        ;;
    23)
        init_todo
        ;;
    *)
        echo "无效的选项"
        ;;
    esac

done
info="记得运行 source ~/.zshrc 或者 source ~/.bashrc 来让配置生效 \n开始享受Ubuntu吧 :)"
dialog --title "信息" --msgbox "$info" 20 60
clear
