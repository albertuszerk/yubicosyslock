#!/bin/bash
# Project: X-SysLock v1.1 (Safe-Guard Edition)
# Version: 1.1.1
# Hotfix: Apt-Lock-Check & Error-Handling

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Funktion: Prüfung auf aktive Updates (Apt-Lock) ---
check_apt_lock() {
    echo -e "${BLUE}[*] Pruefe Systemzugriff...${NC}"
    if fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        echo -e "${RED}FEHLER: System-Update aktiv!${NC}"
        echo "Ein anderes Programm installiert gerade Software."
        echo "Bitte beenden Sie das Update und starten Sie dieses Setup erneut."
        exit 1
    fi
}

# --- Interaktiver Start ---
clear
echo -e "${BLUE}=== X-SysLock Installer v1.1 (Safe-Guard) ===${NC}"
check_apt_lock

read -p "Moechten Sie das Setup jetzt starten? (j/n): " confirm
[[ ! $confirm =~ ^[Jj]$ ]] && exit 1

# --- Variablen ---
SCRIPT_DIR="$HOME/.yubikey-tool"
APP_DIR="$HOME/.local/share/applications"
KEY_FILE="$HOME/.config/Yubico/u2f_keys"

# 1. Software-Installation mit Erfolgskontrolle
echo -e "${BLUE}[1/4] Installiere Software...${NC}"
sudo apt update
if ! sudo apt install -y libpam-u2f pamu2fcfg yubikey-manager-qt zenity; then
    echo -e "${RED}FEHLER: Software konnte nicht installiert werden!${NC}"
    echo "Abbruch, um System-Aussperrung zu verhindern."
    exit 1
fi

mkdir -p "$SCRIPT_DIR"
mkdir -p "$HOME/.config/Yubico"

# 2. Scripte schreiben (Nur wenn Software vorhanden ist)
echo -e "${BLUE}[2/4] Konfiguriere System-Logik...${NC}"

# --- Setup Script (Optimierte Schreib-Logik ohne SED) ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-setup.sh"
#!/bin/bash
KEY_FILE="$HOME/.config/Yubico/u2f_keys"
mkdir -p "$HOME/.config/Yubico"

clear
echo -e "\033[0;34m=== YubiKey BESTAETIGUNG (X-SysLock v1.1) ===\033[0m"

if [ -f "$KEY_FILE" ] && [ -s "$KEY_FILE" ]; then
    echo "Modus: Weiteren Backup-Key hinzufuegen..."
    NEW_KEY=$(pamu2fcfg -n | tr -d '\n' | tr -d '\r')
    if [ ! -z "$NEW_KEY" ]; then
        OLD_CONTENT=$(cat "$KEY_FILE" | tr -d '\n' | tr -d '\r')
        echo -n "${OLD_CONTENT}:${NEW_KEY}" > "$KEY_FILE"
        echo "" >> "$KEY_FILE"
    fi
else
    echo "Modus: Mit YubiKey anmelden / Ersten Key bestaetigen..."
    pamu2fcfg | tr -d '\n' | tr -d '\r' > "$KEY_FILE"
    echo "" >> "$KEY_FILE"
fi
chmod 600 "$KEY_FILE"

# PAM-Integration (Wichtig: Erst hier werden Dateien geaendert!)
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && ! sudo grep -q "pam_u2f.so" "$FILE"; then
        sudo cp "$FILE" "${FILE}.original.bak"
        sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' "$FILE"
    fi
done
echo "Abgeschlossen."; sleep 2
EOF

# --- Uninstall Script ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-uninstall.sh"
#!/bin/bash
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && sudo grep -q "pam_u2f.so" "$FILE"; then
        [ -f "${FILE}.original.bak" ] && sudo mv "${FILE}.original.bak" "$FILE" || sudo sed -i '/pam_u2f.so/d' "$FILE"
    fi
done
rm -rf "$HOME/.config/Yubico"
echo "System bereinigt."; sleep 2
EOF

# --- GUI Control Script ---
cat <<EOF > "$SCRIPT_DIR/yubi-control.sh"
#!/bin/bash
KEY_FILE="\$HOME/.config/Yubico/u2f_keys"
count_keys() {
    [ -f "\$KEY_FILE" ] && grep -o ":" "\$KEY_FILE" | wc -l || echo 0
}

while true; do
    NUM=\$(count_keys)
    if [ \$NUM -eq 0 ]; then STATUS="<span color='red'><b>KRITISCH: Kein Schluessel registriert!</b></span>"
    elif [ \$NUM -eq 1 ]; then STATUS="<span color='orange'><b>! WARNUNG: Nur 1 Schluessel (Aussperrgefahr!)</b></span>"
    else STATUS="<span color='green'><b>! ERFOLG: Mind. 2 Schluessel wurden registriert.</b></span>"; fi

    CHOICE=\$(zenity --list --width=550 --height=450 --title="X-SysLock v1.1" --text="\$STATUS\n\nAuswahl:" \
        --column="Aktion" --column="Beschreibung" \
        "Schluessel hinzufuegen" "Backup-Key registrieren" \
        "Kompletter Reset" "Keys loeschen & neu anmelden" \
        "Editieren" "YubiKey Manager" \
        "Deinstallieren" "Tool entfernen" \
        "Beenden" "Menue verlassen")

    case \$CHOICE in
        "Schluessel hinzufuegen") gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh" ;;
        "Kompletter Reset") [ -f "\$KEY_FILE" ] && rm "\$KEY_FILE" && gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh" ;;
        "Editieren") ykman-gui ;;
        "Deinstallieren") gnome-terminal --wait -- "$SCRIPT_DIR/yubi-uninstall.sh" && rm "$APP_DIR/yubikey-manager.desktop" && break ;;
        *) break ;;
    esac
done
EOF

chmod +x "$SCRIPT_DIR"/*.sh

# 3. Menueeintrag
cat <<EOF > "$APP_DIR/yubikey-manager.desktop"
[Desktop Entry]
Version=1.1
Type=Application
Name=X-SysLock
Comment=YubiKey 5 Series Login Manager
Exec=gnome-terminal -- bash -c "$SCRIPT_DIR/yubi-control.sh"
Icon=security-high
Terminal=false
Categories=System;Security;
EOF

chmod +x "$APP_DIR/yubikey-manager.desktop"
update-desktop-database "$APP_DIR"
echo -e "${GREEN}=== INSTALLATION ERFOLGREICH! ===${NC}"
