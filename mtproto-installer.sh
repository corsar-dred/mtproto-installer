#!/usr/bin/env bash

###############################################################################
#
# MTProto Installer
#
# Version : 0.2.0
# Author  : corsar-dred
# License : MIT
#
###############################################################################

set -e

VERSION="0.2.0"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
NC="\033[0m"

###############################################################################
# Functions
###############################################################################

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Please run this script as root.${NC}"
        exit 1
    fi
}

check_os() {

    if [[ ! -f /etc/os-release ]]; then
        echo -e "${RED}Unsupported operating system.${NC}"
        exit 1
    fi

    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        echo -e "${RED}Only Ubuntu is supported.${NC}"
        exit 1
    fi

    case "$VERSION_ID" in
        "22.04"|"24.04"|"26.04")
            ;;
        *)
            echo -e "${RED}Supported versions: Ubuntu 22.04 / 24.04 / 26.04${NC}"
            exit 1
            ;;
    esac
}

show_banner() {

    clear

    echo -e "${CYAN}"
    echo "===================================================="
    echo "               MTProto Installer"
    echo "===================================================="
    echo -e "${NC}"

    echo "Version : ${VERSION}"
    echo "System  : Ubuntu ${VERSION_ID}"
    echo
}

main_menu() {

    echo "1) Install MTProto Proxy"
    echo "2) Show Status"
    echo "3) About"
    echo "0) Exit"
    echo

    read -rp "Select: " CHOICE

    case "$CHOICE" in

        1)
            echo
            echo -e "${GREEN}Installation module will be implemented in v0.3${NC}"
            ;;

        2)
            echo

            if command -v docker >/dev/null 2>&1; then

                if docker ps --format '{{.Names}}' | grep -q "^tg_proxy$"; then
                    echo -e "${GREEN}MTProto Proxy is running.${NC}"
                else
                    echo -e "${YELLOW}MTProto Proxy is not running.${NC}"
                fi

            else

                echo -e "${RED}Docker is not installed.${NC}"

            fi

            ;;

        3)

            echo
            echo "MTProto Installer"
            echo "Version : ${VERSION}"
            echo "Author  : corsar-dred"
            echo "License : MIT"
            ;;

        0)
            exit 0
            ;;

        *)

            echo -e "${RED}Invalid selection.${NC}"

            ;;

    esac

}

###############################################################################
# Main
###############################################################################

main() {

    check_root
    check_os
    show_banner
    main_menu

}

main
