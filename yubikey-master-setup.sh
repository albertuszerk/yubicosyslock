#!/bin/bash
# Project: X-SysLock v1.1 (Konsolidierte Fassung)
# Repository: https://github.com/albertuszerk/yubicosyslock
# License: CC BY-NC-SA 4.0

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Interaktiver Start (aus v1.0) ---
clear
echo -e "${BLUE}=== X-SysLock Installer v1.1 ===${NC}"
echo "Dieses Script konfiguriert Ihren YubiKey fuer den Linux-Login."
echo "v1.1 Feature: Unterstuetzung fuer mehrere Backup-Keys."
echo ""
read -p "Moechten Sie die Installation von X-SysLock v1.1 jetzt starten? (j/n): " confirm
if [[ ! $confirm =~ ^[Jj]$ ]]; then
    echo "Installation abgebrochen."
    exit 1
fi

# --- Variablen ---
SCRIPT_DIR="$HOME/.yubikey-tool"
APP_DIR="$HOME/.local/share/applications"
KEY_FILE="$HOME/.config/Yubico/u2f_keys"

# 1. Software-Installation
echo -e "${BLUE}[1/4] Installiere Software (PAM, Ykman GUI, Zenity)...${NC}"
sudo apt update && sudo apt install -y libpam-u2f pamu2fcfg yubikey-manager-qt zenity
mkdir -p "$SCRIPT_DIR"
mkdir -p "$HOME/.config/Yubico"

# 2. Scripte schreiben (Konsolidierte Logik)
echo -e "${BLUE}[2/4] Konfiguriere System-Logik...${NC}"

# --- Setup Script (Erweitert um Multi-Key Support) ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-setup.sh"
#!/bin/bash
KEY_FILE="$HOME/.config/Yubico/u2f_keys"
mkdir -p "$HOME/.config/Yubico"

clear
echo -e "\033[0;34m=== YubiKey REGISTRIERUNG (X-SysLock v1.1) ===\033[0m"
echo ""
echo "Hintergrund - Die 3 Standard-PINs eines YubiKeys:"
echo "1. FIDO2-PIN: (Standard: leer). Schuetzt den Login."
echo "2. PIV-PIN:   (Standard: 123456). Fuer Zertifikate."
echo "3. Admin-PIN: (Standard: 12345678). Hardware-Verwaltung."
echo "-------------------------------------------------------"
echo ""

if [ -f "$KEY_FILE" ] && [ -s "$KEY_FILE" ]; then
    echo "Modus: Weiteren Backup-Key hinzufuegen..."
    pamu2fcfg >> "$KEY_FILE" || { echo "Fehler!"; sleep 3; exit 1; }
else
    echo "Modus: Ersten Hauptschluessel registrieren..."
    pamu2fcfg > "$KEY_FILE" || { echo "Fehler!"; sleep 3; exit 1; }
fi

chmod 600 "$KEY_FILE"

# PAM-Integration mit Backup (Sicherheit aus v1.0)
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && ! sudo grep -q "pam_u2f.so" "$FILE"; then
        sudo cp "$FILE" "${FILE}.original.bak"
        sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' "$FILE"
    fi
done
echo "ERFOLG: Schluessel registriert."; sleep 2
EOF

# --- Uninstall Script (aus v1.0 uebernommen) ---
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
echo "System bereinigt. X-SysLock wurde entfernt."; sleep 2
EOF

# --- GUI Control Script (v1.1 Zenity mit Status) ---
cat <<EOF > "$SCRIPT_DIR/yubi-control.sh"
#!/bin/bash
KEY_FILE="\$HOME/.config/Yubico/u2f_keys"

count_keys() {
    [ -f "\$KEY_FILE" ] && grep -c '^' "\$KEY_FILE" || echo 0
}

while true; do
    NUM=\$(count_keys)
    STATUS="Status: \$NUM Schluessel registriert."
    [ \$NUM -eq 1 ] && STATUS="! WARNUNG: Nur \$NUM Schluessel (Aussperrgefahr!)"
    [ \$NUM -eq 0 ] && STATUS="KRITISCH: Kein Schluessel registriert!"

    CHOICE=\$(zenity --list --width=550 --height=450 \\
        --title="X-SysLock v1.1 - Management" \\
        --text="\$STATUS\nBitte waehlen Sie eine Aktion:" \\
        --column="Aktion" --column="Beschreibung" \\
        "Schluessel hinzufuegen" "Backup-Key registrieren (Empfohlen)" \\
        "Kompletter Reset" "Alle Keys loeschen (Bei Diebstahl)" \\
        "Editieren" "YubiKey Manager (PINs verwalten)" \\
        "Deinstallieren" "System bereinigen & Tool entfernen" \\
        "Beenden" "Menue verlassen")

    case \$CHOICE in
        "Schluessel hinzufuegen") gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh" ;;
        "Kompletter Reset")
            if zenity --question --text="Moechten Sie alle Keys loeschen?"; then
                rm -f "\$KEY_FILE"
                gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh"
            fi ;;
        "Editieren") ykman-gui ;;
        "Deinstallieren")
            if zenity --question --text="X-SysLock komplett entfernen?"; then
                gnome-terminal --wait -- "$SCRIPT_DIR/yubi-uninstall.sh"
                rm "$APP_DIR/yubikey-manager.desktop"
                break
            fi ;;
        *) break ;;
    esac
done
EOF

chmod +x "$SCRIPT_DIR"/*.sh

# 3. Menueeintrag (Desktop Entry aus v1.0)
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

echo ""
echo -e "${GREEN}=== INSTALLATION ERFOLGREICH! ===${NC}"
echo "X-SysLock v1.1 ist nun einsatzbereit."
