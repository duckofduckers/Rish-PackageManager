#!/bin/sh

if [ -z "$_SH_RUN" ]; then
    export _SH_RUN=1
    exec sh "$0" "$@"
fi

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
X='\033[0m'
DEBUG=0

echo_info() {
    if [ "${SILENT:-0}" -eq 0 ]; then
        echo "${BLUE}[*] $*${X}"
    fi
}
echo_warn() {
    if [ "${SILENT:-0}" -eq 0 ]; then
        echo "${YELLOW}[-] $*${X}"
    fi
}
echo_success() {
    if [ "${SILENT:-0}" -eq 0 ]; then
        echo "${GREEN}[+] $*${X}"
    fi
}
echo_error() {
    echo "${RED}[!] $*${X}"
}

if [ -z "${TERMUX_VERSION:-}" ]; then
    echo_error "This script must be ran in Termux"
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    echo_error "This script cannot be run as root"
    exit 1
fi

if cmd_path=$(command -v sh) && [ -n "$cmd_path" ]; then
    BIN=$(dirname "$cmd_path")
else
    BIN="${PREFIX}/bin"
    if [ ! -d "$BIN" ]; then
        echo_error "BIN directory could not be found, you have a weird ass environment"
        unset cmd_path
        exit 1
    fi
fi
unset cmd_path

for tool in mktemp curl unzip sed chmod mv rm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo_error "Required tool '$tool' is not available"
        exit 1
    fi
done

ARG="${1:-}"
MODE=""
SUBFLAG=""
HAS_ONLINE=0
HAS_OFFLINE=0

case "$ARG" in
    -install:*|-reinstall:*|-uninstall:*)
        MODE=$(echo "$ARG" | cut -d':' -f1)
        SUBFLAG_RAW=$(echo "$ARG" | cut -d':' -f2-)
        ;;
    -install|-reinstall|-uninstall)
        MODE="$ARG"
        SUBFLAG_RAW=""
        ;;
    *)
        echo_info "Usage: -install[:online|:offline][:silent]|-reinstall[:online|:offline][:silent]|-uninstall[:silent]"
        exit 1
        ;;
esac

if [ -n "$SUBFLAG_RAW" ]; then
    OLD_IFS="$IFS"
    IFS=':'
    for sf in $SUBFLAG_RAW; do
        case "$sf" in
            online)   SUBFLAG="online";   HAS_ONLINE=1 ;;
            offline)  SUBFLAG="offline";  HAS_OFFLINE=1 ;;
            silent)   SILENT=1 ;;
            *)        echo_error "Invalid subflag: $sf"; exit 1 ;;
        esac
    done
    IFS="$OLD_IFS"
fi

if [ "$HAS_ONLINE" -eq 1 ] && [ "$HAS_OFFLINE" -eq 1 ]; then
    echo_error "Cannot use both online and offline subflags together"
    exit 1
fi

if [ "$MODE" = "-reinstall" ]; then
    ANY_FOUND=false
    for NAME in rish rish_shizuku.dex; do
        FILEPATH="$BIN/$NAME"
        if [ -f "$FILEPATH" ]; then
            echo_warn "Uninstalling $NAME..."
            if rm -f "$FILEPATH"; then
                echo_success "$NAME uninstalled successfully"
                ANY_FOUND=true
            else
                echo_error "Failed to uninstall $NAME"
                exit 1
            fi
        else
            echo_warn "$NAME not found"
        fi
    done
    if [ "$ANY_FOUND" = false ]; then
        echo_info "No rish files found"
    fi
    MODE="-install"
fi

