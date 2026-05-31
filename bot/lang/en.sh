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
MSG_WIFI_CLIENTS="clients"
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

BTN_BLOCKED_DEVICES="🚫 Blocked Devices"
BTN_UNBLOCK="🔓 Unblock"
BTN_KICK="🔌 Disconnect"
BTN_BLOCK="🚫 Block"
MSG_DEV_REMAINING_LEASE="<b>Lease remaining:</b>"
MSG_DEV_WIFI_IFACE="<b>Connection interface:</b>"
MSG_DEV_RX_TX="<b>RX / TX Rate:</b>"
MSG_DEV_CONFIRM_KICK="Are you sure you want to <b>disconnect</b> device <b>%s</b>?"
MSG_DEV_CONFIRM_BLOCK="Are you sure you want to <b>block</b> device <b>%s</b>?"
MSG_DEV_CONFIRM_UNBLOCK="Are you sure you want to <b>unblock</b> device <b>%s</b>?"
MSG_DEV_KICKED="🔌 Device <b>%s</b> disconnected"
MSG_DEV_BLOCKED="🚫 Device <b>%s</b> blocked and disconnected"
MSG_DEV_UNBLOCKED="🔓 Device <b>%s</b> unblocked"
MSG_DEV_KICK_RESP="Device disconnected"
MSG_DEV_BLOCK_RESP="Device blocked"
MSG_DEV_UNBLOCK_RESP="Device unblocked"
MSG_DEV_STATUS_NEW="New device"
MSG_DEV_STATUS_KNOWN="Device"
MSG_REFRESH_SUCCESS="Updated"
MSG_REFRESH_ERROR="Error"
MSG_BLOCKED_STATUS="Blocked"
MSG_BLOCKED_DEVICES_HEADER="🚫 <b>Blocked Devices</b>"


# ── Interfaces ──
MSG_IFACES_HEADER="⚡ <b>Network Interfaces</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Are you sure you want to <b>enable</b> interface <b>%s</b>?"
MSG_IFACE_CONFIRM_DOWN="Are you sure you want to <b>disable</b> interface <b>%s</b>?"
MSG_IFACE_CONFIRM_REBOOT="Are you sure you want to <b>restart</b> interface <b>%s</b>?"
MSG_IFACE_DONE_UP="✅ Interface <b>%s</b> has been <b>enabled</b>"
MSG_IFACE_DONE_DOWN="❌ Interface <b>%s</b> has been <b>disabled</b>"
MSG_IFACE_ERROR="⚠️ Failed to toggle interface <b>%s</b>"
BTN_IFACE_UP="🟢 Enable"
BTN_IFACE_DOWN="🔴 Disable"
BTN_IFACE_RESTART="🔄 Restart"
MSG_IFACE_STATUS="<b>Status:</b>"
MSG_IFACE_PROTO="<b>Protocol:</b>"
MSG_IFACE_UPTIME="<b>Uptime:</b>"
MSG_IFACE_MAC="<b>MAC:</b>"
MSG_IFACE_IPV4="<b>IPv4:</b>"
MSG_IFACE_IPV6="<b>IPv6:</b>"
MSG_IFACE_STATE_UP="Enabled"
MSG_IFACE_STATE_DOWN="Disabled"

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

NOTIFY_NEW_DEVICE="📱 <b>%s connected to network!</b>\n\nName: %s\nInterface: %s\nIP: <tg-spoiler>%s</tg-spoiler>\nMAC: <tg-spoiler>%s</tg-spoiler>"
NOTIFY_WAN_IP="🌐 <b>WAN IP changed!</b>\n\nOld: <tg-spoiler>%s</tg-spoiler>\nNew: <tg-spoiler>%s</tg-spoiler>"
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

# ── New features (Diagnostics, WoL, Traffic, Ports) ──
# Buttons
BTN_DIAG="🔍 Diagnostics"
BTN_WOL="🔔 Wake on Lan"
BTN_PORTS="🔀 Ports"
BTN_PORT_ADD="➕ Add Port"
BTN_PORT_PROTO_TCP="TCP"
BTN_PORT_PROTO_UDP="UDP"
BTN_PORT_PROTO_ALL="TCP+UDP"
BTN_TRAFFIC_HOUR="🕒 Hourly"
BTN_TRAFFIC_DAY="📅 Daily"
BTN_TRAFFIC_MONTH="📆 Monthly"
BTN_TRAFFIC_DEVICE="📱 By Device"

