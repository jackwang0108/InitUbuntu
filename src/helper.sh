#!/bin/env bash

# shellcheck disable=SC2034

# Color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
WHITE=$(tput setaf 7)

# Style
BOLD=$(tput bold)
NORMAL=""
DIM=$(tput dim)

# Normal
RESET=$(tput sgr0)

# Project Base Directory
PROJECT_BASE_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# Shell Config
SUPPORTED_SHELL=("bash" "zsh")
EXISTING_SHELL=()
EXISTING_SHELL_RC=()
for shell in "${SUPPORTED_SHELL[@]}"; do
    if command -v "${shell}" &>/dev/null; then
        EXISTING_SHELL+=("${shell}")
        EXISTING_SHELL_RC+=("${HOME}/.${shell}rc")
    fi
done

SHELL_RC=
function get_shell_rc() {

    # print the choices menu
    for i in "${!EXISTING_SHELL[@]}"; do
        printf "%02d) %s\n" "$((i))" "${EXISTING_SHELL[$i]}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }

    while true; do
        read -r -p "${BLUE}Select a shell to add configure (e.g. 0): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please select a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#EXISTING_SHELL_RC[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#EXISTING_SHELL_RC[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            break
        fi
    done

    SHELL_RC="${EXISTING_SHELL_RC[$choice]}"
}

function usage() {
    local max_length=$1
    local install_functions=("${@:2}")
    echo "initUbuntu: A ${BOLD}${GREEN}Better${RESET} way to initialize your Ubuntu"
    echo ""
    echo "Usage:"
    echo "    ${BLUE}-h${RESET} print this help message and exit"
    echo "    ${BLUE}-d${RESET} install all dependencies"
    echo "    ${BLUE}-f${RESET} force  reinitialize the tool"
    echo "    ${BLUE}-c${RESET} change source from given sources"
    echo "    ${BLUE}-t${RESET} use TUI to initialize your ubuntu"
    echo "    ${BLUE}-i${RESET} interactive install selected tools. Available tools are:"

    for i in "${!install_functions[@]}"; do
        printf "%02d) %-${max_length}s\n" "$((i + 1))" "${install_functions[$i]}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(($(tput cols) - 75))"
        else
            sed 's/^/        /'
        fi
    }

    echo ""
    # shellcheck disable=SC2016
    echo 'By default, you can use `initUbuntu -i` to install single tool interactively you'\''d like to use'
    # shellcheck disable=SC2016
    echo 'or you can use `initUbuntu -t` to run text-based UI (dependency dialog is needed)'
}

function check_os() {
    # Check OS
    if ! uname -a | grep -qi 'ubuntu'; then
        echo "This script only supports Ubuntu, your system is $(uname -s)"
        exit 0
    else
        echo "System Information:"
        lsb_release -irdc
    fi
}

function ilog() {
    local msg=$1
    local style=$2
    local color=$3
    echo "${style:-$RESET}${color:-$WHITE}${msg}${RESET}"
}

