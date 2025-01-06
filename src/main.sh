#!/bin/bash

FILE_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Get install functions
max_length=0
install_functions=()
while IFS= read -r line; do
    if [[ $line =~ ^function\ install.* ]]; then
        function_name=$(echo "$line" | awk '{print $2}' | sed 's/()//')
        install_functions+=("$function_name")
        len=${#function_name}
        # get the max length of function name, for pretty print
        if ((len > max_length)); then
            max_length=$len
        fi
    fi
done <"${FILE_DIR}/initUbuntu.sh"

# TODO: 添加换源
# TODO: 添加TUI交互

# parse args
while getopts "hitdc" opt; do
    case $opt in
    c)
        change_source
        ;;
    d)
        add_dependency
        ;;
    i)
        interactive_main "${max_length}" "${install_functions[@]}"
        ;;
    t)
        TUI_main "${install_functions[@]}"
        ;;
    h | *)
        usage "${max_length}" "${install_functions[@]}"
        exit 0
        ;;
    esac
done
