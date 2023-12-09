#! /bin/env bash

# Configuration Variables. You may modify them to your own setting
# Proxy Port
PORT=7890

# ================================ Scripts ================================
# Define Global Variable
rc="False"
dir=$(dirname "$(readlink -f "$0")")
cleaned="False"
exitFail=1
exitSucc=0

os=$(uname)
sysarch=$(arch)
if [[ "$os" == 'Darwin' ]]; then
    log "Darwin is not supported now" "$BOLD" "$RED"
fi

# Command Line Options
isTUI="False"
isForce="False"
isInteractive="False"
isDependency="False"
isChangeSource="False"

# Dependencies
isGit=$(whereis git | awk -F ' ' '{print $2}' | grep -v "man")
isVim=$(whereis vim | awk -F ' ' '{print $2}' | grep -v "man")
isTar=$(whereis tar | awk -F ' ' '{print $2}' | grep -v "man")
isUnzip=$(whereis unzip | awk -F ' ' '{print $2}' | grep -v "man")
isGzip=$(whereis gzip | awk -F ' ' '{print $2}' | grep -v "man")
isWget=$(whereis wget | awk -F ' ' '{print $2}' | grep -v "man")
isCurl=$(whereis curl | awk -F ' ' '{print $2}' | grep -v "man")
isDialog=$(whereis dialog | awk -F ' ' '{print $2}' | grep -v "man")

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

# proxy_on - Set proxy environment variables
#
# This function sets the HTTP_PROXY, HTTPS_PROXY, and ALL_PROXY environment variables
# to the localhost on PORT.
#
# Parameters:
#   None
#
# Example:
#   proxy_on
function proxy_on() {
    export HTTP_PROXY=http://127.0.0.1:${PORT}
    export HTTPS_PROXY=http://127.0.0.1:${PORT}
    export ALL_PROXY=socks5://127.0.0.1:${PORT}
    git config --global https.proxy http://127.0.0.1:${PORT}
    git config --global https.proxy https://127.0.0.1:${PORT}
    alias wget='wget -e http_proxy=127.0.0.1:${PORT} -e https_proxy=127.0.0.1:${PORT}'
}

# proxy_off - Unset proxy environment variables
#
# This function unsets the HTTP_PROXY, HTTPS_PROXY, and ALL_PROXY environment variables.
#
# Parameters:
#   None
#
# Example:
#   proxy_off
function proxy_off() {
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    [[ $(type wget) =~ "alias" ]] && unalias wget
}

# git_clone - Clone git repository and give error
#
# This function clones a Git repository from a specified URL to a specified directory.
#
# Parameters:
#   $1 - The URL of the Git repository to clone.
#   $2 - The directory where the repository will be cloned into.
#
# Example:
#   git_clone "https://github.com/example/repo.git" "/path/to/clone"
#
# Returns:
#   0 - If the cloning process is successful.
#   1 - If the cloning process fails, possibly due to a proxy issue.
function git_clone() {
    local _url=$1
    local _dir=$2
    local _rname=""
    _rname=$(basename "$1")
    ilog "${RESET}git clone ${GREEN}${_rname}${RESET} to ${_dir}"
    if ! git clone --depth=1 "$_url" "$_dir"; then
        ilog "git clone failed! This may because your proxy didn't work. Change to another proxy node and try again!" "${BOLD}" "${RED}"
        return 1
    fi
    return 0
}

# show_menu() - Displays a menu and prompts the user to select tools.
#
# The function supports both TUI (Text-based User Interface) and interactive modes.
# The index of init_functions of selected tools will be stored in functions_to_run variable
#
# Parameters:
#   None
#
# Example:
#   show_menu
#   # Run init functions
#   for index in "${functions_to_run[@]}"; do
#       printf "Running %s\n" "${init_functions[$index]}"
#       ${init_functions[$index]}
#   done
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
                printf "%s\n" "${init_functions[$index]#init_}"
            done | pr -o 8 -3 -t -w "$(tput cols)"
            break
        done
    fi
}

