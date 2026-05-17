# 🤖 OpenWRT Telegram Bot

**OpenWRT Telegram Bot** is an ultra-lightweight, fast, and secure Telegram bot for remote monitoring and management of routers running OpenWRT. It is written entirely in pure POSIX Shell, leveraging the router's native APIs (`ubus`, `jsonfilter`), making it the perfect solution for resource-constrained embedded systems.

The project features a full **LuCI** administrative web interface, allowing you to configure the token, administrators list, notifications, and logs directly through the router's standard web cabinet.

---

## 📈 Operation & Architecture

The bot is designed with the strict limits of embedded devices in mind:
1. **Pure Shell**: No heavy dependencies like Python, Node.js, or Lua scripts are loaded. The bot is written in `/bin/sh`.
2. **Low-Level Utilities**: It parses JSON strings using OpenWRT's built-in fast binary utility `jsonfilter`.
3. **Data Communication**: Network calls are managed via `curl` with strict connection and long polling timeouts to prevent process hangs.
4. **Flash Memory Preservation**: All temporary files, updates cache, and logs reside strictly in `/tmp` (RAM-backed `tmpfs`), completely protecting the physical Flash memory of your router from write wear.
5. **System Daemon**: Implemented as a standard system service (`init.d`) with auto-start support on boot.

---

## ⚡ RAM & Flash Footprint

* **RAM Usage**: **under 2 MB** during active execution (in peaks of Long Polling). In idle state, CPU and RAM usage is near-zero.
* **Flash Space**: **under 60 KB** for the entire installation (including scripts, languages, LuCI controllers, and templates).
* **CPU Load**: Under **0.1%** on typical hardware (computations trigger only when processing messages/commands).

---

## ✨ Features

* **📊 System Monitoring**: View uptime, software versions, free RAM/Flash, CPU load, and WAN IP addresses.
* **⚡ Interface Control**: Toggle any network interface on/off inside the chat with confirmation buttons.
* **📱 Connected Devices**: View active DHCP leases with device names, IP, and MAC addresses.
* **🔄 Router Reboot**: Reboot the router securely and remotely directly from the bot's keyboard.
* **🌐 Multilingual (Localization)**: Out-of-the-box support for 4 languages (Russian 🇷🇺, English 🇬🇧, Ukrainian 🇺🇦, German 🇩🇪) switchable on-the-fly.
* **🔔 Smart Notifications**:
  * On connection of a new device to the network (tracks MAC addresses).
  * On external WAN IP change.
  * On critical CPU load or low RAM (configurable thresholds in %).
  * On new bot updates release.
* **🔐 Security & Access Control**: Access is strictly limited to administrators added to the UCI whitelist. Unauthorized interactions are blocked and logged.
* **📁 Logs Management in LuCI**: A beautiful theme-adaptive modal window to view logs, with auto-clear settings based on age (seconds) or maximum line count.

---

## 🛠 Quick Installation

Requires `root` privileges and OpenWRT v24+ (with `apk` support).

1. Connect to your router via SSH.
2. Download the project archive to `/tmp`:
   ```bash
   wget -O /tmp/bot.tar.gz https://github.com/vlam1n-dev/OpenWRT-TelegramBot/archive/refs/heads/main.tar.gz
   ```
3. Extract the archive and open the directory:
   ```bash
   tar -xzf /tmp/bot.tar.gz -C /tmp/
   cd /tmp/OpenWRT-TelegramBot-main
   ```
4. Run the installer script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
5. Remove the temporary installation files from `/tmp` to free up the router's RAM:
   ```bash
   rm -rf /tmp/bot.tar.gz /tmp/OpenWRT-TelegramBot-main
   ```

Once installed, go to **Services ➡️ Telegram Bot** in the LuCI web interface, enter your bot API token (from `@BotFather`), add your Telegram User ID to the admin list, and enable the service.

---

## 🧹 Uninstallation

To completely and safely uninstall the bot and all its elements without touching other LuCI components:
```bash
cd /tmp/OpenWRT-TelegramBot-main 2>/dev/null || cd /tmp/telegram-bot
chmod +x uninstall.sh
./uninstall.sh
```

---

## 📄 License

This project is licensed under the terms of the **MIT** license. Created by **VLaM1N-Dev**.
