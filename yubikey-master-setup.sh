#!/bin/bash
# Project: X-SysLock v1.1 (Multi-Key Support)
# License: CC BY-NC-SA 4.0

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Pfade ---
SCRIPT_DIR="$HOME/.yubikey-tool"
APP_DIR="$HOME/.local/share/applications"
KEY_FILE="$HOME/.config/Yubico/u2f_keys"

clear
echo -e "${BLUE}=== X-SysLock Installer v1.1 ===${NC}"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$HOME/.config/Yubico"

# 1. Software-Check
sudo apt update && sudo apt install -y libpam-u2f pamu2fcfg yubikey-manager-qt zenity

# 2. Das Steuerungs-Skript (GUI)
cat <<EOF > "$SCRIPT_DIR/yubi-control.sh"
#!/bin/bash
KEY_FILE="\$HOME/.config/Yubico/u2f_keys"

# Funktion: Zaehle registrierte Keys
count_keys() {
    if [ -f "\$KEY_FILE" ]; then
        grep -c '^' "\$KEY_FILE"
    else
        echo 0
    fi
}

while true; do
    NUM=\$(count_keys)
    STATUS="Status: \$NUM Schluessel registriert."
    [ \$NUM -eq 1 ] && STATUS="! WARNUNG: Nur \$NUM Schluessel (Aussperrgefahr!)"
    [ \$NUM -eq 0 ] && STATUS="KRITISCH: Kein Schluessel registriert!"

    CHOICE=\$(zenity --list --width=550 --height=450 \\
        --title="X-SysLock v1.1 - Multi-Key Management" \\
        --text="\$STATUS\nBitte waehlen Sie eine Aktion aus:" \\
        --column="Aktion" --column="Beschreibung" \\
        "Schluessel hinzufuegen" "Einen weiteren Backup-Key registrieren" \\
        "Kompletter Reset" "ALLE Keys loeschen und neu aufsetzen (Diebstahl-Schutz)" \\
        "YubiKey Manager" "PINs und FIDO2-Einstellungen verwalten" \\
        "Deinstallieren" "System bereinigen und Tool entfernen" \\
        "Beenden" "Menue verlassen")

    case \$CHOICE in
        "Schluessel hinzufuegen")
            gnome-terminal --wait -- bash -c "echo 'Zweit-Key einstecken und Kontakt beruehren...'; pamu2fcfg >> '\$KEY_FILE' && echo 'Erfolg!' || echo 'Fehler!'; sleep 2"
            ;;
        "Kompletter Reset")
            if zenity --question --text="Moechten Sie wirklich ALLE Schluessel loeschen?"; then
                rm -f "\$KEY_FILE"
                gnome-terminal --wait -- bash -c "echo 'Ersten Key einstecken und Kontakt beruehren...'; pamu2fcfg > '\$KEY_FILE' && echo 'Neuer Hauptschluessel gesetzt!'; sleep 2"
            fi
            ;;
        "YubiKey Manager") ykman-gui ;;
        "Deinstallieren")
            # Deinstallations-Logik
            break ;;
        *) break ;;
    esac
done
EOF

# 3. PAM-Konfiguration
sudo sed -i '/pam_u2f.so/d' /etc/pam.d/gdm-password 2>/dev/null
sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' /etc/pam.d/gdm-password
sudo sed -i '/pam_u2f.so/d' /etc/pam.d/sudo 2>/dev/null
sudo sed -i '/@include common-auth/a auth required pam_u2f.so cue' /etc/pam.d/sudo

chmod +x "$SCRIPT_DIR"/*.sh
echo -e "${GREEN}Installation von v1.1 abgeschlossen.${NC}"