function usage() {
    echo "initUbuntu: A ${BOLD}${GREEN}Better${RESET} way to initialize your Ubuntu"
    echo ""
    echo "Usage:"
    echo "    ${BLUE}-h${RESET} print this help message and exit"
    echo "    ${BLUE}-d${RESET} install all dependencies"
    echo "    ${BLUE}-f${RESET} force  reinitialize the tool"
    echo "    ${BLUE}-c${RESET} change source from given sources"
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

# get_shell_rc - Get the runtime configuration (rc) of given shell.
#
# This function is used to get the path of the selected shell configuration file.
#
# Parameters:
#   None
#
# Returns:
#   The path of the selected shell configuration file.
#
# Example:
#   get_shell_rc
#   echo "Shell configuration file path: $rc"
function get_shell_rc() {
    all_shell=("bash" "zsh")
    for i in "${!all_shell[@]}"; do
        printf "%02d) %s\n" "$((i))" "${all_shell[$i]}"
    done | pr -o 8 -3 -t -w "$(tput cols)"
    while true; do
        read -r -p "${BLUE}Select a shell to add configure (e.g. 0): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please select a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#all_shell[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#all_shell[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            rc="${HOME}"/.${all_shell[$choice]}rc
            break
        fi
    done
}

# systemd_add - Add a unit file to systemd service and start it
#
# This function adds a unit file to the systemd service by copying it to /etc/systemd/system/,
# reloads the systemd daemon, enables the service to start on boot, and starts the service.
# It also checks the status of the service and returns "True" if the service is active, and "False" otherwise.
#
# Parameters:
#   $1 - The path to the unit file to be added.
#
# Example:
#   systemd_add "${HOME}/opt/clash/clash.service"
function systemd_add() {
    _unit_file=$1
    _unit_name=$(basename "$_unit_file")
    # Add to systemd
    ilog "Add $_unit_name to systemd service" "${NORMAL}" "${GREEN}"
    echo "$PASS" | sudo -S cp "$_unit_file" /etc/systemd/system/
    echo "$PASS" | sudo -S systemctl daemon-reload
    echo "$PASS" | sudo -S systemctl enable "$_unit_name"
    echo "$PASS" | sudo -S systemctl start "$_unit_name"

    # Check Status
    status=$(systemctl status "$_unit_name" --no-pager)
    if [[ $status =~ "Active: active" ]]; then
        return 0
    else
        return 1
    fi
}

# systemd_remove - Remove a systemd service unit
#
# This function removes a systemd service unit by stopping the service, disabling it from starting on boot,
# and checking the status to confirm the removal.
#
# Parameters:
#   $1 - The name of the systemd service unit to be removed.
#
# Example:
#   systemd_remove clash.service
function systemd_remove() {
    _unit_name=$1
    # Remove from systemd
    ilog "Removing systemd service unit: $_unit_name" "${NORMAL}" "${GREEN}"
    echo "$PASS" | sudo -S systemctl stop "$_unit_name"
    echo "$PASS" | sudo -S systemctl disable "$_unit_name"
    echo "$PASS" | sudo -S rm /etc/systemd/system/"$_unit_name"
    echo "$PASS" | sudo -S systemctl daemon-reload

    # Check Status
    status=$(systemctl status "$_name" --no-pager)
    if [[ $status =~ "Active: inactive" ]] || [[ $status =~ "could not be found" ]]; then
        return 0
    else
        return 1
    fi
}

# cleanup - Cleans up an initialized tool's process and its associated files.
#
# This function is used to clean up an initialized tool's process and its associated files.
# It provides the option to force cleanup even if the -f command line option isn't specified.
#
# Parameters:
#   _name - The name of the tool to clean up.
#   _home - The path to the associated files of the process.
#   _systemd - (Optional) The name of the systemd unit for the process. Defaults to "False".
#   _pname - (Optional) The name of the process to kill. Defaults to "False".
#
# Returns:
#   The cleanup status, either "True" or "False".
#
# Example:
#   cleanup "clash" "${HOME}/opt/clash" "clash.service"
#
function cleanup() {
    _name=$1
    _home=$2
    _systemd="${3:-"False"}"
    _pname=${4:-"False"}
    _force="False"
    # check if already initialized
    if [[ -d $_home ]]; then
        if [[ $isForce == "True" ]]; then
            _force="True"
        else
            while true; do
                read -r -p "${YELLOW}$_name is already initialized, reinitialize? [y/n]: ${GREEN}" choice && echo -n "${RESET}"
                if [[ ${choice^^} == "Y" ]]; then
                    _force="True"
                    break
                elif [[ ${choice^^} == "N" ]]; then
                    _force="False"
                    break
                else
                    ilog "Invalid option: ${choice}, please input [y/n]" "${NORMAL}" "${YELLOW}"
                fi
            done
        fi
    fi
    # cleanup
    if [[ $_force == "True" ]]; then
        ilog "Cleaning $_name" "${NORMAL}" "${YELLOW}"
        # stop systemd unit
        if [[ $_systemd != "False" ]]; then
            if systemd_remove "$_systemd"; then
                ilog "Remove systemd service $_systemd success" "${NORMAL}" "${NORMAL}"
            else
                ilog "Remove systemd service $_systemd fail" "${NORMAL}" "${NORMAL}"
            fi
        fi
        # kill process
        if [[ $_pname != "False" ]]; then
            ilog "Killing process: $_pname" "${NORMAL}" "${NORMAL}"
            echo "$PASS" | sudo -S killall -q "$_pname"
        fi
        # remove files
        ilog "Removing files: $_home" "${NORMAL}" "${NORMAL}"
        echo "$PASS" | sudo -S rm -rf "$_home"
        ilog "$_name is successfully removed" "${NORMAL}" "${GREEN}"
        cleaned="True"
    else
        ilog "Nothing changed" "${NORMAL}" "${YELLOW}"
        cleaned="False"
    fi
}

# Set flags
_opt=""
while getopts "hitdcf" option; do
    case "$option" in
    h) usage && exit "$exitSucc" ;;
    d) _opt="True" isDependency="True" || exit "$exitFail" ;;
    c) _opt="True" isChangeSource="True" || exit "$exitFail" ;;
    f) _opt="True" isForce="True" || exit $exitFail ;;
    t) _opt="True" isTUI="True" || exit "$exitFail" ;;
    i) _opt="True" isInteractive="True" || exit "$exitFail" ;;
    ?) usage && exit "$exitSucc" ;;
    esac
