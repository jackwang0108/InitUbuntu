#!/bin/env bash

function install_proxy() {
    # FILE_PATH will be substituted by sed in Makefile
    MODULE_DIR=$(dirname FILE_PATH)

    # Choose Shell Configuration File
    echo "Select Shell Configuration File that you want to install terminal proxy tools"
    get_shell_rc

    # Check if Terminal Proxy Tools has already installed
    if grep -q "proxy_on" "$SHELL_RC"; then
        echo "Terminal Proxy Tools has already installed in $SHELL_RC, nothing changed!"
        return 0
    fi

    # Check config cache
    if [[ -f $PROJECT_BASE_DIR/.proxy_cache ]]; then
        # shellcheck disable=SC1091
        source "$PROJECT_BASE_DIR/.proxy_cache"
    else
        read -r -p "Enter Proxy IP: " PROXY_IP
        read -r -p "Enter Proxy Port: " PROXY_PORT
        echo -e "PROXY_IP=$PROXY_IP\nPROXY_PORT=${PROXY_PORT}" >"$PROJECT_BASE_DIR/.proxy_cache"
    fi

    # Install Terminal Proxy Tools
    sed -e "s/#PROXY_IP#/${PROXY_IP}/g" -e "s/#PROXY_PORT#/${PROXY_PORT}/g" "${MODULE_DIR}/proxy_tools.sh" >>"${SHELL_RC}"

    # print to terminal
    echo "Terminal Proxy Tools installed in $SHELL_RC"
}
