<p align="center">
  <img src="images/banner.png" alt="X-SysLock Banner" width="100%">
</p>

# <img src="images/logo.png" width="32" height="32"> X-SysLock, login for Linux (YubiKey 5 Series)

X-SysLock ist ein Sicherheits-Tool fuer Zorin OS und Ubuntu-basierte Systeme, um eine Hardware-basierte Zwei-Faktor-Authentifizierung (2FA) fuer den System-Login und Sudo-Befehle zu aktivieren.

## Features
- **Interaktive Installation**: Prueft Software und fuehrt den Nutzer Schritt fuer Schritt.
- **PIN-Transparenz**: Erklaert verstaendlich die Unterschiede zwischen FIDO2-, PIV- und Admin-PINs.
- **Sicherheit**: Erstellt automatische Backups (`.original.bak`) der PAM-Dateien.
- **GUI-Manager**: Einfaches Menue zum Aktivieren, Editieren oder Deinstallieren.

---

### ⚠️ WICHTIGER SICHERHEITSHINWEIS (Disclaimer)
Das Modifizieren von PAM (Pluggable Authentication Modules) kann bei Fehlkonfiguration dazu fuehren, dass Sie sich **komplett von Ihrem System aussperren**. 
- Stellen Sie sicher, dass Sie ein aktuelles Backup Ihrer Daten haben.
- Es wird dringend empfohlen, einen zweiten Administrator-Account ohne YubiKey-Pflicht als "Rettungsanker" bereit zu halten.
- Die Nutzung erfolgt auf eigene Gefahr.

---

## Quick Installation (One-Liner)
Oeffnen Sie Ihr Terminal und geben Sie folgenden Befehl ein:

```bash
bash <(wget -qO- [https://raw.githubusercontent.com/albertuszerk/yubicosyslock/main/yubikey-master-setup.sh](https://raw.githubusercontent.com/albertuszerk/yubicosyslock/main/yubikey-master-setup.sh))
