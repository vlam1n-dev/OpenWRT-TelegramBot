# What is it?

**OpenWRT Telegram Bot** is a lightweight, fast, and secure Telegram Bot for remote monitoring and management of OpenWRT-based routers. Written entirely in pure Shell using the router's built-in API (`ubus`, `uci`, `jsonfilter`) and the Telegram API.

Configuring the settings is available both through the config file `/etc/config/telegram` and the **LuCI** web interface - settings for token, administrators list, bot notifications, checking updates, and logs output `Services -> Telegram Bot`

<img width="1142" height="693" alt="image" src="https://github.com/user-attachments/assets/e50f88e9-4f02-4406-8a3c-54ccb48f6d5e" />

---

## README

* [Русский](README.md)
* [English](README_EN.md)
* [Український](README_UK.md)
* [Deutsches](README_DE.md)
  
---

## Table of Contents
- [Architecture](#architecture)
- [System Requirements](#system-requirements)
- [Key Features](#key-features)
- [Resource Consumption](#resource-consumption)
- [Installation and Updates](#installation)
- [Uninstallation](#uninstallation)
- [License](#license)
- [Support the Developer](#support-the-developer)

---

## Architecture

- **Shell**: Pure `/bin/sh`;
- **Low-level utilities**: Built-in binary parser `jsonfilter` is used for parsing JSON;
- **Data exchange**: Network requests are made via `curl`;
- **Flash memory conservation**: Temporary files are located in `/tmp` directory;
- **Built-in daemon**: The bot runs as a system service managed by the `procd` supervisor.

---

## System Requirements

- **Operating System**: OpenWRT **version 19.07 and higher**;
- **Basic dependencies** (installed automatically):
  - `curl`;
  - `jsonfilter`;
  - `ca-certificates` / `ca-bundle`.
- **Optional dependencies** (installed optionally in `install.sh` for advanced modules):
  - `etherwake` or `wol` - for Wake-on-LAN feature;
  - `vnstat` / `vnstatd` - for collecting general traffic statistics;
  - `nlbwmon` - for monitoring bandwidth usage of local clients.

---

## Key Features

- **📊 System Monitoring**:
  - View **uptime**, **software version**, **free RAM/Flash memory**, **CPU load**, **WAN IP** addresses;
  - **Run** standard **network utilities** with dynamic real-time output (Ping, Traceroute, DNS Lookup, Port Check).
- **⚡ Network Interfaces Management**:
  - **Enable/disable** any **network interface** available in OpenWRT;
  - View detailed information about each network interface.
- **📱 Connected Devices List**
  - Instant **output of active DHCP leases** with detailed information including IP, connection interface and more;
  - Ability to disconnect any device from the network;
  - Ability to block a device for subsequent connection to this network interface;
  - Ability to send a **Wake-on-Lan** packet.
- **🔀 Port Forwarding (NAT)**
  - **Firewall management** of the router without entering LuCI;
  - Create, modify, enable/disable already existing rules.
- **🔄 Reboot**
  - Reboot any network interface, including the router itself.
- **🔔 Notifications**
  - **Configure notifications** via Telegram bot (Device connected / WAN IP change / High system load).
- **🌐 Localization**
  - **Support for 4 languages**, including Russian, English, Ukrainian, German.
- **📁 LuCI Integration**
  - Configure API key, admin IDs, notifications via the bot, update check and more;
  - View detailed logs of the Telegram Bot.

---

## Resource Consumption

* **RAM**: **less than 2 MB** during operation. In standby mode, the load is practically zero;
* **Flash storage**: **less than 60 KB** for the entire installation;
  - All volatile files (user state database, temporary FIFO pipes, PID files, logs) are moved to the `/tmp` directory.
* **CPU load**: Less than **1%**.

---

## Installation

For installation, OpenWRT version `19.07` and higher is required.

**WARNING**: Testing was performed only by me on version `25.12.0`, there might be bugs on other versions!

1. Connect to the router (for example, using [Putty](https://github.com/putty-org-ru/PuTTY/releases));
2. Run the **command for automatic download** and start of the installer:
   ```bash
   wget -qO- https://raw.githubusercontent.com/vlam1n-dev/OpenWRT-TelegramBot/main/install.sh | sh
   ```
3. Complete the installer following the instructions.

After successful installation, go to the router's LuCI web interface (if installed): `Services -> Telegram Bot`, enter your bot token (obtained from [@BotFather](https://t.me/BotFather)) and add your **Telegram ID** to the administrators list.

Updating works exactly the same way, by running `install.sh` specify the **new version** or install **automatically**.

---

## Uninstallation

For complete and safe removal of the bot and all its components, run the uninstaller:
```bash
wget -qO- https://raw.githubusercontent.com/vlam1n-dev/OpenWRT-TelegramBot/main/uninstall.sh | sh
```

You can choose which **components to remove** and which to **keep**, including the **configuration file**.

---

## License

The project is distributed under the **MIT** license. Project Author: [VLaM1N-Dev](https://github.com/vlam1n-dev).

---

## Support the Developer

USDT TRC20 ```TWxCEaSNwbXwXs82ad9q9x9EifPQxMwGbb```

USDT ERC20 ```0x0755c77914fc933e029073ad4773643dfdc7a6b1```

ETH ```0x0755c77914fc933e029073ad4773643dfdc7a6b1```

BTC ```194ehsjJWGvrqCsbLmwLz8gTbHA2zTv2Cu```
