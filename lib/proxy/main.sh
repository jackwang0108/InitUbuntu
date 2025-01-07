#!/bin/env bash

function install_proxy() {
    # FILE_PATH will be substituted by sed in Makefile
    local MODULE_DIR
    MODULE_DIR=$(dirname FILE_PATH)

    # Choose Shell Configuration File
    echo "Select Shell Configuration File that you want to install terminal proxy tools"
    get_shell_rc

    # Check if Terminal Proxy Tools has already installed
    if grep -q "proxy_on" "$SHELL_RC"; then
        echo "Terminal Proxy Tools has already installed in $SHELL_RC, nothing changed!"
        return 0
    fi

    # Check proxy cache
    check_cache .proxy_cache "PROXY_IP" "PROXY_PORT"

    # Install Terminal Proxy Tools
    sed -e "s/#PROXY_IP#/${PROXY_IP}/g" -e "s/#PROXY_PORT#/${PROXY_PORT}/g" "${MODULE_DIR}/proxy_tools.sh" >>"${SHELL_RC}"

    # print to terminal
    echo "Terminal Proxy Tools installed in $SHELL_RC"
}
