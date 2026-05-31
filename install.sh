#!/bin/sh
# OpenWRT Telegram Bot — Установщик

# ANSI
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

# Сравнение семантических версий
version_compare() {
    local ver1="$1"
    local ver2="$2"
    
    ver1=$(echo "$ver1" | sed 's/^v//')
    ver2=$(echo "$ver2" | sed 's/^v//')
    
    [ "$ver1" = "$ver2" ] && return 1
    
    local IFS='.'
    set -- $ver1
    local v1_major="${1:-0}" v1_minor="${2:-0}" v1_patch="${3:-0}"
    set -- $ver2
    local v2_major="${1:-0}" v2_minor="${2:-0}" v2_patch="${3:-0}"
    
    if [ "$v1_major" -lt "$v2_major" ] 2>/dev/null; then return 0; fi
    if [ "$v1_major" -gt "$v2_major" ] 2>/dev/null; then return 2; fi
    
    if [ "$v1_minor" -lt "$v2_minor" ] 2>/dev/null; then return 0; fi
    if [ "$v1_minor" -gt "$v2_minor" ] 2>/dev/null; then return 2; fi
    
    if [ "$v1_patch" -lt "$v2_patch" ] 2>/dev/null; then return 0; fi
    if [ "$v1_patch" -gt "$v2_patch" ] 2>/dev/null; then return 2; fi
    
    return 1
}

if [ "$(id -u)" != "0" ]; then
    error "Этот скрипт должен быть запущен от root пользователя!"
    exit 1
fi

if [ ! -f "/etc/openwrt_release" ]; then
    error "Этот скрипт предназначен только для OpenWRT!"
    exit 1
fi

# Получение текущей версии
openwrt_ver=$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_RELEASE | cut -d"'" -f2)
if [ -z "$openwrt_ver" ]; then
    openwrt_ver=$(cat /etc/openwrt_version 2>/dev/null)
fi

info "Ваша версия OpenWRT: ${openwrt_ver:-Неизвестно}"
if [ "$openwrt_ver" != "25.12.0" ]; then
    warn "Тестирование данного бота проводилось только на OpenWRT версии 25.12.0"
    warn "Установка на вашу версию возможна, но стабильная работа всех функций не гарантируется"
    warn "Если были найдены ошибки, пожалуйста, сообщите нам - https://github.com/vlam1n-dev/OpenWRT-TelegramBot/issues/"
    echo ""
fi

# Определение пакетного менеджера
PKG_MANAGER=""
if command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
elif command -v opkg >/dev/null 2>&1; then
    PKG_MANAGER="opkg"
else
    error "С чего ты вообще это открыл?"
    exit 1
fi

info "Обновление списков пакетов для проверки базовых зависимостей..."
if [ "$PKG_MANAGER" = "apk" ]; then
    apk update >/dev/null 2>&1
    apk add curl jsonfilter ca-certificates >/dev/null 2>&1
else
    opkg update >/dev/null 2>&1
    opkg install curl jsonfilter ca-certificates ca-bundle >/dev/null 2>&1
fi

# Функция получения последней стабильной версии с GitHub
get_latest_tag() {
    local tag=""
    tag=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/vlam1n-dev/OpenWRT-TelegramBot/releases/latest" | jsonfilter -e '@.tag_name' 2>/dev/null)
    if [ -z "$tag" ]; then
        local tmp_latest="/tmp/latest_release.json"
        wget -qO "$tmp_latest" --no-check-certificate "https://api.github.com/repos/vlam1n-dev/OpenWRT-TelegramBot/releases/latest" 2>/dev/null
        if [ -f "$tmp_latest" ]; then
            tag=$(jsonfilter -i "$tmp_latest" -e '@.tag_name' 2>/dev/null)
            rm -f "$tmp_latest"
        fi
    fi
    [ -z "$tag" ] && tag="v1.0.67"
    echo "$tag"
}

