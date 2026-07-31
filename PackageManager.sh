#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
X='\033[0m'

[ -z "${BASH_VERSION:-}" ] && echo "${RED}[!] This script must be run with bash" && exit 1
[ -z "${TERMUX_VERSION:-}" ] && echo "${RED}[!] This script must be ran in Termux" && exit 1

if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}[!] This script cannot be run as root${X}"
    exit 1
fi

if cmd_path=$(command -v sh) && [ -n "$cmd_path" ]; then
    BIN=$(dirname "$cmd_path")
else
    BIN="${PREFIX}/bin"
    if [ ! -d "$BIN" ]; then
        echo -e "${RED}[!] BIN directory could not be found, you have a weird ass environment${X}"
        unset cmd_path
        exit 1
    fi
fi
unset cmd_path
MODE="${1,,}"

if [[ "$MODE" != "-install" && "$MODE" != "-uninstall" && "$MODE" != "-reinstall" ]]; then
    echo -e "${BLUE}[*] Usage: [-install|-uninstall|-reinstall]${X}"
    exit 1
fi

if [[ "$MODE" == "-reinstall" ]]; then
    ANY_FOUND=false
    for NAME in rish rish_shizuku.dex; do
        FILEPATH="$BIN/$NAME"
        if [[ -f "$FILEPATH" ]]; then
            echo -e "${YELLOW}[-] Uninstalling $NAME...${X}"
            rm -f "$FILEPATH"
            echo -e "${GREEN}[+] $NAME uninstalled successfully${X}"
            ANY_FOUND=true
        else
            echo -e "${YELLOW}[-] $NAME not found${X}"
        fi
    done
    if [[ "$ANY_FOUND" == false ]]; then
        echo -e "${BLUE}[*] No rish files found${X}"
        exit 0
    fi
    MODE="-install"
fi

if [[ "$MODE" == "-install" ]]; then
    TMP=$(mktemp -d) || { echo -e "${RED}[!] Failed to create temporary directory${X}"; exit 1; }

    cleanup_temp() {
        [[ -n "$TMP" && -d "$TMP" ]] && rm -rf "$TMP"
        exit 1
    }

    trap 'cleanup_temp' SIGINT
    trap '[[ $INSTALL_SUCCESS -eq 1 ]] || cleanup_temp' EXIT

    MISSING=false
    for NAME in rish rish_shizuku.dex; do
        if [[ -f "$BIN/$NAME" ]]; then
            echo -e "${YELLOW}[-] $NAME found${X}"
        else
            MISSING=true
        fi
    done

    if [[ "$MISSING" == false ]]; then
        echo -e "${BLUE}[*] rish files already exist${X}"
        INSTALL_SUCCESS=1
        rm -rf "$TMP"
        trap - EXIT SIGINT
        unset RED GREEN BLUE YELLOW X BIN MODE MISSING NAME INSTALL_SUCCESS TMP
        unset -f cleanup_temp
        exit 0
    fi

    APK_FILE="$TMP/Shizuku.apk"
    SHIZUKU_PATH=""
    if command -v cmd >/dev/null 2>&1; then
        SHIZUKU_PATH=$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | grep -oE 'package:(.*)' | sed 's/package://')
    fi

    if [[ -n "$SHIZUKU_PATH" && -f "$SHIZUKU_PATH" ]]; then
        echo -e "${YELLOW}[-] Shizuku found locally, copying APK...${X}"
        if cp "$SHIZUKU_PATH" "$APK_FILE" 2>/dev/null; then
            echo -e "${GREEN}[+] Shizuku APK copied from local installation${X}"
        else
            echo -e "${RED}[!] Failed to copy Shizuku APK, falling back to download${X}"
            SHIZUKU_PATH=""
        fi
    fi

    if [[ -z "$SHIZUKU_PATH" ]]; then
        echo -e "${YELLOW}[-] Downloading Shizuku APK from GitHub...${X}"
        API_URL="https://api.github.com/repos/RikkaApps/Shizuku/releases/latest"
        APK_URL=$(curl -fsSL "$API_URL" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        if [[ -z "$APK_URL" ]]; then
            echo -e "${RED}[!] Shizuku APK downloaded unsuccessfully${X}"
            exit 1
        fi

        if ! curl -fsSL -o "$APK_FILE" "$APK_URL"; then
            echo -e "${RED}[!] Shizuku APK downloaded unsuccessfully${X}"
            exit 1
        fi
        echo -e "${GREEN}[+] Shizuku APK downloaded successfully${X}"
    fi

    EXTRACT_FAILED=false
    for NAME in rish rish_shizuku.dex; do
        echo -e "${YELLOW}[-] Extracting $NAME${X}"
        if ! unzip -p "$APK_FILE" "assets/$NAME" > "$TMP/$NAME" 2>/dev/null; then
            echo -e "${RED}[!] $NAME extracted unsuccessfully${X}"
            EXTRACT_FAILED=true
            break
        else
            echo -e "${GREEN}[+] $NAME extracted successfully${X}"
        fi
    done

    if [[ "$EXTRACT_FAILED" == true ]]; then
        exit 1
    fi

    PKG_NAME="${HOME#/data/data/}"
    PKG_NAME="${PKG_NAME%%/*}"

    echo -e "${YELLOW}[-] Patching rish${X}"
    if sed -i "s/RISH_APPLICATION_ID=\"PKG\"/RISH_APPLICATION_ID=\"${PKG_NAME}\"/" "$TMP/rish"; then
        echo -e "${GREEN}[+] rish patched successfully${X}"
    else
        echo -e "${RED}[!] rish patched unsuccessfully${X}"
        exit 1
    fi

    chmod +x "$TMP/rish"

    for NAME in rish rish_shizuku.dex; do
        mv "$TMP/$NAME" "$BIN/"
        if [[ ! -f "$BIN/$NAME" ]]; then
            exit 1
        fi
    done

    rm -rf "$TMP"
    INSTALL_SUCCESS=1
    trap - EXIT SIGINT
    unset RED GREEN BLUE YELLOW X BIN MODE MISSING NAME API_URL APK_URL TMP APK_FILE EXTRACT_FAILED INSTALL_SUCCESS SHIZUKU_PATH PKG_NAME
    unset -f cleanup_temp
    exit 0
fi

if [[ "$MODE" == "-uninstall" ]]; then
    ANY_DELETED=false
    for NAME in rish rish_shizuku.dex; do
        FILEPATH="$BIN/$NAME"
        if [[ -f "$FILEPATH" ]]; then
            echo -e "${YELLOW}[-] Uninstalling $NAME...${X}"
            rm -f "$FILEPATH"
            if [[ ! -f "$FILEPATH" ]]; then
                echo -e "${GREEN}[+] $NAME uninstalled successfully${X}"
                ANY_DELETED=true
            fi
        else
            echo -e "${YELLOW}[-] $NAME not found${X}"
        fi
    done
    if [[ "$ANY_DELETED" == false ]]; then
        echo -e "${BLUE}[*] No rish files found${X}"
    fi
    unset RED GREEN BLUE YELLOW X BIN MODE ANY_DELETED NAME FILEPATH
    exit 0
fi
