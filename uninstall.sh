#!/bin/sh
# OpenWRT Telegram Bot — Деинсталлятор

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции вывода
info() {
    printf "${CYAN}ℹ️ %s${NC}\n" "$1"
}
success() {
    printf "${GREEN}✅ %s${NC}\n" "$1"
}
warn() {
    printf "${YELLOW}⚠️ %s${NC}\n" "$1"
}
error() {
    printf "${RED}❌ %s${NC}\n" "$1"
}

if [ "$(id -u)" != "0" ]; then
    error "Этот скрипт должен быть запущен от root пользователя!"
    exit 1
fi

printf "${YELLOW}❓ Вы уверены, что хотите полностью удалить OpenWRT-TelegramBot? (y/N): ${NC}"
read confirm
case "$confirm" in
    [yY]|[yY][eE][sS])
        ;;
    *)
        error "Деинсталляция отменена"
        exit 0
        ;;
esac

echo "-----------------------------------------------------"
printf "${YELLOW}❓ Удалить дополнительные компоненты (etherwake, vnstat, nlbwmon)? (y/N): ${NC}"
read remove_ext
case "$remove_ext" in
    [yY]|[yY][eE][sS])
        info "Удаление дополнительных компонентов..."
        if command -v apk >/dev/null 2>&1; then
            apk del etherwake vnstat nlbwmon >/dev/null 2>&1
        elif command -v opkg >/dev/null 2>&1; then
            opkg remove etherwake vnstat nlbwmon >/dev/null 2>&1
        fi
        success "Дополнительные компоненты удалены"
        ;;
    *)
        info "Дополнительные компоненты сохранены в системе"
        ;;
esac

echo "-----------------------------------------------------"
printf "${YELLOW}❓ Удалить файлы конфигурации (/etc/config/telegram)? (y/N): ${NC}"
read remove_config
config_removed=0
case "$remove_config" in
    [yY]|[yY][eE][sS])
        rm -f /etc/config/telegram
        config_removed=1
        success "Конфигурационные файлы успешно удалены"
        ;;
    *)
        info "Конфигурационные файлы сохранены (/etc/config/telegram)"
        ;;
esac

echo "-----------------------------------------------------"
info "Остановка и отключение службы telegram..."
if [ -f "/etc/init.d/telegram" ]; then
    /etc/init.d/telegram stop >/dev/null 2>&1
    /etc/init.d/telegram disable >/dev/null 2>&1
    rm -f /etc/init.d/telegram
fi

info "Удаление основных файлов бота..."
rm -rf /usr/lib/telegram-bot
rm -f /usr/bin/telegram-bot.sh
rm -f /usr/bin/telegram-monitor.sh
rm -rf /tmp/telegram-bot

luci_removed=0
if [ -f "/usr/lib/lua/luci/controller/telegram.lua" ] || [ -d "/usr/lib/lua/luci/view/telegram" ]; then
    info "Удаление компонентов веб-интерфейса LuCI..."
    rm -f /usr/lib/lua/luci/controller/telegram.lua
    rm -f /usr/lib/lua/luci/model/cbi/telegram.lua
    rm -rf /usr/lib/lua/luci/view/telegram
    
    # Очистка кэша LuCI
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
    luci_removed=1
fi

echo "====================================================="
printf "${GREEN}✅ Деинсталляция OpenWRT-TelegramBot завершена!${NC}\n"
echo "====================================================="
if [ "$config_removed" -eq 1 ]; then
    printf "${BLUE}🗑️ Конфигурация:${NC} Удалена\n"
else
    printf "${BLUE}📄 Конфигурация:${NC} Сохранена (/etc/config/telegram)\n"
fi

if [ "$luci_removed" -eq 1 ]; then
    printf "${BLUE}🗑️ Веб-интерфейс LuCI:${NC} Удален\n"
fi

printf "${BLUE}🔗 Ссылка на проект:${NC} https://github.com/vlam1n-dev/OpenWRT-TelegramBot\n"
echo "====================================================="
echo ""
