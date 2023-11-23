#!/bin/bash

# 获取密码
read -p "请输入用户密码: " -r -s password && echo ""
# 测试是否为sudo用户
if echo "${password}" | sudo -S -n true 2>/dev/null; then
    echo ""
else
    echo "当前用户非SUDO用户"
    exit 1
fi

# 安装必要工具
echo "${password}" | sudo -S apt install curl dialog

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

    if ! grep -q "nodejs" ~/.zshrc; then
        # shellcheck disable=SC2016
        echo '
# NodeJS, NPM
export PATH=/home/jack/opt/nodejs/node-v20.9.0-linux-x64/bin:${PATH}' >>~/.zshrc
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
    # shellcheck disable=SC2016
    echo '
# rust
export PATH="$HOME/.cargo/bin:${PATH}"
    ' >>~/.zshrc
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
    if ! (grep -q "neovim" ~/.zshrc); then
        # shellcheck disable=SC2016
        echo '
# NeoVIM
export PATH=/home/jack/opt/neovim/bin:${PATH}' >>~/.zshrc
    fi
    export PATH=/home/jack/opt/neovim/bin:${PATH}
    # 安装 lunarvim
    echo "${password}" | sudo -S apt install python-is-python3 python3-pip
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)
    export PATH=${HOME}/.local/bin
    if ! (grep -q "lvim" ~/.zshrc); then
        # shellcheck disable=SC2016
        echo '
# LunarVIM
export PATH=${HOME}/.local/bin:$PATH
export EDITOR=lvim
alias vim="lvim"
' >>~/.zshrc
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
    # shellcheck disable=SC2016
    printf 'PATH=$PATH:%s' "${PREFIX}"/bin >>~/.zshrc
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
    # shellcheck disable=SC2016
    printf 'PATH=$PATH:%s' "${PREFIX}"/bin >>~/.zshrc
    echo "${password}" | sudo -S apt install -y gdb-multiarch
}

# 主循环
# TODO: 自动扫描代理端口, 或者用户手动添加代理地址
while true; do
    # 使用dialog创建菜单
    choice=$(
        dialog --menu "选择一个选项：" 30 50 5 \
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
            2>&1 >/dev/tty
    )
    clear
    # 根据用户的选择执行相应的操作
    case $choice in
    1)
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
    *)
        echo "无效的选项"
        ;;
    esac

done

echo "Don't forget to source your ~/.zshrc to make everthing effective"
echo "Have a good day and enjoy your Ubuntu :)"