function add_dependency() {
    local packages=("ncurses-bin" "git" "vim" "tar" "unzip" "gzip" "wget" "curl" "dialog")
    local commands=("tput" "git" "vim" "tar" "unzip" "gzip" "wget" "curl" "dialog")
    local packages_to_install=()

    # Find missing packages
    for i in "${!commands[@]}"; do
        if ! command -v "${commands[$i]}" &>/dev/null; then
            packages_to_install+=("${packages[$i]}")
        fi
    done

    if [ ${#packages_to_install[@]} -eq 0 ]; then
        ilog "All dependencies are already installed." "${BOLD}" "${GREEN}"
    else
        echo "The following packages are missing: ${BOLD}${YELLOW}${packages_to_install[*]}${RESET}"

        while true; do
            read -r -p "${BLUE}Do you want to install them? (y/n): ${GREEN}" response && echo -n "${RESET}"
            if [[ "${response}" =~ ^[Yy]$ ]]; then
                sudo apt-get update
                sudo apt-get install -y "${packages_to_install[@]}"
                break
            elif [[ "${response}" =~ ^[Nn]$ ]]; then
                ilog "Installation aborted by the user." "${BOLD}" "${RED}"
                exit 0
            else
                ilog "Invalid options: ${response}" "${BOLD}" "${RED}"
            fi
        done
    fi
}

function change_source() {
    local release_name
    release_name=$(lsb_release -cs)

    # Get all sources
    local all_sources=() filename source_dir
    source_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/src/sources"
    for file in "${source_dir}"/*\.source; do
        filename=$(basename "$file")
        all_sources+=("${filename/\.source/}")
    done

    # Display
    for i in "${!all_sources[@]}"; do
        printf "%02d) %s\n" "$((i))" "${all_sources[$i]}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }

    # Get user input
    while true; do
        read -r -p "${BLUE}Select the source you want to use (e.g. 1 or 2): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please input a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#all_sources[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#all_sources[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            source_file="${source_dir}/${all_sources[$choice]}.source"
            break
        fi
    done

    # Backup and set new source
    echo "$PASS" | sudo -S cp /etc/apt/sources.list /etc/apt/sources.list.backup-"$(date +%Y.%m.%d.%S)"
    sed "s/\${release_name}/${release_name}/g" "${source_file}" | sudo tee /etc/apt/sources.list >/dev/null

    # Update use new source
    sudo apt update
    sudo apt upgrade -y
}

function run_install_functions() {
    local install_functions=("${!1}")
    local functions_to_run=("${!2}")

    local -n _success_tools=$3
    local -n _fail_tools=$4
    local width text text_length padding filled_string padding_text

    width=$(tput cols)
    for index in "${functions_to_run[@]}"; do
        text="Installing ${install_functions[$index]#install_}"
        text_length=${#text}
        padding=$(((width - text_length) / 2))
        padding_text=$(echo -n "$(printf '\055%.0s' $(seq 1 $padding))")

        ilog "${padding_text}${text}${padding_text}" "${BOLD}" "${MAGENTA}"
        if ${install_functions[$index]}; then
            success_tools+=("${install_functions[$index]#install_}")
            ilog "Setup ${install_functions[$index]#install_} succeeded, enjoy!" "${BOLD}" "${GREEN}"
        else
            fail_tools+=("${install_functions[$index]#install_}")
            ilog "Setup ${install_functions[$index]#install_} failed, please try later!" "${BOLD}" "${RED}"
        fi
    done

    if [[ -n "${success_tools[0]}" ]] || [[ -n "${fail_tools[0]}" ]]; then
        ending_text=$(echo -n "$(printf '\055%.0s' $(seq 1 "$width"))")
        ilog "${ending_text}" "${BOLD}" "${MAGENTA}"
    fi
}

function print_success_fail_tools() {
    local success_tools=("${!1}")
    local fail_tools=("${!2}")

    # print delimiter
    local width
    width=$(tput cols)
    text="Installation Summary"
    text_length=${#text}
    padding=$(((width - text_length) / 2))
    padding_text=$(echo -n "$(printf '\055%.0s' $(seq 1 $padding))")
    ilog "${padding_text}${text}${padding_text}" "${BOLD}" "${MAGENTA}"

    # print success tools
    ilog "Success tools:" "${BOLD}" "${GREEN}"

    for tool in "${success_tools[@]}"; do
        printf "%s\n" "${tool}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }

    # print fail tools
    ilog "Fail tools:" "${BOLD}" "${RED}"

    for tool in "${fail_tools[@]}"; do
        printf "%s\n" "${tool}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }
}

function interactive_main() {
    local max_length=$1
    local install_functions=("${@:2}")

    install_functions+=("quit")

    local quit="false"
    local functions_to_run=()
    while [[ "$quit" != "true" ]]; do
        # Get user input util received legal value
        while true; do
            # Display menu
            for i in "${!install_functions[@]}"; do
                printf "%02d) %-${max_length}s\n" "$((i))" "${install_functions[$i]}"
            done | {
                if [ "$(tput cols)" -ge 120 ]; then
                    pr -o 8 -3 -t -w "$(tput cols)"
                else
                    sed 's/^/        /'
                fi
            }

            # Get user input
            read -r -p "${BLUE}Select a tool to install (e.g. 0,1,2 or 1-3 or 1,3-5, q/Q to quit): ${GREEN}" choices && echo -n "${RESET}"

            # parse user input one by one
            for choice in $(echo "$choices" | tr ',' ' '); do
                if [[ $choice == *-* ]]; then
                    # ranged input, e.g. 1-10
                    if ! [[ $choice =~ ^[0-9]+-[0-9]$ ]]; then
                        ilog "Invalid input format: $1. Expected format: X-Y" "${BOLD}" "${YELLOW}"
                        continue 2
                    fi

                    IFS='-' read -ra range <<<"$choice"
                    range_start=${range[0]}
                    range_end=${range[1]}
                    for ((i = range_start; i <= range_end; i++)); do
                        if ((0 <= i && i <= ${#install_functions[@]})); then
                            functions_to_run+=("$i")
                        fi
                    done
                elif [[ "$choice" =~ ^[0-9]+$ ]] && ((0 <= choice && choice <= ${#install_functions[@]})); then
                    # single number, e.g. 5
                    functions_to_run+=("$choice")

                elif [[ "$choice" =~ ^[Qq]$ ]]; then
                    break 3
                else
                    # out of range, e.g. 1000
                    ilog "Invalid Option: $choice, Try again." "${BOLD}" "${YELLOW}"
                    continue 2

                fi
            done
            break
        done

        # check if is null
        if [[ -z "${functions_to_run[0]}" ]]; then
            ilog "No tools selected, try again or quit to exit." "${BOLD}" "${YELLOW}"
            continue
        fi

        # check if quit
        for index in "${functions_to_run[@]}"; do
            if [[ "${install_functions[$index]}" == "quit" ]]; then
                quit="true"
                break 2
            fi
        done

        # run install functions
        fail_tools=()
        success_tools=()
        run_install_functions install_functions[@] functions_to_run[@] success_tools fail_tools

    done

    # print installation result
    print_success_fail_tools success_tools[@] fail_tools[@]
}

function TUI_main() {
    local install_functions=("${@}") functions_to_run=()

    local quit="false"

    # Generate menu options
    local options menu_options choices
    for index in "${!install_functions[@]}"; do
        options="${options} $((index + 1)) ${install_functions[$index]} off"
    done
    # shellcheck disable=SC2206
    menu_options=(${options})

    cmd=(dialog --title "InitUbuntu Tool Selection" --separate-output --checklist "Select tools to be installed:" 22 76 16)

    choices=$("${cmd[@]}" "${menu_options[@]}" 2>&1 >/dev/tty)
    clear

    if [[ -z "$choices" ]]; then
        ilog "No tools selected, see you~" "${BOLD}" "${GREEN}"
        exit 0
    fi

    for choice in $choices; do
        functions_to_run+=("$((choice - 1))")
    done

    # run install functions
    fail_tools=()
    success_tools=()
    run_install_functions install_functions[@] functions_to_run[@] success_tools fail_tools

    # print installation result
    print_success_fail_tools success_tools[@] fail_tools[@]
}
