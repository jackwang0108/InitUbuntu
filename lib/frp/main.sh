#!/bin/env bash

function install_frp() {
    # FILE_PATH will be substituted by sed in Makefile
    local MODULE_DIR
    MODULE_DIR=$(dirname FILE_PATH)

    ilog "Installing frp" "${BOLD}" "${GREEN}"

    # Get user choice of frp client or server
    local install_function
    while true; do
        read -r -p "${BLUE}Install frp Client or Server? [C/S]: ${GREEN}" choice && echo -n "${RESET}"
        if [[ ${choice^^} == "C" ]]; then
            install_function=frpc_install
            break
        elif [[ ${choice^^} == "S" ]]; then
            install_function=frps_install
            break
        else
            ilog "Invalid option: ${choice}, please input [c/s]" "${NORMAL}" "${YELLOW}"
        fi
    done

    # Call install function
    if ! ${install_function} "${MODULE_DIR}"; then
        ilog "Frp install failed" "${BOLD}" "${RED}"
        return 1
    fi
}

function frpc_install() {
    local MODULE_DIR=$1
    echo "$MODULE_DIR"
}

function frps_install() {
    local MODULE_DIR=$1
    echo "$MODULE_DIR"
}
