#!/bin/sh
# OpenWRT Telegram Bot — German language file
# shellcheck disable=SC2034

# ── Main menu ──
MSG_SYS_INFO_HEADER="📊 <b>Systeminformationen</b>"
MSG_HOSTNAME="🖥 <b>Hostname:</b>"
MSG_VERSION="📦 <b>Version:</b>"
MSG_KERNEL="🐧 <b>Kernel:</b>"
MSG_UPTIME="⏱ <b>Betriebszeit:</b>"
MSG_RAM="💾 <b>RAM:</b>"
MSG_FLASH="💿 <b>Flash:</b>"
MSG_WAN_IP="🌐 <b>WAN-IP:</b>"
MSG_WIFI_STATUS="📶 <b>WLAN:</b>"
MSG_BOT_VER="🤖 <b>Bot v:</b>"

BTN_RESTART="🔄 Neustart"
BTN_INTERFACES="⚡ Schnittstellen"
BTN_STATS="📊 Statistiken"
BTN_DEVICES="📱 Geräte"
BTN_SETTINGS="⚙️ Einstellungen"
BTN_REFRESH="🔃 Aktualisieren"

# ── Statistics ──
MSG_STATS_HEADER="📊 <b>Systemstatistiken</b>"
MSG_CPU="🔲 <b>CPU:</b>"
MSG_RAM_USED="💾 <b>RAM belegt:</b>"
MSG_RAM_FREE="💾 <b>RAM frei:</b>"
MSG_RAM_TOTAL="💾 <b>RAM gesamt:</b>"
MSG_FLASH_USED="💿 <b>Flash belegt:</b>"
MSG_FLASH_FREE="💿 <b>Flash frei:</b>"
MSG_FLASH_TOTAL="💿 <b>Flash gesamt:</b>"
MSG_LOAD_AVG="📈 <b>Lastdurchschnitt:</b>"
MSG_PROCESSES="⚙️ <b>Prozesse:</b>"
MSG_NET_RX="📥 <b>Herunterladen:</b>"
MSG_NET_TX="📤 <b>Hochladen:</b>"
BTN_BACK="◀️ Zurück"

# ── Devices ──
MSG_DEVICES_HEADER="📱 <b>Verbundene Geräte</b>"
MSG_DEVICES_NONE="Keine Geräte gefunden"
MSG_DEVICE_IP="IP:"
MSG_DEVICE_MAC="MAC:"
MSG_DEVICE_NAME="Name:"
MSG_DEVICES_COUNT="Gesamt:"

# ── Interfaces ──
MSG_IFACES_HEADER="⚡ <b>Netzwerkschnittstellen</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Sind Sie sicher, dass Sie die Schnittstelle <b>%s</b> <b>aktivieren</b> möchten?"
MSG_IFACE_CONFIRM_DOWN="Sind Sie sicher, dass Sie die Schnittstelle <b>%s</b> <b>deaktivieren</b> möchten?"
MSG_IFACE_DONE_UP="✅ Schnittstelle <b>%s</b> wurde <b>aktiviert</b>"
MSG_IFACE_DONE_DOWN="❌ Schnittstelle <b>%s</b> wurde <b>deaktiviert</b>"
MSG_IFACE_ERROR="⚠️ Schnittstelle <b>%s</b> konnte nicht umgeschaltet werden"

# ── Reboot ──
MSG_REBOOT_CONFIRM="⚠️ Sind Sie sicher, dass Sie den Router <b>neustarten</b> möchten?"
MSG_REBOOT_OK="🔄 Router wird neu gestartet..."
MSG_REBOOT_CANCEL="↩️ Neustart abgebrochen"
BTN_YES="✅ Ja"
BTN_NO="❌ Nein"

# ── Settings ──
MSG_SETTINGS_HEADER="⚙️ <b>Einstellungen</b>"
BTN_NOTIFICATIONS="🔔 Benachrichtigungen"
BTN_LANGUAGE="🌐 Sprache"

# ── Notifications ──
MSG_NOTIFY_HEADER="🔔 <b>Benachrichtigungseinstellungen</b>"
MSG_NOTIFY_HINT="Tippen zum Ein-/Ausschalten:"
BTN_NOTIFY_NEWDEV="📱 Neues Gerät"
BTN_NOTIFY_WANIP="🌐 WAN-IP Änderung"
BTN_NOTIFY_CPU="🔲 Hohe CPU-Last"
BTN_NOTIFY_RAM="💾 Hohe RAM-Nutzung"
BTN_NOTIFY_UPD="📦 Bot-Update"
MSG_NOTIFY_ENABLED="✅"
MSG_NOTIFY_DISABLED="❌"

NOTIFY_NEW_DEVICE="📱 <b>Neues Gerät verbunden!</b>\n\nName: %s\nIP: %s\nMAC: %s"
NOTIFY_WAN_IP="🌐 <b>WAN-IP geändert!</b>\n\nAlt: %s\nNeu: %s"
NOTIFY_HIGH_CPU="🔲 <b>Hohe CPU-Auslastung!</b>\n\nLast: %s%%\nSchwellenwert: %s%%"
NOTIFY_HIGH_RAM="💾 <b>Hohe RAM-Auslastung!</b>\n\nBelegt: %s%%\nSchwellenwert: %s%%"
NOTIFY_UPDATE="📦 <b>Bot-Update verfügbar!</b>\n\nAktuell: %s\nNeueste: %s\nRepository: %s"

# ── Language ──
MSG_LANG_HEADER="🌐 <b>Language / Sprache</b>"
MSG_LANG_CURRENT="Aktuelle Sprache: <b>Deutsch</b>"
MSG_LANG_CHANGED="🌐 Sprache auf <b>Deutsch</b> geändert"
BTN_LANG_EN="🇬🇧 English"
BTN_LANG_RU="🇷🇺 Русский"
BTN_LANG_UK="🇺🇦 Українська"
BTN_LANG_DE="🇩🇪 Deutsch"

# ── Auth ──
MSG_ACCESS_DENIED="⛔ <b>Zugriff verweigert</b>\n\nSie sind nicht berechtigt, diesen Bot zu nutzen.\nIhre ID: <code>%s</code>"

# ── Errors ──
MSG_API_ERROR="⚠️ Telegram-API-Fehler"
MSG_RATE_LIMITED="⏳ Zu viele Anfragen. Bitte warten."
MSG_UNKNOWN_CMD="❓ Unbekannter Befehl. Verwenden Sie /start"

# ── About & Updates ──
BTN_ABOUT="ℹ️ Über den Bot"
MSG_ABOUT_HEADER="ℹ️ <b>Über OpenWRT Telegram Bot</b>"
MSG_ABOUT_TEXT="<b>OpenWRT Telegram Bot</b>\n\n👤 <b>Autor:</b> VLaM1N-Dev\n🌐 <b>GitHub:</b> <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>\n📄 <b>Lizenz:</b> MIT\n🤖 <b>Version:</b> %s"
BTN_CHECK_UPDATES="📥 Updates prüfen"
MSG_CHECKING_UPDATES="⏳ Updates werden geprüft..."
MSG_UPD_LATEST="✅ Sie verwenden die neueste Version (v%s)."
MSG_UPD_AVAILABLE="📥 <b>Neues Update verfügbar!</b>\n\nVersion: <b>v%s</b>\nHerunterladen: <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>"
MSG_UPD_ERROR="❌ Fehler beim Prüfen auf Updates. Bitte versuchen Sie es später noch einmal."
MSG_UPD_COOLDOWN="⏳ Bitte warten Sie %s Sekunden vor dem nächsten Versuch."
