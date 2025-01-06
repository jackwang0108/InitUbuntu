#!/bin/env bash

function install_clash() {
    # FILE_PATH will be substituted by sed in Makefile
    MODULE_DIR=$(dirname FILE_PATH)
    echo "install clash"

    echo "${MODULE_DIR}"
}
