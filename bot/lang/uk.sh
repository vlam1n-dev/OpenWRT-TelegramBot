#!/bin/sh
# OpenWRT Telegram Bot — Ukrainian language file
# shellcheck disable=SC2034

# ── Main menu ──
MSG_SYS_INFO_HEADER="📊 <b>Інформація про систему</b>"
MSG_HOSTNAME="🖥 <b>Ім'я хоста:</b>"
MSG_VERSION="📦 <b>Версія:</b>"
MSG_KERNEL="🐧 <b>Ядро:</b>"
MSG_UPTIME="⏱ <b>Аптайм:</b>"
MSG_RAM="💾 <b>ОЗУ:</b>"
MSG_FLASH="💿 <b>Flash:</b>"
MSG_WAN_IP="🌐 <b>WAN IP:</b>"
MSG_WIFI_STATUS="📶 <b>WiFi:</b>"
MSG_BOT_VER="🤖 <b>Бот v:</b>"

BTN_RESTART="🔄 Перезапуск"
BTN_INTERFACES="⚡ Інтерфейси"
BTN_STATS="📊 Статистика"
BTN_DEVICES="📱 Пристрої"
BTN_SETTINGS="⚙️ Налаштування"
BTN_REFRESH="🔃 Оновити"

# ── Statistics ──
MSG_STATS_HEADER="📊 <b>Системна статистика</b>"
MSG_CPU="🔲 <b>CPU:</b>"
MSG_RAM_USED="💾 <b>ОЗУ зайнято:</b>"
MSG_RAM_FREE="💾 <b>ОЗУ вільно:</b>"
MSG_RAM_TOTAL="💾 <b>ОЗУ всього:</b>"
MSG_FLASH_USED="💿 <b>Flash зайнято:</b>"
MSG_FLASH_FREE="💿 <b>Flash вільно:</b>"
MSG_FLASH_TOTAL="💿 <b>Flash всього:</b>"
MSG_LOAD_AVG="📈 <b>Load Avg:</b>"
MSG_PROCESSES="⚙️ <b>Процеси:</b>"
MSG_NET_RX="📥 <b>Завантаження:</b>"
MSG_NET_TX="📤 <b>Віддача:</b>"
BTN_BACK="◀️ Назад"

# ── Devices ──
MSG_DEVICES_HEADER="📱 <b>Підключені пристрої</b>"
MSG_DEVICES_NONE="Пристроїв не знайдено"
MSG_DEVICE_IP="IP:"
MSG_DEVICE_MAC="MAC:"
MSG_DEVICE_NAME="Ім'я:"
MSG_DEVICES_COUNT="Всього:"

# ── Interfaces ──
MSG_IFACES_HEADER="⚡ <b>Мережеві інтерфейси</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Ви впевнені, що хочете <b>увімкнути</b> інтерфейс <b>%s</b>?"
MSG_IFACE_CONFIRM_DOWN="Ви впевнені, що хочете <b>вимкнути</b> інтерфейс <b>%s</b>?"
MSG_IFACE_DONE_UP="✅ Інтерфейс <b>%s</b> <b>увімкнено</b>"
MSG_IFACE_DONE_DOWN="❌ Інтерфейс <b>%s</b> <b>вимкнено</b>"
MSG_IFACE_ERROR="⚠️ Не вдалося змінити стан інтерфейсу <b>%s</b>"

# ── Reboot ──
MSG_REBOOT_CONFIRM="⚠️ Ви впевнені, що хочете <b>перезавантажити</b> роутер?"
MSG_REBOOT_OK="🔄 Перезавантаження роутера..."
MSG_REBOOT_CANCEL="↩️ Перезавантаження скасовано"
BTN_YES="✅ Так"
BTN_NO="❌ Ні"

# ── Settings ──
MSG_SETTINGS_HEADER="⚙️ <b>Налаштування</b>"
BTN_NOTIFICATIONS="🔔 Сповіщення"
BTN_LANGUAGE="🌐 Мова"

# ── Notifications ──
MSG_NOTIFY_HEADER="🔔 <b>Налаштування сповіщень</b>"
MSG_NOTIFY_HINT="Натисніть для увімкнення/вимкнення:"
BTN_NOTIFY_NEWDEV="📱 Новий пристрій"
BTN_NOTIFY_WANIP="🌐 Зміна WAN IP"
BTN_NOTIFY_CPU="🔲 Високе завантаження CPU"
BTN_NOTIFY_RAM="💾 Високе використання ОЗУ"
BTN_NOTIFY_UPD="📦 Оновлення бота"
MSG_NOTIFY_ENABLED="✅"
MSG_NOTIFY_DISABLED="❌"

NOTIFY_NEW_DEVICE="📱 <b>Підключено новий пристрій!</b>\n\nІм'я: %s\nIP: %s\nMAC: %s"
NOTIFY_WAN_IP="🌐 <b>WAN IP змінився!</b>\n\nСтарий: %s\nНовий: %s"
NOTIFY_HIGH_CPU="🔲 <b>Високе завантаження CPU!</b>\n\nНавантаження: %s%%\nПоріг: %s%%"
NOTIFY_HIGH_RAM="💾 <b>Високе використання ОЗУ!</b>\n\nВикористано: %s%%\nПоріг: %s%%"
NOTIFY_UPDATE="📦 <b>Доступно оновлення бота!</b>\n\nПоточна: %s\nАктуальна: %s\nРепозиторій: %s"

# ── Language ──
MSG_LANG_HEADER="🌐 <b>Language / Мова</b>"
MSG_LANG_CURRENT="Поточна мова: <b>Українська</b>"
MSG_LANG_CHANGED="🌐 Мову змінено на <b>Українську</b>"
BTN_LANG_EN="🇬🇧 English"
BTN_LANG_RU="🇷🇺 Русский"
BTN_LANG_UK="🇺🇦 Українська"
BTN_LANG_DE="🇩🇪 Deutsch"

# ── Auth ──
MSG_ACCESS_DENIED="⛔ <b>Доступ заборонено</b>\n\nВи не авторизовані для використання цього бота.\nВаш ID: <code>%s</code>"

# ── Errors ──
MSG_API_ERROR="⚠️ Помилка Telegram API"
MSG_RATE_LIMITED="⏳ Занадто багато запитів. Будь ласка, зачекайте."
MSG_UNKNOWN_CMD="❓ Невідома команда. Використовуйте /start"

# ── About & Updates ──
BTN_ABOUT="ℹ️ Про бота"
MSG_ABOUT_HEADER="ℹ️ <b>Про OpenWRT Telegram Bot</b>"
MSG_ABOUT_TEXT="<b>OpenWRT Telegram Bot</b>\n\n👤 <b>Автор:</b> VLaM1N-Dev\n🌐 <b>GitHub:</b> <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>\n📄 <b>Ліцензія:</b> MIT\n🤖 <b>Версія:</b> %s"
BTN_CHECK_UPDATES="📥 Перевірити оновлення"
MSG_CHECKING_UPDATES="⏳ Перевірка оновлень..."
MSG_UPD_LATEST="✅ У вас встановлена остання версія (v%s)."
MSG_UPD_AVAILABLE="📥 <b>Доступне нове оновлення!</b>\n\nНова версія: <b>v%s</b>\nЗавантажити: <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>"
MSG_UPD_ERROR="❌ Не вдалося перевірити оновлення. Будь ласка, спробуйте пізніше."
MSG_UPD_COOLDOWN="⏳ Будь ласка, зачекайте %s сек. перед повторною перевіркою."
