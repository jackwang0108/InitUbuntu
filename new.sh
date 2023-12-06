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

# Command Line Options
isTUI="False"
isInteractive="False"
isDependency="False"

# Dependencies
isGit=$(whereis git | awk -F ' ' '/(?!man)/{print $2}')
isVim=$(whereis vim | awk -F ' ' '/(?!man)/{print $2}')
isTar=$(whereis tar | awk -F ' ' '/(?!man)/{print $2}')
isUnzip=$(whereis unzip | awk -F ' ' '/(?!man)/{print $2}')
isWget=$(whereis wget | awk -F ' ' '/(?!man)/{print $2}')
isCurl=$(whereis curl | awk -F ' ' '/(?!man)/{print $2}')
isDialog=$(whereis dialog | awk -F ' ' '/(?!man)/{print $2}')

# Color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
WHITE=$(tput setaf 7)
# Style
BOLD=$(tput bold)
NORMAL=""
DIM=$(tput dim)
# Normal
RESET=$(tput sgr0)

# Init Tools
mlen=0
functions_to_run=()
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
done <"$dir/new.sh"

# ============================= Helper Functions =============================

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

# shellcheck disable=SC2120
function show_menu() {
    choices=()
    if [[ $isTUI == "True" ]]; then
        # shellcheck disable=SC2086
        while true; do
            menu_content=$(
                for index in "${!init_functions[@]}"; do
                    for i in "${functions_to_run[@]}"; do
                        if [[ $i == "$index" ]]; then
                            continue 2
                        fi
                    done
                    echo "${index} ${init_functions[$index]#init_}"
                done
            )
            if [[ -n $menu_content ]]; then
                dialog --title "InitUbuntu" --ok-label "Add" --cancel-label "Start" --menu "Add a tool to installation list: " 30 50 20 ${menu_content} 2>"${dir}/menuchoice"
                menu_status=$?
            else
                menu_status=1
            fi
            choice=$(cat "${dir}/menuchoice")
            rm "${dir}/menuchoice"
            if [ $menu_status -eq 0 ]; then
                functions_to_run+=("$choice")
            elif [ $menu_status -eq 1 ]; then
                msg=$(
                    for index in "${functions_to_run[@]}"; do
                        printf "\t%02d %s\n" $index ${init_functions[$index]#init_}
                    done
                )
                dialog --title "Tools to be installed" --msgbox "${msg}" 30 50
                break
            fi
        done
        clear
    elif [[ $isInteractive == "True" ]]; then
        for i in "${!init_functions[@]}"; do
            printf "%02d) %-${mlen}s\n" "$((i))" "${init_functions[$i]}"
        done | pr -o 8 -3 -t -w "$(tput cols)"
        while true; do
            read -r -p "${BLUE}Select a tool to install (e.g. 0,1,2 or 1-3 or 1,3-5): ${GREEN}" choices && echo -n "${RESET}"
            # Handler user input
            for choice in $(echo "$choices" | tr ',' ' '); do
                if [[ $choice == *-* ]]; then
                    # parse range, e.g. 1-3
                    if ! [[ $choice =~ ^[0-9]+-[0-9]$ ]]; then
                        ilog "Invalid input format: $1. Expected format: X-Y" "${BOLD}" "${YELLOW}"
                    fi
                    IFS='-' read -ra range <<<"$choice"
                    range_start=${range[0]}
                    range_end=${range[1]}
                    for ((i = range_start; i <= range_end; i++)); do
                        if ((0 <= i && i <= ${#init_functions[@]})); then
                            functions_to_run+=("$i")
                        fi
                    done
                elif ((0 <= choice && choice <= ${#init_functions[@]})); then
                    # parse number, e.g. 5
                    functions_to_run+=("$choice")
                else
                    # out of range, e.g. 1000
                    ilog "Invalid Option: $choice. Try again." "${BOLD}" "${YELLOW}"
                    continue 2
                fi
            done
            echo "Tools to be installed: "
            for index in "${functions_to_run[@]}"; do
                printf "\t%02d %s\n" "$index" "${init_functions[$index]#init_}"
            done
            break
        done
    fi
    echo "$choice"
}

function usage() {
    echo "initUbuntu: A ${BOLD}${GREEN}Better${RESET} way to initialize your Ubuntu"
    echo ""
    echo "Usage:"
    echo "    ${BLUE}-h${RESET} print this help message and exit"
    echo "    ${BLUE}-d${RESET} install all dependencies"
    echo "    ${BLUE}-t${RESET} use TUI to initialize your ubuntu"
    echo "    ${BLUE}-i${RESET} interactive install selected tools. Available tools are:"
    for i in "${!init_functions[@]}"; do
        printf "%02d) %-${mlen}s\n" "$((i + 1))" "${init_functions[$i]}"
    done | pr -o 8 -3 -t -w "$(($(tput cols) - 75))"
    echo ""
    # shellcheck disable=SC2016
    echo 'By default, you can use `initUbuntu -i [tools]` to install single tools you'\''d like to use'
    # shellcheck disable=SC2016
    echo 'or you can use `initUbuntu -t` to run text-based UI (dependency dialog is needed)'
}

# Set flags
_opt=""
while getopts "hitd" option; do
    case "$option" in
    h) usage && exit "$exitSucc" ;;
    d) _opt="True" isDependency="True" || exit "$exitFail" ;;
    t) _opt="True" isTUI="True" || exit "$exitFail" ;;
    i) _opt="True" isInteractive="True" || exit "$exitFail" ;;
    ?) usage && exit "$exitSucc" ;;
    esac
done
[[ -z "$_opt" ]] && usage && exit "$exitFail"

# check denpendencies
if [[ $isDependency != "True" ]]; then
    [[ -z $isGit ]] && ilog "Dependency git is not installed on your system. Use -d option to install dependencies"
    [[ -z $isTar ]] && ilog "Dependency tar is not installed on your system. Use -d option to install dependencies"
    [[ -z $isVim ]] && ilog "Dependency vim is not installed on your system. Use -d option to install dependencies"
    [[ -z $isUnzip ]] && ilog "Dependency unzip is not installed on your system. Use -d option to install dependencies"
    [[ -z $isWget ]] && ilog "Dependency wget is not installed on your system. Use -d option to install dependencies"
    [[ -z $isCurl ]] && ilog "Dependency curl is not installed on your system. Use -d option to install dependencies"
    [[ -z $isDialog ]] && ilog "Dependency dialog is not installed on your system. Use -d option to install dependencies"
fi

# ============================= init Functions =============================
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
    [[ -n $tools ]] && msg="Dependencies to be installed: ${tools}" || msg="All dependencies are installed. Nothing to do"
    ilog "$msg" "${NORMAL}" "${BLUE}"
    sleep 3s
    # shellcheck disable=SC2086
    echo "$PASS" | sudo -S apt install -y ${tools}
}

function init_test() {
    echo "=> init_test"
}

function init_test1() {
    echo "=> init_test1"
}

function init_test2() {
    echo "=> init_test2"
}

# Show menu and get user input
show_menu

# TODO: 添加main函数, 实现依赖安装, 同时添加别的函数
for index in "${functions_to_run[@]}"; do
    printf "\t%02d %s\n" "$index" "${init_functions[$index]#init_}"
    ${init_functions[$index]}
done

function main() {
    # Read Password
    read -r -s -p "${BOLD}${GREEN}[initUbuntu]${RESET} Please enter password for $USER: ${RESET}" PASS && echo ""
    # Check SUDO privilege
    (echo "$PASS" | sudo -S -l -U "$USER" | grep -q 'may run the following') ||
        (ilog "initUbuntu needs SUDO privilege to run. Make sure you have it." "$BOLD" "$RED" && exit 1)
    if [[ $isDependency == "True" ]]; then
        install_dependency
    fi
}

main
