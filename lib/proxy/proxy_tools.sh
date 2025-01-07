# 命令行代理工具

IP_PROXY=#PROXY_IP#
PORT_PROXY=#PROXY_PORT#

function proxy_on() {
    # print to terminal
    echo "Terminal Proxy is turned $(tput setaf 2)$(tput bold)ON$(tput sgr0)"
    echo "Terminal Traffic is $(tput setaf 2)$(tput bold)now$(tput sgr0) redirected to $(tput setaf 2)$(tput bold)${IP_PROXY}:${PORT_PROXY}$(tput sgr0)"

    # turn on proxy
    export HTTP_PROXY="http://${IP_PROXY}:${PORT_PROXY}"
    export HTTPS_PROXY="http://${IP_PROXY}:${PORT_PROXY}"
    export ALL_PROXY="socks5://${IP_PROXY}:${PORT_PROXY}"
    git config --global http.proxy "http://${IP_PROXY}:${PORT_PROXY}"
    git config --global https.proxy "https://${IP_PROXY}:${PORT_PROXY}"
    alias wget='wget -e use_proxy=yes -e http_proxy="${HTTP_PROXY}" -e https_proxy="${HTTPS_PROXY}"'
    alias curl='curl -x "${HTTP_PROXY}"'
}

function proxy_off() {
    # print to terminal
    echo "Terminal Proxy is turned $(tput setaf 3)$(tput bold)OFF$(tput sgr0)"
    echo "Terminal Traffic was $(tput setaf 3)$(tput bold)previously$(tput sgr0) redirected to $(tput setaf 3)$(tput bold)${IP_PROXY}:${PORT_PROXY}$(tput sgr0)"

    # turn off proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    unalias wget
    unalias curl
}

function proxy_test() {
    # print to terminal
    echo "Terminal Proxy testing..."

    # print current proxy status
    local color print_status="ON"
    color=$(tput setaf 2)
    if [[ -z $HTTP_PROXY ]] || [[ -z $HTTPS_PROXY ]] || [[ -z $ALL_PROXY ]]; then
        print_status="OFF"
        color=$(tput setaf 3)
    fi
    echo "Terminal Proxy is turned ${color}$(tput bold)${print_status}$(tput sgr0) now"

    # test if can connect to google
    if [[ "${print_status}" == "OFF" ]]; then
        echo "Terminal Proxy test ${color}$(tput bold)SKIPPED$(tput sgr0), turn on terminal proxy first"
        return 0
    fi

    local suffix=", enjoy your surfing! ^_^"
    wget -q --spider --timeout=5 www.google.com
    error_code=$?
    if [[ $error_code == 0 ]]; then
        color=$(tput setaf 2)
        print_status="SUCCESS"
    else
        color=$(tput setaf 3)
        print_status="FAILED"
        suffix=", wget exit code: $(tput setaf 3)$(tput bold)${error_code}$(tput sgr0)"
    fi

    echo "Terminal Proxy test ${color}$(tput bold)${print_status}$(tput sgr0)${suffix}"
    if [[ $error_code != 0 ]]; then
        echo "Check wget man page on section EXIT STATUS for detailed proxy test failure reason"
    fi
}