# Функция валидации существования версии на GitHub
validate_version_github() {
    local ver="$1"
    local status=""
    status=$(curl -sL -w "%{http_code}" -o /dev/null "https://github.com/vlam1n-dev/OpenWRT-TelegramBot/archive/refs/tags/${ver}.tar.gz")
    if [ "$status" = "200" ]; then
        return 0
    fi
    if command -v wget >/dev/null 2>&1; then
        wget --spider --no-check-certificate "https://github.com/vlam1n-dev/OpenWRT-TelegramBot/archive/refs/tags/${ver}.tar.gz" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Установлен ли бот ранее
PREV_VER=""
if [ -f "/usr/lib/telegram-bot/VERSION" ]; then
    PREV_VER=$(cat /usr/lib/telegram-bot/VERSION 2>/dev/null)
    if [ -n "$PREV_VER" ]; then
        case "$PREV_VER" in
            v*) ;;
            *) PREV_VER="v$PREV_VER" ;;
        esac
    fi
fi

IS_UPDATE=0
INSTALL_VER=""

if [ -n "$PREV_VER" ]; then
    info "Бот уже установлен. Проверка обновлений на GitHub..."
    LATEST_TAG=$(get_latest_tag)
    version_compare "$PREV_VER" "$LATEST_TAG"
    cmp_res=$?
    
    if [ $cmp_res -eq 0 ]; then
        warn "Найдено обновление!"
        echo "   - Установленная версия: $PREV_VER"
        echo "   - Доступная версия:     $LATEST_TAG"
        echo ""
        printf "${YELLOW} Вы хотите обновить OpenWRT-TelegramBot до версии $LATEST_TAG? (Y/n): ${NC}"
        read user_update
        case "$user_update" in
            [nN]|[nN][oO])
                info "Пропуск обновления. Переход к ручному выбору версии..."
                ;;
            *)
                INSTALL_VER="$LATEST_TAG"
                IS_UPDATE=1
                ;;
        esac
    else
        # Установленная версия актуальна или новее
        success "У вас уже установлена актуальная версия: $PREV_VER (Доступная в релизах: $LATEST_TAG)"
        printf "${YELLOW} Вы хотите переустановить или выбрать другую версию для установки? (y/N): ${NC}"
        read user_reinstall
        case "$user_reinstall" in
            [yY]|[yY][eE][sS])
                info "Переход к выбору версии..."
                ;;
            *)
                success "Установка не требуется. Завершение работы."
                exit 0
                ;;
        esac
    fi
fi

# Если это не автоматическое обновление, запрашиваем версию у пользователя
if [ "$IS_UPDATE" -ne 1 ]; then
    echo "-----------------------------------------------------"
    while true; do
        printf "${YELLOW}✍️ Введите релизную версию для установки (например: v1.0.67) [Enter для последней]: ${NC}"
        read user_ver

        if [ -z "$user_ver" ]; then
            info "Поиск последней версии на GitHub..."
            INSTALL_VER=$(get_latest_tag)
            break
        else
            case "$user_ver" in
                v*) INSTALL_VER="$user_ver" ;;
                *) INSTALL_VER="v$user_ver" ;;
            esac
            
            info "Проверка существования версии $INSTALL_VER на GitHub..."
            if validate_version_github "$INSTALL_VER"; then
                success "Версия валидна и найдена на GitHub"
                break
            else
                error "Версия $INSTALL_VER не найдена на GitHub. Пожалуйста, введите корректный тег релиза"
            fi
        fi
    done
fi

info "Загрузка архива версии $INSTALL_VER..."
DOWNLOAD_URL="https://github.com/vlam1n-dev/OpenWRT-TelegramBot/archive/refs/tags/${INSTALL_VER}.tar.gz"
download_ok=0

curl -sL -o /tmp/bot.tar.gz "$DOWNLOAD_URL"
if [ $? -eq 0 ] && [ -s /tmp/bot.tar.gz ]; then
    download_ok=1
else
    wget -qO /tmp/bot.tar.gz --no-check-certificate "$DOWNLOAD_URL" 2>/dev/null
    if [ $? -eq 0 ] && [ -s /tmp/bot.tar.gz ]; then
        download_ok=1
    fi
