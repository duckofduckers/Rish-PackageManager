#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
X='\033[0m'

[ -z "${BASH_VERSION:-}" ] && echo "${RED}[!] This script must be run with bash" && exit 1

BIN="/data/data/com.termux/files/usr/bin"
RISH_BIN="$BIN/rish"
DEX_BIN="$BIN/rish_shizuku.dex"

MODE="${1,,}"

if [[ "$MODE" != "-install" && "$MODE" != "-uninstall" ]]; then
    echo -e "${RED}[!] Usage: $0 [-install|-uninstall]${X}"
    exit 1
fi

declare -A FILES=(
    ["rish"]="https://github.com/duckofduckers/Shizuku-Rish-Setup/raw/main/rish"
    ["rish_shizuku.dex"]="https://github.com/duckofduckers/Shizuku-Rish-Setup/raw/main/rish_shizuku.dex"
)

if [[ "$MODE" == "-install" ]]; then
    ALL_EXIST=true
    for NAME in "${!FILES[@]}"; do
        FILEPATH="$BIN/$NAME"
        URL="${FILES[$NAME]}"
        if [[ -f "$FILEPATH" ]]; then
            echo -e "${YELLOW}[-] $NAME found${X}"
        else
            ALL_EXIST=false
            echo -e "${YELLOW}[-] Installing $NAME...${X}"
            curl -fsS -L -o "$FILEPATH" "$URL"
            if [[ "$NAME" == "rish" ]]; then
                chmod +x "$FILEPATH"
            fi
            if [[ -f "$FILEPATH" ]]; then
                echo -e "${GREEN}[*] $NAME installed successfully${X}"
            else
                echo -e "${RED}[!] $NAME not installed successfully${X}"
            fi
        fi
    done
    if [[ "$ALL_EXIST" == true ]]; then
        echo -e "${BLUE}[*] rish files already exist${X}"
    fi
elif [[ "$MODE" == "-uninstall" ]]; then
    ANY_DELETED=false
    for NAME in "${!FILES[@]}"; do
        FILEPATH="$BIN/$NAME"
        if [[ -f "$FILEPATH" ]]; then
            echo -e "${YELLOW}[-] Uninstalling $NAME...${X}"
            rm -f "$FILEPATH"
            if [[ ! -f "$FILEPATH" ]]; then
                echo -e "${GREEN}[*] $NAME uninstalled successfully${X}"
                ANY_DELETED=true
            fi
        else
            echo -e "${YELLOW}[-] $NAME not found${X}"
        fi
    done
    if [[ "$ANY_DELETED" == false ]]; then
        echo -e "${BLUE}[+] No rish files found${X}"
    fi
fi

unset RED GREEN BLUE YELLOW X BIN RISH_BIN DEX_BIN MODE FILES ALL_EXIST ANY_DELETED NAME FILEPATH URL
