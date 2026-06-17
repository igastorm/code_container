#!/bin/bash
set -euo pipefail

# ==========================================
USER_NAME="${USER_NAME:-devenv}"

DETECTED_UID=$(stat -c '%u' /home)
DETECTED_GID=$(stat -c '%g' /home)

USER_UID="${USER_UID:-$DETECTED_UID}"
USER_GID="${USER_GID:-$DETECTED_GID}"

if [ "$USER_UID" -eq 0 ]; then
    USER_UID=1000
fi
if [ "$USER_GID" -eq 0 ]; then
    USER_GID=1000
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
    
    echo "$USER_NAME:*:19000:0:99999:7:::" > /tmp/extrausers/shadow
    
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
if [ -z "$LOG" ]; then
    echo "ERROR: LOG environment variable is not set. Container stopped."
    exit 1
fi

FLAG="> /dev/null 2>&1"
if [ "$LOG" = "on" ] || [ "$LOG" = "ON" ]; then
  FLAG=""
fi

exec sudo -u "$USER_NAME" /usr/local/code-server/bin/code-server \
    --bind-addr 0.0.0.0:3000 \
    --auth none \
    --disable-telemetry \
    --disable-update-check \
    --disable-workspace-trust $FLAG
