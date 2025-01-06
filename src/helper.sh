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
    done | pr -o 8 -3 -t -w "$(($(tput cols) - 75))"
    echo ""
    # shellcheck disable=SC2016
    echo 'By default, you can use `initUbuntu -i` to install single tool interactively you'\''d like to use'
    # shellcheck disable=SC2016
    echo 'or you can use `initUbuntu -t` to run text-based UI (dependency dialog is needed)'
}

function check_os() {
    # Check OS
    if ! uname -a | grep -qi 'ubuntu'; then
        echo "当前系统为 $(uname -s), 该脚本仅支持Ubuntu操作系统, 退出..."
        exit 0
    else
        echo "当前系统信息: "
        lsb_release -irdc
    fi
}

function ilog() {
    local msg=$1
    local style=$2
    local color=$3
    echo "${style:-$RESET}${color:-$WHITE}${msg}${RESET}"
}

function install_dependency() {
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

    ending_text=$(echo -n "$(printf '\055%.0s' $(seq 1 "$width"))")
    ilog "${ending_text}" "${BOLD}" "${MAGENTA}"

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
            done | pr -o 8 -3 -t -w "$(tput cols)"

            # Get user input
            read -r -p "${BLUE}Select a tool to install (e.g. 0,1,2 or 1-3 or 1,3-5): ${GREEN}" choices && echo -n "${RESET}"

            # parse user input one by one
            for choice in $(echo "$choices" | tr ',' ' '); do
                if [[ $choice == *-* ]]; then
                    # ranged input, e.g. 1-10
                    if ! [[ $choice =~ ^[0-9]+-[0-9]$ ]]; then
                        ilog "Invalid input format: $1. Expected format: X-Y" "${BOLD}" "${YELLOW}"
                    fi

                    IFS='-' read -ra range <<<"$choice"
                    range_start=${range[0]}
                    range_end=${range[1]}
                    for ((i = range_start; i <= range_end; i++)); do
                        if ((0 <= i && i <= ${#install_functions[@]})); then
                            functions_to_run+=("$i")
                        fi
                    done
                elif ((0 <= choice && choice <= ${#install_functions[@]})); then
                    # single number, e.g. 5
                    functions_to_run+=("$choice")

                else
                    # out of range, e.g. 1000
                    ilog "Invalid Option: $choice, Try again." "${BOLD}" "${YELLOW}"
                    continue 2
                fi
            done
            break
        done

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
    echo "finished"
}

function TUI_main() {
    echo "TUI Main"
}
