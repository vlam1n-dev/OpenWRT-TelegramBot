#!/bin/sh
# OpenWRT Telegram Bot — Installer

if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

if [ ! -f "/etc/openwrt_release" ]; then
    echo "Error: This script is only for OpenWRT."
    exit 1
fi

if ! command -v apk >/dev/null 2>&1; then
    echo "Error: apk package manager not found. This bot requires OpenWRT 24+ with apk support."
    exit 1
fi

echo "Installing dependencies..."
apk add curl jsonfilter ca-certificates luci-base luci-compat || {
    echo "Failed to install dependencies."
    exit 1
}

echo "Copying files..."
mkdir -p /usr/lib/telegram-bot/lang
cp -f bot/telegram-bot-lib.sh /usr/lib/telegram-bot/
cp -f bot/telegram-bot.sh /usr/bin/
cp -f bot/telegram-monitor.sh /usr/bin/
cp -f VERSION /usr/lib/telegram-bot/
cp -f bot/lang/*.sh /usr/lib/telegram-bot/lang/

chmod +x /usr/bin/telegram-bot.sh
chmod +x /usr/bin/telegram-monitor.sh

if [ ! -f "/etc/config/telegram" ]; then
    cp -f config/telegram /etc/config/
fi

cp -f init.d/telegram /etc/init.d/
chmod +x /etc/init.d/telegram

echo "Installing LuCI components..."
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi
mkdir -p /usr/lib/lua/luci/view/telegram

cp -f luci/controller/telegram.lua /usr/lib/lua/luci/controller/
cp -f luci/model/cbi/telegram.lua /usr/lib/lua/luci/model/cbi/
cp -f luci/view/telegram/status.htm /usr/lib/lua/luci/view/telegram/
cp -f luci/view/telegram/project_info.htm /usr/lib/lua/luci/view/telegram/

rm -rf /tmp/luci-indexcache /tmp/luci-modulecache

echo "Enabling service..."
/etc/init.d/telegram enable

echo ""
echo "====================================================="
echo "✅ Installation completed successfully!"
echo "Please configure the bot in LuCI:"
echo "Services -> Telegram Bot"
echo "====================================================="