# Diagnostics
MSG_DIAG_HEADER="🔍 <b>Network Diagnostics</b>"
MSG_DIAG_PING_REQ="Enter IP or host for <b>Ping</b> (e.g., <code>8.8.8.8</code> or <code>google.com</code>):"
MSG_DIAG_TRACE_REQ="Enter IP or host for <b>Traceroute</b> (e.g., <code>1.1.1.1</code>):"
MSG_DIAG_DNS_REQ="Enter domain for <b>DNS Lookup</b> (e.g., <code>github.com</code>):"
MSG_DIAG_PORT_REQ="Enter host and port as <code>host:port</code> for <b>Port Check</b> (e.g., <code>192.168.1.1:80</code>):"
MSG_DIAG_INVALID_INPUT="⚠️ Invalid input format or illegal characters detected."
MSG_DIAG_RUNNING="⏳ Executing command..."
MSG_DIAG_RESULT="📝 <b>Result:</b>\n<pre>%s</pre>"

# WoL
MSG_WOL_CONFIRM="🔔 Are you sure you want to send WoL packet to <b>%s</b>?"
MSG_WOL_SENT="🔔 WoL packet successfully sent to %s"
MSG_WOL_ERROR="❌ Neither etherwake nor wol utility was found in the system."

# Traffic
MSG_TRAFFIC_HEADER="📊 <b>Traffic Statistics</b>"
MSG_TRAFFIC_ERR_VNSTAT="❌ The <b>vnStat</b> package is not installed on the system.\n\nInstall it using:\n<code>%s</code>"
MSG_TRAFFIC_ERR_NLBWMON="❌ The <b>nlbwmon</b> package is not installed on the system.\n\nInstall it using:\n<code>%s</code>"
MSG_TRAFFIC_HOUR_TITLE="🕒 <b>Traffic for the last 24 hours</b>\n\n"
MSG_TRAFFIC_DAY_TITLE="📅 <b>Daily Traffic</b>\n\n"
MSG_TRAFFIC_MONTH_TITLE="📆 <b>Monthly Traffic</b>\n\n"
MSG_TRAFFIC_DEVICE_TITLE="📱 <b>Top 10 Devices by Traffic</b>\n\n"

# Ports
MSG_PORTS_HEADER="🔀 <b>Port Forwarding</b>"
MSG_PORTS_NONE="No port forwarding rules found."
MSG_PORT_DETAILS="🔀 <b>Rule: %s</b>\n\n<b>Protocol:</b> %s\n<b>External Port:</b> %s\n<b>Internal IP:</b> %s\n<b>Internal Port:</b> %s\n<b>Status:</b> %s"
MSG_PORT_CONFIRM_DELETE="⚠️ Are you sure you want to <b>delete</b> rule <b>%s</b>?"
MSG_PORT_DELETED="✅ Rule %s successfully deleted."
MSG_PORT_ADD_NAME="✍️ Enter a <b>name</b> for the new rule (e.g., <code>Web Server</code>):"
MSG_PORT_ADD_EXT="✍️ Enter the <b>external port</b> (e.g., <code>8080</code>):"
MSG_PORT_ADD_IP="✍️ Enter the <b>internal IP address</b> of the device (e.g., <code>192.168.1.10</code>):"
MSG_PORT_ADD_INT="✍️ Enter the <b>internal port</b> (e.g., <code>80</code>):"
MSG_PORT_ADD_PROTO="✍️ Choose the <b>protocol</b> for the rule:"
MSG_PORT_ADD_SUCCESS="✅ Rule %s successfully added!"
MSG_PORT_INVALID_PORT="⚠️ Invalid port. Enter a number between 1 and 65535."
MSG_PORT_INVALID_IP="⚠️ Invalid IP address. Enter a correct local IP."
MSG_CANCEL_MSG="↩️ Action cancelled."

