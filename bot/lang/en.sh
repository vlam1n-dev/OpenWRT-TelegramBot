#!/bin/sh
# OpenWRT Telegram Bot — English language file
# shellcheck disable=SC2034

# ── Main menu ──
MSG_SYS_INFO_HEADER="📊 <b>System Information</b>"
MSG_HOSTNAME="🖥 <b>Hostname:</b>"
MSG_VERSION="📦 <b>Version:</b>"
MSG_KERNEL="🐧 <b>Kernel:</b>"
MSG_UPTIME="⏱ <b>Uptime:</b>"
MSG_RAM="💾 <b>RAM:</b>"
MSG_FLASH="💿 <b>Flash:</b>"
MSG_WAN_IP="🌐 <b>WAN IP:</b>"
MSG_WIFI_STATUS="📶 <b>WiFi:</b>"
MSG_BOT_VER="🤖 <b>Bot v:</b>"

BTN_RESTART="🔄 Restart"
BTN_INTERFACES="⚡ Interfaces"
BTN_STATS="📊 Statistics"
BTN_DEVICES="📱 Devices"
BTN_SETTINGS="⚙️ Settings"
BTN_REFRESH="🔃 Refresh"

# ── Statistics ──
MSG_STATS_HEADER="📊 <b>System Statistics</b>"
MSG_CPU="🔲 <b>CPU:</b>"
MSG_RAM_USED="💾 <b>RAM Used:</b>"
MSG_RAM_FREE="💾 <b>RAM Free:</b>"
MSG_RAM_TOTAL="💾 <b>RAM Total:</b>"
MSG_FLASH_USED="💿 <b>Flash Used:</b>"
MSG_FLASH_FREE="💿 <b>Flash Free:</b>"
MSG_FLASH_TOTAL="💿 <b>Flash Total:</b>"
MSG_LOAD_AVG="📈 <b>Load Avg:</b>"
MSG_PROCESSES="⚙️ <b>Processes:</b>"
MSG_NET_RX="📥 <b>Download:</b>"
MSG_NET_TX="📤 <b>Upload:</b>"
BTN_BACK="◀️ Back"

# ── Devices ──
MSG_DEVICES_HEADER="📱 <b>Connected Devices</b>"
MSG_DEVICES_NONE="No devices found"
MSG_DEVICE_IP="IP:"
MSG_DEVICE_MAC="MAC:"
MSG_DEVICE_NAME="Name:"
MSG_DEVICES_COUNT="Total:"

# ── Interfaces ──
MSG_IFACES_HEADER="⚡ <b>Network Interfaces</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Are you sure you want to <b>enable</b> interface <b>%s</b>?"
MSG_IFACE_CONFIRM_DOWN="Are you sure you want to <b>disable</b> interface <b>%s</b>?"
MSG_IFACE_DONE_UP="✅ Interface <b>%s</b> has been <b>enabled</b>"
MSG_IFACE_DONE_DOWN="❌ Interface <b>%s</b> has been <b>disabled</b>"
MSG_IFACE_ERROR="⚠️ Failed to toggle interface <b>%s</b>"

# ── Reboot ──
MSG_REBOOT_CONFIRM="⚠️ Are you sure you want to <b>reboot</b> the router?"
MSG_REBOOT_OK="🔄 Rebooting the router now..."
MSG_REBOOT_CANCEL="↩️ Reboot cancelled"
BTN_YES="✅ Yes"
BTN_NO="❌ No"

# ── Settings ──
MSG_SETTINGS_HEADER="⚙️ <b>Settings</b>"
BTN_NOTIFICATIONS="🔔 Notifications"
BTN_LANGUAGE="🌐 Language"

# ── Notifications ──
MSG_NOTIFY_HEADER="🔔 <b>Notification Settings</b>"
MSG_NOTIFY_HINT="Tap to toggle on/off:"
BTN_NOTIFY_NEWDEV="📱 New Device"
BTN_NOTIFY_WANIP="🌐 WAN IP Change"
BTN_NOTIFY_CPU="🔲 High CPU"
BTN_NOTIFY_RAM="💾 High RAM"
BTN_NOTIFY_UPD="📦 Bot Update"
MSG_NOTIFY_ENABLED="✅"
MSG_NOTIFY_DISABLED="❌"

NOTIFY_NEW_DEVICE="📱 <b>New device connected!</b>\n\nName: %s\nIP: %s\nMAC: %s"
NOTIFY_WAN_IP="🌐 <b>WAN IP changed!</b>\n\nOld: %s\nNew: %s"
NOTIFY_HIGH_CPU="🔲 <b>High CPU usage!</b>\n\nLoad: %s%%\nThreshold: %s%%"
NOTIFY_HIGH_RAM="💾 <b>High RAM usage!</b>\n\nUsed: %s%%\nThreshold: %s%%"
NOTIFY_UPDATE="📦 <b>Bot update available!</b>\n\nCurrent: %s\nLatest: %s\nRepo: %s"

# ── Language ──
MSG_LANG_HEADER="🌐 <b>Language / Язык</b>"
MSG_LANG_CURRENT="Current language: <b>English</b>"
MSG_LANG_CHANGED="🌐 Language changed to <b>English</b>"
BTN_LANG_EN="🇬🇧 English"
BTN_LANG_RU="🇷🇺 Русский"
BTN_LANG_UK="🇺🇦 Українська"
BTN_LANG_DE="🇩🇪 Deutsch"

# ── Auth ──
MSG_ACCESS_DENIED="⛔ <b>Access Denied</b>\n\nYou are not authorized to use this bot.\nYour ID: <code>%s</code>"

# ── Errors ──
MSG_API_ERROR="⚠️ Telegram API error"
MSG_RATE_LIMITED="⏳ Too many requests. Please wait."
MSG_UNKNOWN_CMD="❓ Unknown command. Use /start"

# ── About & Updates ──
BTN_ABOUT="ℹ️ About Bot"
MSG_ABOUT_HEADER="ℹ️ <b>About OpenWRT Telegram Bot</b>"
MSG_ABOUT_TEXT="<b>OpenWRT Telegram Bot</b>\n\n👤 <b>Author:</b> VLaM1N-Dev\n🌐 <b>GitHub:</b> <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>\n📄 <b>License:</b> MIT\n🤖 <b>Version:</b> %s"
BTN_CHECK_UPDATES="📥 Check Updates"
MSG_CHECKING_UPDATES="⏳ Checking for updates..."
MSG_UPD_LATEST="✅ You are running the latest version (v%s)."
MSG_UPD_AVAILABLE="📥 <b>New update available!</b>\n\nLatest: <b>v%s</b>\nDownload: <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>"
MSG_UPD_ERROR="❌ Failed to check updates. Please try again later."
MSG_UPD_COOLDOWN="⏳ Please wait %s seconds before checking again."