done
[[ -z "$_opt" ]] && usage && exit "$exitFail"

# check denpendencies
if [[ $isDependency != "True" ]]; then
    _not_ok="False"
    [[ -z $isGit ]] && _not_ok="True" ilog "Dependency git is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isTar ]] && _not_ok="True" ilog "Dependency tar is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isVim ]] && _not_ok="True" ilog "Dependency vim is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isUnzip ]] && _not_ok="True" ilog "Dependency unzip is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isGzip ]] && _not_ok="True" ilog "Dependency gzip is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isWget ]] && _not_ok="True" ilog "Dependency wget is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isCurl ]] && _not_ok="True" ilog "Dependency curl is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    [[ -z $isDialog ]] && _not_ok="True" ilog "Dependency dialog is not installed on your system. Use -d option to install dependencies" "${BOLD}" "${RED}"
    if [[ $_not_ok == "True" ]]; then
        ilog "Dependcies are not installed, exit." "${BOLD}" "${RED}"
        exit "$exitFail"
    fi
fi

# ============================= init Functions =============================
function change_source() {
    ilog "=> Changing apt source" "$BOLD" "$GREEN"
    release_name=$(lsb_release -cs)
    all_sources=()
    for file in "${dir}"/*\.source; do
        _file=$(basename "$file")
        all_sources+=("${_file/\.source/}")
    done
    for i in "${!all_sources[@]}"; do
        printf "%02d) %s\n" "$((i))" "${all_sources[$i]}"
    done | pr -o 8 -3 -t -w "$(tput cols)"
    while true; do
        read -r -p "${BLUE}Select a source you want to use (e.g. 1 or 2): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please select a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#all_sources[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#all_sources[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            source_file="${dir}/${all_sources[$choice]}.source"
            break
        fi
    done
    # Backup and set new source
    echo "$PASS" | sudo -S cp /etc/apt/sources.list /etc/apt/sources.list.backup-"$(date +%Y.%m.%d.%S)"
    sed "s/\${release_name}/${release_name}/g" "${source_file}" >>"${dir}/temp"
    echo "$PASS" | sudo -S mv temp /etc/apt/sources.list

    # Update use new source
    echo "$PASS" | sudo -S apt update
    echo "$PASS" | sudo -S apt upgrade -y
}

function install_dependency() {
    ilog "=> Installing dependencies" "$BOLD" "$GREEN"
    tools=""
    [[ -z $isGit ]] && tools="$tools git"
    [[ -z $isVim ]] && tools="$tools vim"
    [[ -z $isTar ]] && tools="$tools tar"
    [[ -z $isUnzip ]] && tools="$tools unzip"
    [[ -z $isGzip ]] && tools="$tools gzip"
    [[ -z $isWget ]] && tools="$tools wget"
    [[ -z $isCurl ]] && tools="$tools curl"
    [[ -z $isDialog ]] && tools="$tools dialog"
    [[ -n $tools ]] && msg="Dependencies to be installed: ${tools}" || msg="All dependencies are installed. Nothing to do"
    ilog "$msg" "${NORMAL}" "${BLUE}"
    sleep 3s
    # shellcheck disable=SC2086
    echo "$PASS" | sudo -S apt install -y ${tools}
}

function add_proxy() {
    ilog "Add proxy_on and proxy_off to shell runtime configuration (rc)" "${NORMAL}" "${GREEN}"
    get_shell_rc
    # Add proxy_on
    if ! grep -q "function proxy_on" "$rc"; then
        echo "
function proxy_on() {
    echo \"Terminal Proxy is turned \$(tput setaf 2)\$(tput bold)ON\$(tput sgr0)\"
    export HTTP_PROXY=http://127.0.0.1:${PORT}
    export HTTPS_PROXY=http://127.0.0.1:${PORT}
    export ALL_PROXY=socks://127.0.0.1:${PORT}
    git config --global https.proxy http://127.0.0.1:${PORT}
    git config --global https.proxy https://127.0.0.1:${PORT}
    alias wget=\"wget -e http_proxy=127.0.0.1:${PORT} -e https_proxy=127.0.0.1:${PORT}\"
}" >>"$rc"
    fi
    # Add proxy_off
    if ! grep -q "function proxy_off" "${rc}"; then
        echo "
function proxy_off() {
    echo \"Terminal Proxy is turned \$(tput setaf 3)\$(tput bold)OFF\$(tput sgr0)\"
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    unalias wget
}" >>"${rc}"
    fi
    # Add proxy_test
    if ! grep -q "function proxy_test" "${rc}"; then
        echo "
function proxy_test() {
    if [[ -z \$HTTP_PROXY ]] || [[ -z \$HTTPS_PROXY ]] || [[ -z \$ALL_PROXY ]]; then
        echo \"Terminal Proxy is \$(tput setaf 3)\$(tput bold)OFF\$(tput sgr0) now\"
        return 0
    else
        echo \"Terminal Proxy is \$(tput setaf 2)\$(tput bold)ON\$(tput sgr0) now\"
    fi
    if curl -# www.google.com >/dev/null 2>&1; then
        echo \"Terminal Proxy test \$(tput setaf 2)\$(tput bold)PASSED\$(tput sgr0)\"
    else
        echo \"Terminal Proxy test \$(tput setaf 3)\$(tput bold)FAILED\$(tput sgr0), please change to another proxy node\"
    fi
}" >>"${rc}"
    fi
}

function init_clash() {
    ilog "=> Initializing Clash" "$BOLD" "$GREEN"
    _home="$HOME"/opt/clash
    # Clean up
    if [[ -d $_home ]]; then
        cleaned="False"
        cleanup "clash" "$_home" "clash.service" "clash"
        if [[ $cleaned == "False" ]]; then
            return 1
        fi
    fi
    # Update subscription
    mkdir -p "$_home"
    if [[ ! -e $_home/config.yaml ]]; then
        # Get subscription link and save to file
        _target=$dir/subscription.txt
        read -r -p "${BLUE}Input your clash subscription link: ${GREEN}" clink && echo -n "${RESET}"
        echo "$clink" >>"$_target"
        wget -q --show-progress -c -O "$_home"/config.yaml "$clink"
        # modify the config
        sed -i -e '/^port:/s/^/#/' \
            -e '/^socks-port:/s/^/#/' \
            -e '/^redir-port:/s/^/#/' \
            -e '/^log-level:/s/silent/info/' \
            -e "6a mixed-port: ${PORT}" \
            "$_home"/config.yaml
    fi

    # Download executable
    ilog "Downloading executables" "${NORMAL}" "${GREEN}"
    git clone https://gitee.com/jackwangsh/cbackup.git "$_home/src"
    rm -rf "$_home"/src/.git
    # TODO: extract according to system
    gzip -d "$_home/src/new-linux-amd64-v1.18.0.gz"
    cp "$_home/src/new-linux-amd64-v1.18.0" "$_home/clash"
    chmod +x "$_home/clash"
    mv "$_home/src/Country.mmdb" "$_home"
    ln -s "$_home/src" "$_home/bin"

    # Dashboard
    ilog "Setting dashboard..." "${NORMAL}" "${GREEN}"
    tar -xJf "$_home"/src/yacd.tar.xz -C "$_home"
    mv "$_home"/public "$_home"/dashboard
    sed -i \
        -e "s/^secret:.*/secret: '123456'/" \
        -e "/^secret:.*/a external-ui: dashboard" \
        "$_home"/config.yaml
    echo "Click ${GREEN}http://localhost:9090/ui${RESET} or ${GREEN}http://$(curl -s ifconfig.me)/ui${RESET} to login into dashboard"
    echo "Username: ${GREEN}ip:9090${RESET}, Password: ${GREEN}123456${RESET}"

    # Add proxy to shell rc
    add_proxy

    # Test
    "$_home/clash" -d "$_home" &
    sleep 5s
    ilog "Start clash testing, this maybe fail because of your subscription default proxy node is unreachable" "${NORMAL}" "${YELLOW}"
    ilog "But it does not mean the clash is failed, you may access dashboard to change your default proxy node" "${NORMAL}" "${YELLOW}"
    proxy_on
    if curl -s -# www.google.com >/dev/null 2>&1; then
        ilog "Clash test passed" "${NORMAL}" "${GREEN}"
    else
        ilog "Clash test failed, please change default proxy node to another" "${BOLD}" "${RED}"
    fi
    killall -q clash

    # Add to systemd and test again
    sleep 5s
    if systemd_add "${dir}"/clash.service; then
        ilog "Add systemd service $_systemd success" "${NORMAL}" "${NORMAL}"
    else
        ilog "Add systemd service $_systemd fail" "${NORMAL}" "${NORMAL}"
    fi
    if curl -# www.google.com >/dev/null 2>&1; then
        ilog "Clash test passed" "${NORMAL}" "${GREEN}"
    else
        ilog "Clash test failed, please change default proxy node to another" "${BOLD}" "${RED}"
    fi

    return 0
}

