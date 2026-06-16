#!/bin/bash
set -euo pipefail 

# ==========================================
generate_config_file() {
    TEMPLATE=$1
    OUT_DIR=$2
    OUT="$OUT_DIR/"$3

    if [[ ! -f "$TEMPLATE" ]]; then
        echo "ERROR: template file '$TEMPLATE' not found." >&2
        return 1
    fi

    mkdir -p "$OUT_DIR"

    TMP="$(mktemp "${OUT}.tmp.XXXXXX")"
    trap 'rm -f "$TMP"' EXIT

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line//\$USER_NAME/$USER_NAME}"
        line="${line//\$USER_PASSWORD/$USER_PASSWORD}"
        line="${line//\$USER_UID/$USER_UID}" 
        printf '%s\n' "$line" >> "$TMP"
    done < "$TEMPLATE"

    if grep -q '\$USER_' "$TMP"; then
        echo "Warning: Template still contains unsubstituted \$USER_ variables." >&2
    fi

    chmod 600 "$TMP"
    mv "$TMP" "$OUT"
    trap - EXIT
}

# ==========================================
if [ -z "$USER_NAME" ] ||[ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
    echo "ERROR: USER_NAME, USER_UID, or USER_GID environment variable is not set. Container stopped."
    exit 1
fi

# ==========================================
mkdir -p /tmp/log
mkdir -p /tmp/extrausers

# ==========================================
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
    echo "$USER_NAME:x:$USER_UID:$USER_GID::/home/$USER_NAME:/bin/bash" > /tmp/extrausers/passwd
    
    SUDO_GID=$(getent group sudo | cut -d: -f3)
    echo "$USER_NAME:x:$USER_GID:" > /tmp/extrausers/group
    echo "sudo:x:$SUDO_GID:$USER_NAME" >> /tmp/extrausers/group
    
    if [ -z "$USER_PASSWORD" ]; then
        echo "$USER_NAME::19000:0:99999:7:::" > /tmp/extrausers/shadow
    else
        HASH=$(openssl passwd -6 "$USER_PASSWORD")
        echo "$USER_NAME:$HASH:19000:0:99999:7:::" > /tmp/extrausers/shadow
    fi
    
    chmod 0644 /tmp/extrausers/passwd /tmp/extrausers/group
    chmod 0640 /tmp/extrausers/shadow
    chown root:shadow /tmp/extrausers/shadow
fi

HOME_DIR="/home/$USER_NAME"

if [ ! -d "$HOME_DIR" ]; then
    sudo -u "$USER_NAME" mkdir -p "$HOME_DIR"
fi

mkdir -p /tmp/run/user/$USER_UID
chown $USER_UID:$USER_GID /tmp/run/user/$USER_UID
chmod 0700 /tmp/run/user/$USER_UID

# ==========================================
if [ ! -f "$HOME_DIR/.bashrc" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee -a "$HOME_DIR/.bashrc" > /dev/null
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
fi

CS_USER_DIR="/home/$USER_NAME/.local/share/code-server/User"
if  [ ! -f "$CS_USER_DIR/settings.json" ]; then
    sudo -u "$USER_NAME" mkdir -p "$CS_USER_DIR"
    sudo -u "$USER_NAME" cp /usr/local/etc/settings.json "$CS_USER_DIR/settings.json"
fi
CS_DATA_DIR="$HOME_DIR/.local/share/code-server"
sudo -u "$USER_NAME" mkdir -p "$CS_DATA_DIR"

if [ -f "/usr/local/bin/custom-setup.sh" ]; then
    /usr/local/bin/custom-setup.sh
fi

# ==========================================
generate_config_file "/usr/local/etc/supervisord-template.conf" "/tmp" "supervisord.conf"
if [ -z "$SUPERVISOR_LOG" ]; then
    echo "ERROR: SUPERVISOR_LOG environment variable is not set. Container stopped."
    exit 1
fi
SUPERVISOR_LOG="-s"
if [ "$SUPERVISOR_LOG" = "on" ] || [ "$SUPERVISOR_LOG" = "ON" ]; then
    SUPERVISOR_LOG=""
fi
exec supervisord $SUPERVISOR_LOG -n -c /tmp/supervisord.conf
