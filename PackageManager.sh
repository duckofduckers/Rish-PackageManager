#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
X='\033[0m'

[ -z "${BASH_VERSION:-}" ] && echo "${RED}[!] This script must be run with bash" && exit 1
[ -z "${TERMUX_VERSION:-}" ] && echo "${RED}[!] This script must be ran in Termux" && exit 1

BIN="/data/data/com.termux/files/usr/bin"
MODE="${1,,}"

if [[ "$MODE" != "-install" && "$MODE" != "-uninstall" ]]; then
    echo -e "${BLUE}[*] Usage: [-install|-uninstall]${X}"
    exit 1
fi

if [[ "$MODE" == "-install" ]]; then
    TMPDIR="${TMPDIR:-/tmp}"

    cleanup_temp() {
        local tmp_files=("$TMPDIR/Shizuku.apk" "$TMPDIR/rish" "$TMPDIR/rish_shizuku.dex")
        for f in "${tmp_files[@]}"; do
            [[ -f "$f" ]] && rm -f "$f"
        done
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
        trap - EXIT SIGINT
        unset RED GREEN BLUE YELLOW X BIN MODE MISSING NAME INSTALL_SUCCESS
        unset -f cleanup_temp
        exit 0
    fi

    echo -e "${YELLOW}[-] Downloading Shizuku APK from GitHub...${X}"
    API_URL="https://api.github.com/repos/RikkaApps/Shizuku/releases/latest"
    APK_URL=$(curl -fsSL "$API_URL" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    if [[ -z "$APK_URL" ]]; then
        echo -e "${RED}[!] Shizuku APK downloaded unsuccessfully${X}"
        exit 1
    fi

    APK_FILE="$TMPDIR/Shizuku.apk"
    if ! curl -fsSL -o "$APK_FILE" "$APK_URL"; then
        echo -e "${RED}[!] Shizuku APK downloaded unsuccessfully${X}"
        exit 1
    fi
    echo -e "${GREEN}[+] Shizuku APK downloaded successfully${X}"

    EXTRACT_FAILED=false
    for NAME in rish rish_shizuku.dex; do
        echo -e "${YELLOW}[-] Extracting $NAME${X}"
        if ! unzip -p "$APK_FILE" "assets/$NAME" > "$TMPDIR/$NAME" 2>/dev/null; then
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

    echo -e "${YELLOW}[-] Patching rish${X}"
    if sed -i 's/PKG/com.termux/g' "$TMPDIR/rish"; then
        echo -e "${GREEN}[+] rish patched successfully${X}"
    else
        echo -e "${RED}[!] rish patched unsuccessfully${X}"
        exit 1
    fi

    chmod +x "$TMPDIR/rish"

    for NAME in rish rish_shizuku.dex; do
        mv "$TMPDIR/$NAME" "$BIN/"
        if [[ ! -f "$BIN/$NAME" ]]; then
            exit 1
        fi
    done

    rm -f "$APK_FILE"
    INSTALL_SUCCESS=1
    trap - EXIT SIGINT
    unset RED GREEN BLUE YELLOW X BIN MODE MISSING NAME API_URL APK_URL TMPDIR APK_FILE EXTRACT_FAILED INSTALL_SUCCESS
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
        echo -e "${BLUE}[+] No rish files found${X}"
    fi
    unset RED GREEN BLUE YELLOW X BIN MODE ANY_DELETED NAME FILEPATH
    exit 0
fi