fi

if [ "$download_ok" -ne 1 ]; then
    error "Не удалось скачать архив версии $INSTALL_VER. Проверьте сеть и повторите попытку!"
    exit 1
fi

info "Распаковка архива..."
rm -rf /tmp/OpenWRT-TelegramBot-*
tar -zxf /tmp/bot.tar.gz -C /tmp/
if [ $? -ne 0 ]; then
    error "Не удалось распаковать файлы!"
    rm -f /tmp/bot.tar.gz
    exit 1
fi

EXTRACTED_DIR=$(find /tmp -maxdepth 1 -type d -name "OpenWRT-TelegramBot-*" | head -n 1)
if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR" ]; then
    error "Не удалось найти распакованную директорию исходного кода!"
    rm -f /tmp/bot.tar.gz
    exit 1
fi

# Копирование основных файлов
info "Копирование основных файлов бота..."
mkdir -p /usr/lib/telegram-bot/lang
mkdir -p /usr/bin

cp -f "$EXTRACTED_DIR/bot/telegram-bot-lib.sh" /usr/lib/telegram-bot/
cp -f "$EXTRACTED_DIR/bot/telegram-bot.sh" /usr/bin/
cp -f "$EXTRACTED_DIR/bot/telegram-monitor.sh" /usr/bin/
echo "$INSTALL_VER" | sed 's/^v//' > /usr/lib/telegram-bot/VERSION
cp -f "$EXTRACTED_DIR/bot/lang/"*.sh /usr/lib/telegram-bot/lang/

chmod +x /usr/bin/telegram-bot.sh
chmod +x /usr/bin/telegram-monitor.sh

if [ ! -f "/etc/config/telegram" ]; then
    cp -f "$EXTRACTED_DIR/config/telegram" /etc/config/
fi

cp -f "$EXTRACTED_DIR/init.d/telegram" /etc/init.d/
chmod +x /etc/init.d/telegram

# Проверка и установка LuCI
luci_installed=0
if [ -d "/usr/lib/lua/luci" ]; then
    echo "-----------------------------------------------------"
    printf "${YELLOW} Установить компоненты веб-интерфейса LuCI для настройки бота? (Y/n) [рекомендуется]: ${NC}"
    read user_luci
    case "$user_luci" in
        [nN]|[nN][oO])
            info "Установка компонентов LuCI пропущена"
            ;;
        *)
            info "Установка компонентов LuCI..."
            mkdir -p /usr/lib/lua/luci/controller
            mkdir -p /usr/lib/lua/luci/model/cbi
            mkdir -p /usr/lib/lua/luci/view/telegram
            
            cp -f "$EXTRACTED_DIR/luci/controller/telegram.lua" /usr/lib/lua/luci/controller/
            cp -f "$EXTRACTED_DIR/luci/model/cbi/telegram.lua" /usr/lib/lua/luci/model/cbi/
            cp -f "$EXTRACTED_DIR/luci/view/telegram/"*.htm /usr/lib/lua/luci/view/telegram/
            
            rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
            luci_installed=1
            ;;
    esac
fi

# Установка дополнительных пакетов
ext_installed=""
ext_failed=""
echo "-----------------------------------------------------"
info "Для полноценной работы бота требуются дополнительные компоненты:"
echo "   - etherwake (функция Wake on Lan)"
echo "   - vnstat (детальная статистика трафика)"
echo "   - nlbwmon (отображение потребления трафика устройствами)"
printf "${YELLOW}Установить эти компоненты сейчас? (y/N): ${NC}"
read user_ext

case "$user_ext" in
    [yY]|[yY][eE][sS])
        info "Установка дополнительных компонентов..."
        for pkg in etherwake vnstat nlbwmon; do
            info "Установка пакета $pkg..."
            if [ "$PKG_MANAGER" = "apk" ]; then
                apk add "$pkg" >/dev/null 2>&1
            else
                opkg install "$pkg" >/dev/null 2>&1
            fi
            
            if [ $? -eq 0 ]; then
                ext_installed="$ext_installed $pkg"
            else
                ext_failed="$ext_failed $pkg"
            fi
        done
        ;;
    *)
        info "Установка дополнительных компонентов пропущена. Вы можете установить эти компоненты самостоятельно позже!"
        ;;
