#!/bin/env bash

function install_frp() {
    # FILE_PATH will be substituted by sed in Makefile
    local MODULE_DIR
    MODULE_DIR=$(dirname FILE_PATH)

    ilog "Installing frp" "${BOLD}" "${GREEN}"

    # Get user choice of frp client or server
    local install_target
    while true; do
        read -r -p "${BLUE}Install frp Client or Server? [C/S]: ${GREEN}" choice && echo -n "${RESET}"
        if [[ ${choice^^} == "C" ]]; then
            install_target=frpc
            break
        elif [[ ${choice^^} == "S" ]]; then
            install_target=frps
            break
        else
            ilog "Invalid option: ${choice}, please input [c/s]" "${NORMAL}" "${YELLOW}"
        fi
    done

    # Declare Variables
    export FRP_HOME="${HOME}/opt/${install_target}"
    service_template_file="${MODULE_DIR}/${install_target}.service.template"

    # Check if frp has already installed
    if [[ -d "${FRP_HOME}" ]]; then
        while true; do
            read -r -p "${YELLOW}${install_target^} has already installed, removed and re-install? [y/n]: ${GREEN}" choice && echo -n "${RESET}"
            if [[ ${choice^^} == "Y" ]]; then
                if ! clean_frp "$install_target"; then
                    ilog "${install_target^} removed failed" "${BOLD}" "${RED}"
                    return 1
                fi
                break
            elif [[ ${choice^^} == "N" ]]; then
                ilog "${install_target^} has already installed, skipping..." "${NORMAL}" "${GREEN}"
                return 0
            else
                ilog "Invalid option: ${choice}, please input [y/n]" "${NORMAL}" "${YELLOW}"
            fi
        done
    fi

    # Create frp home directory
    mkdir -p "${FRP_HOME}"

    # Check frp cache
    frp_caches=("serverAddr" "serverPort" "authToken" "webServerPort" "webServerUser" "webServerPassword" "proxyName")
    check_cache ".frp_cache" "${frp_caches[@]}"

    # Get proxy configuration
    ilog "Frp installation requires downloading the frp binary file from github, which requires the proxy configuration." "${BOLD}" "${GREEN}"
    echo "Testing proxy configuration..."
    check_cache ".proxy_cache" "PROXY_IP" "PROXY_PORT"

    local HTTP_PROXY
    HTTP_PROXY="http://${PROXY_IP}:${PROXY_PORT}"

    if curl --connect-timeout 5 -x "${HTTP_PROXY}" www.google.com >/dev/null 2>&1; then
        ilog "Proxy configuration test passed" "${NORMAL}" "${GREEN}"
    else
        ilog "Proxy configuration test failed, please check your proxy configuration." "${BOLD}" "${RED}"
        return 1
    fi

    # Get target distribution
    local distributions
    distributions=("arm" "arm64" "arm_hf" "amd64" "loong64" "mips" "mips64" "mips64le" "mipsle" "riscv64")

    # Print the choices menu
    for i in "${!distributions[@]}"; do
        printf "%02d) %s\n" "$((i))" "${distributions[$i]}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }

    # Get user choice
    while true; do
        read -r -p "${BLUE}Select the distribution you want to install (e.g. 0): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please select a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#distributions[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#distributions[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            break
        fi
    done

    local archive_name="frp_0.61.1_linux_${distributions[$choice]}.tar.gz"
    local download_url="https://github.com/fatedier/frp/releases/download/v0.61.1/${archive_name}"

    # Download frp binary file
    ilog "Downloading ${install_target} binary file" "${NORMAL}" "${GREEN}"
    if ! wget -c -q --show-progress --tries=5 --timeout=10 -P "${FRP_HOME}" -e "https_proxy=${HTTP_PROXY}" -e "http_proxy=${HTTP_PROXY}" "${download_url}"; then
        ilog "Download ${install_target} binary file failed, please check your network." "${BOLD}" "${RED}"
        return 1
    fi

    # Install frp binary file
    ilog "Installing ${install_target} binary file" "${NORMAL}" "${GREEN}"
    tar xzvf "${FRP_HOME}/${archive_name}" -C "${FRP_HOME}" --strip-components=1

    # Remove useless files
    local file_to_remove=("LICENSE" "README.md")
    if [[ "${install_target}" == "frpc" ]]; then
        file_to_remove+=("${FRP_HOME}/frps" "${FRP_HOME}/frps.toml")
    else
        file_to_remove+=("${FRP_HOME}/frpc" "${FRP_HOME}/frpc.toml")
    fi
    rm -rf "${file_to_remove[@]}"

    # Setup frp configuration
    ilog "Setting up ${install_target} configuration" "${NORMAL}" "${GREEN}"
    cp "${MODULE_DIR}/${install_target}.toml" "${FRP_HOME}"
    for variable in "${frp_caches[@]}"; do
        sed -i "s/#${variable}#/${!variable}/g" "${FRP_HOME}/${install_target}.toml"
    done

    # Setup frp systemd service
    ilog "Installing ${install_target} systemd service" "${NORMAL}" "${GREEN}"
    sed "s/#USER#/$(whoami)/g" "${MODULE_DIR}"/${install_target}.service.template >"${MODULE_DIR}/${install_target}.service"

    if add_systemd_service "${MODULE_DIR}/${install_target}.service"; then
        ilog "${install_target^} systemd service installed successfully" "${NORMAL}" "${GREEN}"
    else
        ilog "${install_target^} systemd service installed failed" "${BOLD}" "${RED}"
        return 1
    fi

    ilog "${install_target^} Installed Successfully in ${FRP_HOME}" "${BOLD}" "${GREEN}"

}

function clean_frp() {

    local install_target=$1

    # Remove frp cache
    echo "Removing ${install_target} cache"
    rm -f "${PROJECT_BASE_DIR}/.frp_cache"

    # Remove frp home directory
    echo "Removing ${install_target} home directory"
    rm -rf "${FRP_HOME}"

    # Remove frp systemd service
    echo "Removing ${install_target} systemd service"
    if remove_systemd_service "${install_target}.service"; then
        ilog "${install_target^} systemd service removed successfully" "${NORMAL}" "${GREEN}"
    else
        ilog "${install_target^} systemd service removed failed" "${BOLD}" "${RED}"
        return 1
    fi

    echo "${install_target^} Removed Successfully"
}