if [ "$MODE" = "-install" ]; then
    echo_warn "Creating temporary directory..."
    TMP=$(mktemp -d) || { echo_error "Failed to create temporary directory"; exit 1; }
    echo_success "Temporary directory created: $TMP"

    cleanup_temp() {
        if [ -n "$TMP" ] && [ -d "$TMP" ]; then
            rm -rf "$TMP"
        fi
        exit 1
    }

    trap 'cleanup_temp' INT
    trap 'if [ "$INSTALL_SUCCESS" -ne 1 ]; then cleanup_temp; fi' EXIT

    MISSING=false
    for NAME in rish rish_shizuku.dex; do
        if [ -f "$BIN/$NAME" ]; then
            echo_warn "$NAME found"
        else
            MISSING=true
        fi
    done

    if [ "$MISSING" = false ]; then
        echo_info "rish files already exist"
        INSTALL_SUCCESS=1
        echo_warn "Cleaning up temporary directory..."
        rm -rf "$TMP"
        echo_success "Temporary directory removed"
        trap - INT EXIT
        unset RED GREEN BLUE YELLOW X BIN MODE SUBFLAG MISSING NAME INSTALL_SUCCESS TMP DEBUG SILENT HAS_ONLINE HAS_OFFLINE
        unset -f cleanup_temp echo_info echo_warn echo_success echo_error
        exit 0
    fi

    APK_FILE="$TMP/Shizuku.apk"
    SHIZUKU_PATH=""
    APK_OBTAINED=false

    if [ -z "$SUBFLAG" ]; then
        if command -v cmd >/dev/null 2>&1; then
            SHIZUKU_PATH=$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | grep -oE 'package:(.*)' | sed 's/package://') || SHIZUKU_PATH=""
        fi
        if [ -n "$SHIZUKU_PATH" ] && [ -f "$SHIZUKU_PATH" ]; then
            echo_warn "Shizuku found locally, copying APK..."
            if cp "$SHIZUKU_PATH" "$APK_FILE" 2>/dev/null; then
                echo_success "Shizuku APK copied from local installation"
                APK_OBTAINED=true
            else
                echo_error "Failed to copy Shizuku APK, falling back to download"
                SHIZUKU_PATH=""
            fi
        fi
        if [ "$APK_OBTAINED" = false ]; then
            echo_warn "Downloading Shizuku APK from GitHub..."
            API_URL="https://api.github.com/repos/RikkaApps/Shizuku/releases/latest"
            if [ "$DEBUG" -eq 1 ]; then
                APK_URL=$(curl -fsSL "$API_URL" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            else
                APK_URL=$(curl -fsSL "$API_URL" 2>/dev/null | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            fi
            if [ -z "$APK_URL" ]; then
                echo_error "Shizuku APK downloaded unsuccessfully"
                exit 1
            fi
            if [ "$DEBUG" -eq 1 ]; then
                if ! curl -fsSL -o "$APK_FILE" "$APK_URL"; then
                    echo_error "Shizuku APK downloaded unsuccessfully"
                    exit 1
                fi
            else
                if ! curl -fsSL -o "$APK_FILE" "$APK_URL" 2>/dev/null; then
                    echo_error "Shizuku APK downloaded unsuccessfully"
                    exit 1
                fi
            fi
            echo_success "Shizuku APK downloaded successfully"
            APK_OBTAINED=true
        fi
    elif [ "$SUBFLAG" = "online" ]; then
        echo_warn "Downloading Shizuku APK from GitHub..."
        API_URL="https://api.github.com/repos/RikkaApps/Shizuku/releases/latest"
        if [ "$DEBUG" -eq 1 ]; then
            APK_URL=$(curl -fsSL "$API_URL" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        else
            APK_URL=$(curl -fsSL "$API_URL" 2>/dev/null | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        fi
        if [ -z "$APK_URL" ]; then
            echo_error "Shizuku APK downloaded unsuccessfully"
            exit 1
        fi
        if [ "$DEBUG" -eq 1 ]; then
            if ! curl -fsSL -o "$APK_FILE" "$APK_URL"; then
                echo_error "Shizuku APK downloaded unsuccessfully"
                exit 1
            fi
        else
            if ! curl -fsSL -o "$APK_FILE" "$APK_URL" 2>/dev/null; then
                echo_error "Shizuku APK downloaded unsuccessfully"
                exit 1
            fi
        fi
        echo_success "Shizuku APK downloaded successfully"
        APK_OBTAINED=true
    elif [ "$SUBFLAG" = "offline" ]; then
        if command -v cmd >/dev/null 2>&1; then
            SHIZUKU_PATH=$(cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null | grep -oE 'package:(.*)' | sed 's/package://') || SHIZUKU_PATH=""
        fi
        if [ -n "$SHIZUKU_PATH" ] && [ -f "$SHIZUKU_PATH" ]; then
            echo_warn "Shizuku found locally, copying APK..."
            if cp "$SHIZUKU_PATH" "$APK_FILE" 2>/dev/null; then
                echo_success "Shizuku APK copied from local installation"
                APK_OBTAINED=true
            else
                echo_error "Failed to copy Shizuku APK"
                exit 1
            fi
        else
            echo_error "Shizuku not found locally"
            exit 1
        fi
    fi

    if [ "$APK_OBTAINED" != true ]; then
        exit 1
    fi

    EXTRACT_FAILED=false
    for NAME in rish rish_shizuku.dex; do
        echo_warn "Extracting $NAME"
        if ! unzip -p "$APK_FILE" "assets/$NAME" > "$TMP/$NAME" 2>/dev/null; then
            echo_error "$NAME extracted unsuccessfully"
            EXTRACT_FAILED=true
            break
        else
            echo_success "$NAME extracted successfully"
        fi
    done

    if [ "$EXTRACT_FAILED" = true ]; then
        exit 1
    fi

    PKG_NAME=$(echo "$BIN" | sed 's|^/data/data/||' | cut -d'/' -f1)
    echo_warn "Detected package name: $PKG_NAME"

    echo_warn "Patching rish with package name..."
    if ! sed -i "s/RISH_APPLICATION_ID=\"PKG\"/RISH_APPLICATION_ID=\"${PKG_NAME}\"/" "$TMP/rish"; then
        echo_error "rish patched unsuccessfully"
        exit 1
    else
        echo_success "rish patched successfully"
    fi

    echo_warn "Setting executable permissions on rish..."
    if ! chmod +x "$TMP/rish"; then
        echo_error "Failed to set executable permissions on rish"
        exit 1
    else
        echo_success "Executable permissions set"
    fi

    for NAME in rish rish_shizuku.dex; do
        echo_warn "Moving $NAME to $BIN..."
        if ! mv "$TMP/$NAME" "$BIN/"; then
            echo_error "Failed to move $NAME to $BIN"
            exit 1
        else
            echo_success "$NAME moved successfully"
        fi
        if [ ! -f "$BIN/$NAME" ]; then
            echo_error "$NAME not found after move"
            exit 1
        fi
    done

    echo_warn "Cleaning up temporary directory..."
    rm -rf "$TMP"
    echo_success "Temporary directory removed"

    INSTALL_SUCCESS=1
    trap - INT EXIT
    echo_success "Installation completed successfully"
    unset RED GREEN BLUE YELLOW X BIN MODE SUBFLAG MISSING NAME API_URL APK_URL TMP APK_FILE EXTRACT_FAILED INSTALL_SUCCESS SHIZUKU_PATH PKG_NAME APK_OBTAINED DEBUG SILENT HAS_ONLINE HAS_OFFLINE
    unset -f cleanup_temp echo_info echo_warn echo_success echo_error
    exit 0
fi

if [ "$MODE" = "-uninstall" ]; then
    ANY_DELETED=false
    for NAME in rish rish_shizuku.dex; do
        FILEPATH="$BIN/$NAME"
        if [ -f "$FILEPATH" ]; then
            echo_warn "Uninstalling $NAME..."
            if rm -f "$FILEPATH"; then
                echo_success "$NAME uninstalled successfully"
                ANY_DELETED=true
            else
                echo_error "Failed to remove $NAME"
                exit 1
            fi
        else
            echo_warn "$NAME not found"
        fi
    done
    if [ "$ANY_DELETED" = false ]; then
        echo_info "No rish files found"
    fi
    unset RED GREEN BLUE YELLOW X BIN MODE SUBFLAG ANY_DELETED NAME FILEPATH DEBUG SILENT HAS_ONLINE HAS_OFFLINE
    unset -f echo_info echo_warn echo_success echo_error
    exit 0
fi
