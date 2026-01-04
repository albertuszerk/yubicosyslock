#!/bin/bash

# Project: X-SysLock, login for Linux (YubiKey 5 Series)
# Repository: https://github.com/albertuszerk/yubicosyslock
# License: CC BY-NC-SA 4.0

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Interaktiver Start ---
clear
echo -e "${BLUE}=== X-SysLock Installer v1.0 ===${NC}"
echo "Dieses Script konfiguriert Ihren YubiKey fuer den Linux-Login."
echo ""
read -p "Moechten Sie die Installation von X-SysLock jetzt starten? (j/n): " confirm
if [[ ! $confirm =~ ^[Jj]$ ]]; then
    echo "Installation abgebrochen."
    exit 1
fi

# --- Variablen ---
SCRIPT_DIR="$HOME/.yubikey-tool"
APP_DIR="$HOME/.local/share/applications"

# 1. Software-Installation
echo -e "${BLUE}[1/4] Installiere Software (PAM, Ykman GUI, Zenity)...${NC}"
sudo apt update && sudo apt install -y libpam-u2f pamu2fcfg yubikey-manager-qt zenity

mkdir -p "$SCRIPT_DIR"

# 2. Scripte schreiben
echo -e "${BLUE}[2/4] Konfiguriere System-Logik...${NC}"

# --- Setup Script mit PIN-Erklaerung ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-setup.sh"
#!/bin/bash
clear
echo -e "\033[0;34m=== YubiKey REGISTRIERUNG ===\033[0m"
echo ""
echo "WICHTIGE PIN-INFORMATION:"
echo "Wenn Sie nach einer PIN gefragt werden, ist dies die FIDO2-PIN."
echo ""
echo "Hintergrund - Die 3 Standard-PINs eines YubiKeys:"
echo "1. FIDO2-PIN: (Standard: leer/nicht gesetzt). Schuetzt den Login."
echo "2. PIV-PIN:   (Standard: 123456). Fuer Zertifikate/Smartcards."
echo "3. Admin-PIN: (Standard: 12345678). Zum Entsperren des Sticks."
echo "-------------------------------------------------------"
echo ""
KEY_FILE="$HOME/.config/Yubico/u2f_keys"
mkdir -p "$HOME/.config/Yubico"
echo "Schritt 1: FIDO2-PIN tippen (falls gesetzt) + ENTER"
echo "Schritt 2: Wenn der YubiKey blinkt, Goldkontakt beruehren."
echo ""
pamu2fcfg > "$KEY_FILE" || { echo "Fehler bei der Registrierung!"; sleep 5; exit 1; }
chmod 600 "$KEY_FILE"
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && ! sudo grep -q "pam_u2f.so" "$FILE"; then
        sudo cp "$FILE" "${FILE}.original.bak"
        sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' "$FILE"
    fi
done
echo ""
echo "ERFOLG: X-SysLock ist nun fuer Login und Sudo aktiv."; sleep 4
EOF

# --- Uninstall Script ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-uninstall.sh"
#!/bin/bash
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && sudo grep -q "pam_u2f.so" "$FILE"; then
        if [ -f "${FILE}.original.bak" ]; then
            sudo mv "${FILE}.original.bak" "$FILE"
        else
            sudo sed -i '/pam_u2f.so/d' "$FILE"
        fi
    fi
done
rm -rf "$HOME/.config/Yubico"
echo "System bereinigt. X-SysLock wurde entfernt."; sleep 3
EOF

# --- GUI Control Script ---
cat <<EOF > "$SCRIPT_DIR/yubi-control.sh"
#!/bin/bash
CHOICE=\$(zenity --list --width=500 --height=400 \\
    --title="X-SysLock - Management" \\
    --column="Aktion" --column="Beschreibung" \\
    "Aktivieren" "Hardware-Login einschalten (Passwort + Key)" \\
    "Editieren" "YubiKey Manager (PINs & Defaults verwalten)" \\
    "Deinstallieren" "System bereinigen & Tool entfernen" \\
    "Abbrechen" "Menue verlassen")

case \$CHOICE in
    "Aktivieren") gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh" ;;
    "Editieren") ykman-gui ;;
    "Deinstallieren") 
        if zenity --question --text="Moechten Sie X-SysLock wirklich komplett entfernen?"; then
            gnome-terminal --wait -- "$SCRIPT_DIR/yubi-uninstall.sh"
            rm "$APP_DIR/yubikey-manager.desktop"
            zenity --info --text="Deinstallation abgeschlossen."
        fi ;;
    *) exit ;;
esac
EOF

chmod +x "$SCRIPT_DIR"/*.sh

# 3. Menueeintrag (Desktop Entry)
cat <<EOF > "$APP_DIR/yubikey-manager.desktop"
[Desktop Entry]
Version=1.0
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
echo ""
echo -e "${GREEN}=== INSTALLATION ERFOLGREICH! ===${NC}"
echo "Sie finden 'X-SysLock' jetzt in Ihrem Menue unter Systemwerkzeuge."