esac

echo "-----------------------------------------------------"
info "Запуск и включение службы telegram..."
/etc/init.d/telegram enable >/dev/null 2>&1

token=$(uci -q get telegram.bot.api_token)
enabled=$(uci -q get telegram.bot.enabled || echo 0)

if [ -n "$token" ]; then
    if [ "$enabled" != "1" ]; then
        uci set telegram.bot.enabled='1'
        uci commit telegram
    fi
    info "API токен найден. Запуск службы telegram..."
    /etc/init.d/telegram restart >/dev/null 2>&1
else
    /etc/init.d/telegram restart >/dev/null 2>&1
    warn "API токен не настроен. Бот не запустится до тех пор, пока вы не вставите токен в LuCI (Службы -> Telegram Bot) или вручную в /etc/config/telegram."
fi

# Очистка
rm -f /tmp/bot.tar.gz
rm -rf /tmp/OpenWRT-TelegramBot-*

# Итог
echo ""
if [ "$IS_UPDATE" -eq 1 ]; then
    printf "${GREEN}=====================================================${NC}\n"
    printf "${GREEN}✅ Обновление OpenWRT-TelegramBot успешно завершено!${NC}\n"
    printf "${GREEN}=====================================================${NC}\n"
    printf "${BLUE}📁 Предыдущая версия:${NC} %s\n" "$PREV_VER"
    printf "${BLUE}📁 Новая версия:${NC} %s\n" "$INSTALL_VER"
    printf "${BLUE}📄 Путь к конфигу:${NC} /etc/config/telegram\n"
    if [ "$luci_installed" -eq 1 ]; then
        printf "${BLUE}🌐 Веб-интерфейс LuCI:${NC} установлен/обновлен (вкладка Services -> Telegram Bot)\n"
    else
        printf "${BLUE}🌐 Веб-интерфейс LuCI:${NC} не изменялся\n"
    fi
    if [ -n "$ext_installed" ]; then
        printf "${BLUE}📦 Обновленные пакеты:${NC} %s\n" "$ext_installed"
    fi
    if [ -n "$ext_failed" ]; then
        warn "Ошибка установки пакетов: $ext_failed (установите вручную)"
    fi
    printf "${BLUE}📝 Список изменений:${NC} https://github.com/vlam1n-dev/OpenWRT-TelegramBot/releases/tag/%s\n" "$INSTALL_VER"
else
    printf "${GREEN}=====================================================${NC}\n"
    printf "${GREEN}✅ Установка OpenWRT-TelegramBot успешно завершена!${NC}\n"
    printf "${GREEN}=====================================================${NC}\n"
    printf "${BLUE}📁 Установленная версия:${NC} %s\n" "$INSTALL_VER"
    printf "${BLUE}📄 Путь к конфигу:${NC} /etc/config/telegram\n"
    if [ "$luci_installed" -eq 1 ]; then
        printf "${BLUE}🌐 Веб-интерфейс LuCI:${NC} установлен (вкладка Services -> Telegram Bot)\n"
    else
        printf "${BLUE}🌐 Веб-интерфейс LuCI:${NC} не устанавливался\n"
    fi
    if [ -n "$ext_installed" ]; then
        printf "${BLUE}📦 Установленные пакеты:${NC} %s\n" "$ext_installed"
    fi
    if [ -n "$ext_failed" ]; then
        warn "Ошибка установки пакетов: $ext_failed (установите вручную)"
    fi
fi

printf "${BLUE}🔗 Ссылка на проект:${NC} https://github.com/vlam1n-dev/OpenWRT-TelegramBot\n"
printf "${BLUE}🔗 Информация:${NC} https://github.com/vlam1n-dev/OpenWRT-TelegramBot/blob/main/README.md\n"
printf "${GREEN}=====================================================${NC}\n"
echo ""