function init_qv2ray() {
    ilog "=> Initializing Clash" "$BOLD" "$GREEN"
    _home="$HOME"/opt/qv2ray
    _config="$HOME"/.config/qv2ray
    # Clean up
    if [[ -d $_home ]]; then
        cleaned="False"
        cleanup "qv2ray" "$_home" "" ""
        if [[ $cleaned == "False" ]]; then
            return 1
        fi
        [[ -d $_config ]] && rm -rf "$_config"
    fi
    # Dependency
    ilog "Downloading dependencies" "${NORMAL}" "${GREEN}"
    echo "$PASS" | sudo -S apt install -y libfuse2

    # Download executable
    ilog "Downloading executables" "${NORMAL}" "${GREEN}"
    git clone https://gitee.com/jackwangsh/newnew.git "$_home"
    rm -rf "$_home"/.git
    chmod +x "$_home"/Qv2ray-v2.7.0-linux-x64.AppImage
    unzip -d "$_home"/v2ray "$_home"/new.zip

    # Plugins
    ilog "Setting up plugins" "${NORMAL}" "${GREEN}"
    mkdir -p "$_config"/plugins
    cp "$_home"/QvPlugin-* "$_config"/plugins
    return 0
}

function init_zsh() {
    ilog "=> Initializing zsh" "$BOLD" "$GREEN"
    # Test Proxy
    proxy_on
    if curl -# www.google.com >/dev/null 2>&1; then
        ilog "Proxy test passed" "${NORMAL}" "${NORMAL}"
    else
        ilog "Proxy test failed. To initialize zsh, you must have proxy on. Initialize clash first" "${BOLD}" "${RED}"
    fi
    # Download zsh
    ilog "Downloading zsh" "${NORMAL}" "${GREEN}"
    echo "$PASS" | sudo -S apt install -y zsh

    # Cleanup oh-my-zsh
    _home="${HOME}"/.oh-my-zsh
    if [[ -d $_home ]]; then
        cleaned="False"
        cleanup "oh-my-zsh" "$_home" "" ""
        if [[ $cleaned == "False" ]]; then
            return 1
        fi
        [[ -d $_config ]] && rm -rf "$_config"
    fi

    # Download oh-my-zsh
    ilog "Downloading oh-my-zsh" "${NORMAL}" "${GREEN}"
    _home="${HOME}"/.oh-my-zsh
    _attempt=1
    while [ $_attempt -le 5 ]; do
        # 检查curl的退出状态码
        if ! (echo n | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"); then
            # 删除下载到一半的文件
            ilog "Retry... ${_attempt}" "${NORMAL}" "${YELLOW}"
            rm -rf "$_home"
            _attempt+=1
        else
            break
        fi
        # 等待一段时间再进行下一次尝试
        sleep 1
    done
    if [[ $_attempt -gt 5 ]]; then
        ilog "oh-my-zsh download failed!" "${BOLD}" "${RED}"
        proxy_off
        return 1
    fi

    # Powerlevel10k
    ilog "Setting up PowerLevel-10K" "${NORMAL}" "${GREEN}"
    if ! git_clone https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"; then
        ilog "Download PowerLevel-10K Failed!" "${BOLD}" "${NORMAL}"
        return 1
    fi
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    echo "
# To customize prompt, run \$(p10k configure) or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
" >>~/.zshrc
    cp "${dir}/.p10k.zsh" "${HOME}"

    # Zsh Plugins
    ilog "Setting up zsh plugins" "${NORMAL}" "${GREEN}"
    # Default Plugins
    sed -i "s/plugins=(/plugins=(copypath copyfile copybuffer sudo /" ~/.zshrc
    # Third Party Plugins
    _plugins=(
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "zsh-history-substring-search"
        "zsh-vi-mode"
    )
    _plugin_urls=(
        "https://github.com/zsh-users/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "https://github.com/zsh-users/zsh-history-substring-search"
        "https://github.com/jeffreytse/zsh-vi-mode.git"
    )
    for i in "${!_plugins[@]}"; do
        if ! git_clone "${_plugin_urls[$i]}" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${_plugins[$i]}"; then
            ilog "Download ${_plugins[$i]} failed!" "${BOLD}" "${RED}"
        fi
        sed -i "s/plugins=(/plugins=(${_plugins[$i]} /" ~/.zshrc
        ilog "Zsh Plugin: ${_plugins[$i]} added" "${NORMAL}" "${GREEN}"
    done
    # Plugin configure
    echo "
# zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey \"\$terminfo[kcuu1]\" history-substring-search-up
bindkey \"\$terminfo[kcud1]\" history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(bg=red,fg=magenta,bold)

# zsh-vi-mode
ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
" >>~/.zshrc

    # Download Font
    ilog "Installing NerdFont: FiraMono" "${NORMAL}" "${GREEN}"
    ilog "Downloading getnf" "${NORMAL}" "${NORMAL}"
    if ! git_clone https://github.com/ronniedroid/getnf.git "${HOME}"/opt/getnf; then
        ilog "Download getnf failed" "${BOLD}" "${RED}"
    fi
    if ! wget -c -q --show-progress --tries=5 -P "${dir}" -e http_proxy=127.0.0.1:7890 -e https_proxy=127.0.0.1:7890 https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraMono.zip; then
        ilog "Mannually download NerdFont failed, you can try getnf in ${HOME}/opt/getnf to download NerdFont later!" "${BOLD}" "${RED}"
        proxy_off
        return 1
    else
        echo "$PASS" | sudo -S mkdir -p /usr/share/fonts/FiraMono
        echo "$PASS" | sudo -S unzip -q "${dir}"/FiraMono.zip -d /usr/share/fonts/FiraMono
        sudo chmod 744/usr/share/fonts/FiraMono/*.ttf
        echo "$PASS" | sudo mkfontscale
        echo "$PASS" | sudo mkfontdir
        echo "$PASS" | sudo fc-cache -fv
    fi

    # Add proxy to shell rc
    add_proxy
    proxy_off
    return 0
}

function init_frp() {
    ilog "=> Initializing frp" "$BOLD" "$GREEN"
    while true; do
        read -r -p "${BLUE}Install client or server? [c/s]: ${GREEN}" choice && echo -n "${RESET}"
        if [[ ${choice^^} == "C" ]]; then
            _name="frpc"
            _home="${HOME}"/opt/frpc
            _systemd="frpc.service"
            break
        elif [[ ${choice^^} == "S" ]]; then
            _name="frps"
            _home="${HOME}"/opt/frps
            _systemd="frps.service"
            break
        else
            ilog "Invalid option: ${choice}, please input [c/s]" "${NORMAL}" "${YELLOW}"
        fi
    done

    # Cleanup
    if [[ -d $_home ]]; then
        cleaned="False"
        cleanup "$_name" "$_home" "$_systemd" "$_name"
        if [[ $cleaned == "False" ]]; then
            return 1
        fi
    fi

    # Download File
    proxy_on
    ilog "Downloading $_name" "${NORMAL}" "${GREEN}"
    if ! wget -c -q --show-progress --tries=5 -P "$_home" -e http_proxy=127.0.0.1:${PORT} -e https_proxy=127.0.0.1:${PORT} https://github.com/fatedier/frp/releases/download/v0.52.3/frp_0.52.3_linux_amd64.tar.gz; then
        ilog "Mannually download $_name failed, this may because of your proxy. Check your proxy and try later!" "${BOLD}" "${RED}"
        proxy_off
        return 1
    fi
    tar xzvf "$_home"/frp_0.52.3_linux_amd64.tar.gz -C "$_home"
    [[ $_name == "frpc" ]] && rm "$_home/frp_0.52.3_linux_amd64/${_name/c/s}" "$_home/frp_0.52.3_linux_amd64/${_name/c/s}.toml"
    [[ $_name == "frps" ]] && rm "$_home/frp_0.52.3_linux_amd64/${_name/s/c}" "$_home/frp_0.52.3_linux_amd64/${_name/s/c}.toml"
    cp "${dir}/${_name}.toml" "$_home"
    ln -s "$_home"/frp_0.52.3_linux_amd64 "$_home"/bin

    # Configure
    ilog "${_name} configuration" "${NORMAL}" "${GREEN}"
    _addr=""
    _pass=""
    if [[ $_name == "frpc" ]]; then
        while true; do
            read -r -p "${BLUE}Please input your frp server address (default: X.X.X.X): ${GREEN}" _addr && echo -n "${RESET}"
            if [[ $_addr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                break
            fi
            ilog "Invalid IP address, please check if the address is valid." "${NORMAL}" "${YELLOW}"
        done
    fi
    while true; do
        read -r -p "${BLUE}Please input your frp token: ${GREEN}" _pass && echo -n "${RESET}"
        if [[ -n $_pass ]]; then
            break
        fi
    done
    sed -i "s/serverAddr = \"#ADDR\"/serverAddr = \"${_addr}\"/" "${_home}/${_name}".toml
    sed -i "s/auth.token = \"#PASS\"/auth.token = \"${_pass}\"/" "${_home}/${_name}".toml

    if systemd_add "${dir}/${_name}.service"; then
        ilog "Add systemd service $_systemd success" "${NORMAL}" "${NORMAL}"
    else
        ilog "Add systemd service $_systemd fail" "${NORMAL}" "${NORMAL}"
        return 1
    fi
    proxy_off
    return 0
}

function init_tmux() {
    ilog "=> Initializing tmux" "$BOLD" "$GREEN"
    while true; do
        read -r -p "${BLUE}Using oh-my-tmux or MyConfig? [o/m]: ${GREEN}" choice && echo -n "${RESET}"
        if [[ ${choice^^} == "M" ]]; then
            _which="MyConfig"
            _home="${HOME}"/opt/tmux
            break
        elif [[ ${choice^^} == "O" ]]; then
            _which="oh-my-tmux"
            _home="${HOME}"/opt/tmux/oh-my-tmux
            break
        else
            ilog "Invalid option: ${choice}, please input [o/m]" "${NORMAL}" "${YELLOW}"
        fi
    done

    # Cleanup
    if [[ -d $_home ]]; then
        cleaned="False"
        cleanup "tmux" "$_home" "" ""
        if [[ $cleaned == "False" ]]; then
            return 1
        fi
        rm -rf "${HOME}"/.tmux.conf
        rm -rf "${HOME}"/.tmux.conf.local
    fi

    mkdir -p "$_home"
    if [[ $_which == "MyConfig" ]]; then
        ilog "Coping MyConfig configuration" "${NORMAL}" "${GREEN}"
        cp "${dir}"/.tmux.conf "$_home"
        ln -s -f "$_home"/.tmux.conf "${HOME}"/.tmux.conf
    else
        proxy_on
        ilog "Downloading oh-my-tmux configuration" "${NORMAL}" "${GREEN}"
        if ! git_clone https://github.com/gpakosz/.tmux.git "$_home"; then
            ilog "Download oh-my-tmux failed" "${BOLD}" "${RED}"
            return 1
        fi
        cp "${dir}"/.tmux.conf.local "$_home"/.tmux.conf.local
        ln -s -f "$_home"/.tmux.conf "${HOME}"/.tmux.conf
        ln -s -f "$_home"/.tmux.conf.local "${HOME}"/.tmux.conf.local
        proxy_off
    fi

    return 0
}

function init_rust() {
    ilog "=> Initializing tmux" "$BOLD" "$GREEN"
    proxy_on
}

# Show menu and get user input
show_menu

# TODO: 添加main函数, 实现依赖安装, 同时添加别的函数

function main() {
    # Read Password
    read -r -s -p "${BOLD}${GREEN}[initUbuntu]${RESET} Please enter password for $USER: ${RESET}" PASS && echo ""
    # Check SUDO privilege
    if ! (echo "$PASS" | sudo -S -l -U "$USER" | grep -q '(ALL : ALL) ALL'); then
        ilog "initUbuntu needs SUDO privilege to run. Make sure you have it." "$BOLD" "$RED"
        exit "$exitFail"
    fi
    echo ""
    # main function
    proxy_off
    fail_tools=()
    success_tools=()
    if [[ $isChangeSource == "True" ]]; then
        change_source
    elif [[ $isDependency == "True" ]]; then
        install_dependency
    elif [[ $isInteractive == "True" ]] || [[ $isTUI == "True" ]]; then
        for index in "${functions_to_run[@]}"; do
            if ${init_functions[$index]}; then
                success_tools+=("${init_functions[$index]#init_}")
                ilog "Setup ${init_functions[$index]#init_} successed, enjoy!" "${BOLD}" "${GREEN}"
                printf '%*s\n' "$(tput cols)" "-"
            else
                fail_tools+=("${init_functions[$index]#init_}")
                ilog "Setup ${init_functions[$index]#init_} failed, please try later!" "${BOLD}" "${RED}"
                printf '%*s\n' "$(tput cols)" "-"
            fi
        done

        # Print success and fail tools
        echo ""
        echo ""
        content="Summary"
        hlen=$((($(tput cols) - ${#content}) / 2 - 1))
        delimiter=$(printf '%*s\n' $hlen | tr ' ' '-')
        echo "${delimiter} ${content} ${delimiter}"
        ilog "Successed Tools: " "${NORMAL}" "${GREEN}"
        for index in "${!success_tools[@]}"; do
            printf "%s\n" "${success_tools[$index]}"
        done | pr -o 8 -3 -t -w "$(tput cols)"
        ilog "Failed Tools: " "${NORMAL}" "${RED}"
        for index in "${!fail_tools[@]}"; do
            printf "%s\n" "${fail_tools[$index]}"
        done | pr -o 8 -3 -t -w "$(tput cols)"
        ilog "Don't forget to source your shell rc" "${NORMAL}" "${GREEN}"
    fi
}

main
