# X-SysLock, login for Linux (YubiKey 5 Series)

X-SysLock is a security tool for Zorin OS and Ubuntu-based systems to enable hardware-based Two-Factor Authentication (2FA) for system login and sudo commands.

## Features
- **Interactive Installation**: Checks for software and guides the user.
- **PIN Transparency**: Clearly explains the difference between FIDO2, PIV, and Admin PINs.
- **Safety**: Creates automatic backups (`.original.bak`) of PAM files.
- **GUI Manager**: Easy "X-SysLock" menu entry for activating, editing, or uninstalling the tool.

## Quick Installation (One-Liner)
Open your terminal and run:
```bash
wget -qO- [https://raw.githubusercontent.com/albertuszerk/yubicosyslock/main/yubikey-master-setup.sh](https://raw.githubusercontent.com/albertuszerk/yubicosyslock/main/yubikey-master-setup.sh) | bash
