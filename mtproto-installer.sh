#!/usr/bin/env bash

set -e

VERSION="0.1.0"

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m"

clear

echo -e "${CYAN}"
echo "========================================"
echo "      MTProto Installer v${VERSION}"
echo "========================================"
echo -e "${NC}"

echo "Supported:"
echo " • Ubuntu 22.04"
echo " • Ubuntu 24.04"
echo " • Ubuntu 26.xx"
echo

echo "1) Install MTProto Proxy"
echo "2) Show Status"
echo "3) Exit"
echo

read -rp "Select: " CHOICE

case "$CHOICE" in
1)
    echo
    echo -e "${GREEN}Installation module will be implemented in v0.2${NC}"
    ;;
2)
    echo
    if docker ps --format '{{.Names}}' | grep -q "^tg_proxy$"; then
        echo -e "${GREEN}MTProto Proxy is running.${NC}"
    else
        echo -e "${RED}MTProto Proxy is not running.${NC}"
    fi
    ;;
3)
    exit 0
    ;;
*)
    echo -e "${RED}Invalid selection.${NC}"
    ;;
esac
