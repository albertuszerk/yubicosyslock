#!/bin/bash
# Project: X-SysLock v1.1 (Final Pro Version)
# Repository: https://github.com/albertuszerk/yubicosyslock
# Version: 1.1
# License: CC BY-NC-SA 4.0

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Interaktiver Start ---
clear
echo -e "${BLUE}=== X-SysLock Installer v1.1 ===${NC}"
echo "Dieses Script konfiguriert Ihren YubiKey fuer den Linux-Login."
echo "v1.1 Feature: Unterstuetzung fuer mehrere Schluessel & visuelle Status-Anzeige."
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

# 2. Scripte schreiben
echo -e "${BLUE}[2/4] Konfiguriere System-Logik...${NC}"

# --- Setup Script (Registrierungs-Logik) ---
cat <<'EOF' > "$SCRIPT_DIR/yubi-setup.sh"
#!/bin/bash
KEY_FILE="$HOME/.config/Yubico/u2f_keys"
mkdir -p "$HOME/.config/Yubico"

clear
echo -e "\033[0;34m=== YubiKey BESTAETIGUNG (X-SysLock v1.1) ===\033[0m"
echo ""
echo "WICHTIG: Wenn Sie nach einer PIN gefragt werden, ist dies die FIDO2-PIN."
echo ""
echo "Die 3 Standard-PINs eines YubiKeys:"
echo "1. FIDO2-PIN: (Standard: leer). Schuetzt den Login."
echo "2. PIV-PIN:   (Standard: 123456). Fuer Zertifikate."
echo "3. Admin-PIN: (Standard: 12345678). Hardware-Verwaltung."
echo "-------------------------------------------------------"
echo ""

if [ -f "$KEY_FILE" ] && [ -s "$KEY_FILE" ]; then
    echo "Modus: Weiteren Backup-Key hinzufuegen..."
    # Sicherstellen, dass ein Trenner gesetzt wird, falls pamu2fcfg direkt anhaengt
    printf ":" >> "$KEY_FILE"
    pamu2fcfg -n >> "$KEY_FILE" || { echo "Fehler!"; sleep 3; exit 1; }
else
    echo "Modus: Mit YubiKey anmelden / Ersten Key bestaetigen..."
    pamu2fcfg > "$KEY_FILE" || { echo "Fehler!"; sleep 3; exit 1; }
fi

chmod 600 "$KEY_FILE"

# PAM-Integration mit Backup-Schutz (Original bleibt erhalten)
PAM_FILES=("/etc/pam.d/gdm-password" "/etc/pam.d/sudo")
for FILE in "${PAM_FILES[@]}"; do
    if [ -f "$FILE" ] && ! sudo grep -q "pam_u2f.so" "$FILE"; then
        sudo cp "$FILE" "${FILE}.original.bak"
        sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' "$FILE"
    fi
done
echo "ERFOLG: Schluessel wurde registriert."; sleep 2
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
echo "System bereinigt. X-SysLock wurde entfernt."; sleep 2
EOF

# --- GUI Control Script (Zenity mit korrigierter Zaehl-Logik) ---
cat <<EOF > "$SCRIPT_DIR/yubi-control.sh"
#!/bin/bash
KEY_FILE="\$HOME/.config/Yubico/u2f_keys"

count_keys() {
    # Korrektur: Zaehlt Doppelpunkte statt Zeilen fuer maximale Praezision
    [ -f "\$KEY_FILE" ] && grep -o ":" "\$KEY_FILE" | wc -l || echo 0
}

while true; do
    NUM=\$(count_keys)
    
    if [ \$NUM -eq 0 ]; then
        STATUS="<span color='red'><b>KRITISCH: Kein Schluessel registriert!</b></span>"
    elif [ \$NUM -eq 1 ]; then
        STATUS="<span color='orange'><b>! WARNUNG: Nur 1 Schluessel (Aussperrgefahr!)</b></span>"
    else
        STATUS="<span color='green'><b>! ERFOLG: Mind. \$NUM Schluessel wurden registriert.</b></span>"
    fi

    CHOICE=\$(zenity --list --width=550 --height=450 \\
        --title="X-SysLock v1.1 - Management" \\
        --text="\$STATUS\n\nBitte waehlen Sie eine Aktion aus:" \\
        --column="Aktion" --column="Beschreibung" \\
        "Schluessel hinzufuegen" "Einen weiteren Backup-Key registrieren" \\
        "Kompletter Reset" "Alle Keys loeschen und neu anmelden" \\
        "Editieren" "YubiKey Manager (PINs & Einstellungen)" \\
        "Deinstallieren" "System bereinigen & Tool entfernen" \\
        "Beenden" "Menue verlassen")

    case \$CHOICE in
        "Schluessel hinzufuegen") gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh" ;;
        "Kompletter Reset")
            if zenity --question --text="Moechten Sie wirklich ALLE registrierten Schluessel loeschen?"; then
                rm -f "\$KEY_FILE"
                gnome-terminal --wait -- "$SCRIPT_DIR/yubi-setup.sh"
            fi ;;
        "Editieren") ykman-gui ;;
        "Deinstallieren")
            if zenity --question --text="X-SysLock komplett entfernen und System-Originalzustand wiederherstellen?"; then
                gnome-terminal --wait -- "$SCRIPT_DIR/yubi-uninstall.sh"
                rm "$APP_DIR/yubikey-manager.desktop"
                break
            fi ;;
        *) break ;;
    esac
done
EOF

chmod +x "$SCRIPT_DIR"/*.sh

# 3. Menueeintrag (Desktop Entry)
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
