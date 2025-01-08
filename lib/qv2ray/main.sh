#!/bin/env bash

function install_qv2ray() {
    # FILE_PATH will be substituted by sed in Makefile
    local MODULE_DIR
    MODULE_DIR=$(dirname FILE_PATH)

    ilog "Installing qv2ray" "${BOLD}" "${GREEN}"

    export QV2RAY_HOME="${HOME}/opt/qv2ray"

    # Check if qv2ray has already installed
    if [[ -d "${QV2RAY_HOME}" ]]; then
        while true; do
            read -r -p "${YELLOW}Qv2ray has already installed, removed and re-install? [y/n]: ${GREEN}" choice && echo -n "${RESET}"
            if [[ ${choice^^} == "Y" ]]; then
                if ! clean_qv2ray; then
                    ilog "Qv2ray removed failed" "${BOLD}" "${RED}"
                    return 1
                fi
                break
            elif [[ ${choice^^} == "N" ]]; then
                ilog "Qv2ray has already installed, skipping..." "${NORMAL}" "${GREEN}"
                return 0
            else
                ilog "Invalid option: ${choice}, please input [y/n]" "${NORMAL}" "${YELLOW}"
            fi
        done
    fi

    # Install qv2ray dependencies
    ilog "Installing qv2ray dependencies" "${NORMAL}" "${GREEN}"
    sudo apt update && sudo apt install -y libfuse2

    # Install qv2ray
    ilog "Installing qv2ray" "${NORMAL}" "${GREEN}"
    mkdir -p "${QV2RAY_HOME}"
    git clone https://gitee.com/jackwangsh/newnew.git "${QV2RAY_HOME}/src"
    rm -rf "${QV2RAY_HOME}"/src/.git
    ln -s "${QV2RAY_HOME}/src/Qv2ray-v2.7.0-linux-x64.AppImage" "${QV2RAY_HOME}/Qv2ray"

    # chmod +x "$_home"/Qv2ray-v2.7.0-linux-x64.AppImage
    # unzip -d "$_home"/v2ray "$_home"/new.zip

}

function clean_qv2ray() {
    echo 1
}
