#!/bin/sh
# OpenWRT Telegram Bot — Uninstaller

if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

echo "Stopping service..."
/etc/init.d/telegram stop
/etc/init.d/telegram disable

echo "Removing files..."
rm -rf /usr/lib/telegram-bot
rm -f /usr/bin/telegram-bot.sh
rm -f /usr/bin/telegram-monitor.sh
rm -f /etc/init.d/telegram

echo "Removing LuCI components..."
rm -f /usr/lib/lua/luci/controller/telegram.lua
rm -f /usr/lib/lua/luci/model/cbi/telegram.lua
rm -rf /usr/lib/lua/luci/view/telegram

rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
rm -rf /tmp/telegram-bot

echo "Do you want to remove the configuration file (/etc/config/telegram)? [y/N]"
read remove_config
if [ "$remove_config" = "y" ] || [ "$remove_config" = "Y" ]; then
    rm -f /etc/config/telegram
    echo "Configuration removed."
fi

echo "✅ Uninstallation completed."
