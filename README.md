<p align="center">
  <img src="images/banner.png" alt="X-SysLock Banner" width="100%">
</p>

# <img src="images/logo.png" width="32" height="32"> X-SysLock, login for Linux (YubiKey 5 Series)

# X-SysLock, login for Linux (YubiKey 5 Series)

X-SysLock is a security tool for Zorin OS and Ubuntu-based systems to enable hardware-based Two-Factor Authentication (2FA) for system login and sudo commands.

## Features
- **Interactive Installation**: Checks for software and guides the user.
- **PIN Transparency**: Clearly explains the difference between FIDO2, PIV, and Admin PINs.
- **Safety**: Creates automatic backups (`.original.bak`) of PAM files.
- **GUI Manager**: Easy "X-SysLock" menu entry for activating, editing, or uninstalling the tool.

## Quick Installation (One-Liner)
Open your terminal and run:

```bash <(wget -qO- https://raw.githubusercontent.com/albertuszerk/yubicosyslock/main/yubikey-master-setup.sh)```

## Understanding YubiKey PINs
When X-SysLock asks for a PIN during registration, it refers to the **FIDO2 PIN**. 

### The 3 standard PINs on a YubiKey:
1. **FIDO2 PIN:** Used for Login (Default: often not set/empty). This is the PIN X-SysLock uses.
2. **PIV PIN:** Used for Smartcards/Certificates (Default: 123456).
3. **Admin PIN:** Used to manage the hardware (Default: 12345678).

## Uninstallation
X-SysLock can be removed cleanly via its own GUI menu. It restores your system's original PAM configuration and removes its own scripts and configurations.

## License
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

## Hashtags
#XSysLock #YubiKey #LinuxSecurity #ZorinOS #CyberSecurity #2FA #MFA #HardwareSecurity #LinuxLogin #Yubico #SystemHardening #PAM #FIDO2 #ZweiFaktorAuthentifizierung #HardwareToken #SudoSecurity #OpenSource #Ubuntu #SecurityTools #albertuszerk #yubicosyslock #LinuxMint #IdentityManagement #CyberDefense #SysAdmin #Privacy #DataProtection #Encryption #Hardening #LoginSecurity
