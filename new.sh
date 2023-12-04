#! /bin/env bash

# Define Global Variable
dir=$(dirname "$(readlink -f "$0")")
exitFail=1
exitSucc=0

os=$(uname)
sysarch=$(arch)
if [[ "$os" == 'Darwin' ]]; then
    log "Darwin is not supported now" "$BOLD" "$RED"
fi

# Dependencies
isGit=$(whereis git | awk -F ' ' '{print $2}')
isVim=$(whereis vim | awk -F ' ' '{print $2}')
isTar=$(whereis tar | awk -F ' ' '{print $2}')
isUnzip=$(whereis unzip | awk -F ' ' '{print $2}')
isWget=$(whereis wget | awk -F ' ' '{print $2}')
isCurl=$(whereis curl | awk -F ' ' '{print $2}')
isDialog=$(whereis dialog | awk -F ' ' '{print $2}')

# Color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
WHITE=$(tput setaf 7)
# Style
BOLD=$(tput bold)
DIM=$(tput dim)
# Normal
RESET=$(tput sgr0)

# Init Tools
mlen=0
init_functions=()
while IFS= read -r line; do
    if [[ $line =~ ^function\ init.* ]]; then
        function_name=$(echo "$line" | awk '{print $2}' | sed 's/()//')
        init_functions+=("$function_name")
        len=${#function_name}
        if ((len > mlen)); then
            mlen=$len
        fi
    fi
done <"$dir/init.sh"

# Check SUDO privilege
read -r -s -p "[initUbuntu] Please enter password for $USER: " PASS && echo ""
echo "$PASS" | sudo -S -l -U "$USER" | grep -q 'may run the following' ||
    (ilog "initUbuntu needs SUDO privilege to run. Make sure you have it." "$BOLD" "$RED" && exit 1)

# ilog() - Print log messages with style and color to the terminal
#
# This function is used to print log messages with style and color to the terminal. You can specify the style and color of the message, or use the default values if not provided.
#
# Parameters:
#     msg   - The log message to be printed
#     style - (optional) The style of the message. Default is null (no style)
#     color - (optional) The color of the message. Default is null (no color)
#
# Examples:
#     ilog "This is a normal log message."
#     ilog "This is a warning message." $BOLD $YELLOW
#     ilog "This is an error message." $BOLD $RED
function ilog() {
    local msg=$1
    local style=$2
    local color=$3
    echo "${style:-$RESET}${color:-$WHITE}${msg}${RESET}"
}

function usage() {
    echo "initUbuntu: A ${BOLD}${GREEN}Better${RESET} way to initialize your Ubuntu"
    echo ""
    echo "Usage:"
    echo "    ${BLUE}-h${RESET} print this help message and exit"
    echo "    ${BLUE}-d${RESET} install all dependencies"
    echo "    ${BLUE}-t${RESET} use TUI to initialize your ubuntu"
    echo "    ${BLUE}-i${RESET} select tool you want to install. Available tools are:"
    for i in "${!init_functions[@]}"; do
        printf "%02d) %-${mlen}s\n" "$((i + 1))" "${init_functions[$i]}"
    done | pr -o 8 -3 -t -w "$(($(tput cols) - 75))"
    echo ""
    # shellcheck disable=SC2016
    echo 'By default, you can use `initUbuntu -i [tools]` to install single tools you'\''d like to use'
    # shellcheck disable=SC2016
    echo 'or you can use `initUbuntu -t` to run text-based UI (dependency dialog is needed)'
}

function change_source() {
    echo "=> 正在换源"
    # 版本代号
    code_name=$(lsb_release -cs)
    # 中科大源
    ustc_source="
# 中科大源
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
    echo "${PASS}" | sudo -S cp /etc/apt/sources.list /etc/apt/sources.list.backup-"$(date +%Y.%m.%d.%S)"
    # 设置新源
    echo "$ustc_source" >temp && (echo "${PASS}" | sudo -S cp temp /etc/apt/sources.list) && rm temp

    # 更新
    echo "${PASS}" | sudo -S apt update
    echo "${PASS}" | sudo -S apt upgrade -y
}

function install_dependency() {
    ilog "=> Installing dependencies" "$BOLD" "$GREEN"
    tools=""
    [[ -z $isGit ]] && tools="$tools git"
    [[ -z $isVim ]] && tools="$tools vim"
    [[ -z $isTar ]] && tools="$tools tar"
    [[ -z $isUnzip ]] && tools="$tools unzip"
    [[ -z $isWget ]] && tools="$tools wget"
    [[ -z $isCurl ]] && tools="$tools curl"
    [[ -z $isDialog ]] && tools="$tools dialog"
    echo "$tools"
}

# Set flags
while getopts :hitd option; do
    case "$option" in
    h) usage && exit "$exitSucc" ;;
    d) install_dependency || exit "$exitSucc" ;;
    t) ilog "Not implemented yet" && exit "$exitFail" ;;
    i) ilog "Not implemented yet" && exit "$exitFail" ;;
    *) usage && exit "$exitSucc" ;;
    esac
done

# check denpendencies
[[ -z $isGit ]] && ilog "Dependency git is not installed on your system. Use -d option to install dependencies"
[[ -z $isTar ]] && ilog "Dependency tar is not installed on your system. Use -d option to install dependencies"
[[ -z $isVim ]] && ilog "Dependency vim is not installed on your system. Use -d option to install dependencies"
[[ -z $isUnzip ]] && ilog "Dependency unzip is not installed on your system. Use -d option to install dependencies"
[[ -z $isWget ]] && ilog "Dependency wget is not installed on your system. Use -d option to install dependencies"
[[ -z $isCurl ]] && ilog "Dependency curl is not installed on your system. Use -d option to install dependencies"
[[ -z $isDialog ]] && ilog "Dependency dialog is not installed on your system. Use -d option to install dependencies"
