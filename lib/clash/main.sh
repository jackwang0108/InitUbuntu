#!/bin/env bash

function install_clash() {
    # FILE_PATH will be substituted by sed in Makefile
    local MODULE_DIR
    MODULE_DIR=$(dirname FILE_PATH)

    ilog "Installing clash" "${BOLD}" "${GREEN}"

    export CLASH_HOME="${HOME}/opt/clash"

    # Check if clash has already installed
    if [[ -d "${CLASH_HOME}" ]]; then
        while true; do
            read -r -p "${YELLOW}Clash has already installed, removed and re-install? [y/n]: ${GREEN}" choice && echo -n "${RESET}"
            if [[ ${choice^^} == "Y" ]]; then
                if ! clean_clash; then
                    ilog "Clash removed failed" "${BOLD}" "${RED}"
                    return 1
                fi
                break
            elif [[ ${choice^^} == "N" ]]; then
                ilog "Clash has already installed, skipping..." "${NORMAL}" "${GREEN}"
                return 0
            else
                ilog "Invalid option: ${choice}, please input [y/n]" "${NORMAL}" "${YELLOW}"
            fi
        done
    fi

    # Create clash home directory
    mkdir -p "${CLASH_HOME}"

    # Check clash cache
    check_cache ".clash_cache" "SUBSCRIPTION_LINK"

    # Download clash config
    ilog "Updating clash subscriptions" "${NORMAL}" "${GREEN}"
    if wget -q --show-progress -c -O "${CLASH_HOME}/config.yaml" "${SUBSCRIPTION_LINK}"; then
        ilog "Clash config update successfully" "${NORMAL}" "${GREEN}"
    else
        ilog "Clash config update failed" "${NORMAL}" "${RED}"
        return 1
    fi

    # Check proxy cache
    check_cache .proxy_cache "PROXY_IP" "PROXY_PORT"

    # Modify clash config
    sed -i \
        -e '/^port:/s/^/#/' \
        -e '/^socks-port:/s/^/#/' \
        -e '/^redir-port:/s/^/#/' \
        -e '/^log-level:/s/silent/info/' \
        -e "6a mixed-port: ${PROXY_PORT}" \
        "${CLASH_HOME}/config.yaml"

    # Download clash binary
    ilog "Downloading clash executables" "${NORMAL}" "${GREEN}"
    git clone https://gitee.com/jackwangsh/cbackup.git "${CLASH_HOME}/src"
    rm -rf "${CLASH_HOME}"/src/.git

    # Install clash binary
    ilog "Installing clash executables" "${NORMAL}" "${GREEN}"
    clash_binaries_arch=()
    for file in "${CLASH_HOME}"/src/*.gz; do
        architecture="${file#*-*-}"
        architecture="${architecture%%-*}"

        if [[ ${#architecture} -le 7 && ! "${clash_binaries_arch[*]}" =~ ${architecture} ]]; then
            clash_binaries_arch+=("${architecture}")
        fi
    done

    # Display menu
    for i in "${!clash_binaries_arch[@]}"; do
        printf "%02d) clash-%s\n" "$((i))" "${clash_binaries_arch[$i]}"
    done | {
        if [ "$(tput cols)" -ge 120 ]; then
            pr -o 8 -3 -t -w "$(tput cols)"
        else
            sed 's/^/        /'
        fi
    }

    # Get user choice
    while true; do
        read -r -p "${BLUE}Select a clash binary to install (e.g. 0): ${GREEN}" choice && echo -n "${RESET}"
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            ilog "Invalid option: ${choice}, please select a number" "${NORMAL}" "${YELLOW}"
        elif ((choice < 0 || choice > ${#EXISTING_SHELL_RC[@]} - 1)); then
            ilog "Out of range: ${choice}, please select a number between 0 to $((${#EXISTING_SHELL_RC[@]} - 1))" "${NORMAL}" "${YELLOW}"
        else
            break
        fi
    done

    # Install clash binary
    target_arch="${clash_binaries_arch[$choice]}"
    clash_binary="${CLASH_HOME}/src/new-linux-${target_arch}-v1.18.0.gz"

    gzip -d "${clash_binary}"
    cp "${CLASH_HOME}/src/new-linux-${target_arch}-v1.18.0" "${CLASH_HOME}/clash"
    chmod +x "${CLASH_HOME}/clash"
    mv "${CLASH_HOME}/src/Country.mmdb" "${CLASH_HOME}"

    # Install clash dashboard
    ilog "Setting up clash dashboard" "${NORMAL}" "${GREEN}"
    tar -xJf "${CLASH_HOME}"/src/yacd.tar.xz -C "${CLASH_HOME}"
    mv "${CLASH_HOME}"/public "${CLASH_HOME}"/dashboard
    sed -i 's/# external-ui: folder/external-ui: dashboard/' "${CLASH_HOME}/config.yaml"

    ilog "Clash dashboard installed successfully" "${NORMAL}" "${GREEN}"
    echo "Click ${GREEN}http://127.0.0.1:9090/ui${RESET} to login into dashboard"
    echo "Username: ${BOLD}${GREEN}http://127.0.0.1:9090${RESET}, Password: ${BOLD}${GREEN}null${RESET}"

    # Install proxy tools
    install_proxy

    # Install clash systemd service
    ilog "Installing clash systemd service" "${NORMAL}" "${GREEN}"
    sed "s/#USER#/$(whoami)/g" "${MODULE_DIR}"/clash.service.template >"${MODULE_DIR}/clash.service"

    if add_systemd_service "${MODULE_DIR}/clash.service"; then
        ilog "Clash systemd service installed successfully" "${NORMAL}" "${GREEN}"
    else
        ilog "Clash systemd service installed failed" "${BOLD}" "${RED}"
        return 1
    fi

    ilog "Clash Installed Successfully in ${CLASH_HOME}, default node may not be accessible, change the node in https://127.0.0.1:9090/ui" "${BOLD}" "${GREEN}"
}

function clean_clash() {

    # Remove clash cache
    echo "Remove clash cache..."
    rm -f "${PROJECT_BASE_DIR}/.clash_cache"

    # Remove clash home directory
    echo "Remove clash home directory..."
    rm -rf "${CLASH_HOME}"

    # Remove clash systemd service
    echo "Remove clash systemd service..."
    if remove_systemd_service clash.service; then
        ilog "Clash systemd service removed successfully" "${NORMAL}" "${GREEN}"
    else
        ilog "Clash systemd service removed failed" "${BOLD}" "${RED}"
        return 1
    fi

    echo "Clash Removed Successfully"
}
