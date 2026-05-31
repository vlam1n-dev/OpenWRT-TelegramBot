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
MSG_WIFI_CLIENTS="клієнтів"
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

BTN_BLOCKED_DEVICES="🚫 Заблоковані"
BTN_UNBLOCK="🔓 Розблокувати"
BTN_KICK="🔌 Відключити"
BTN_BLOCK="🚫 Заблокувати"
MSG_DEV_REMAINING_LEASE="<b>Залишок оренди:</b>"
MSG_DEV_WIFI_IFACE="<b>Інтерфейс підключення:</b>"
MSG_DEV_RX_TX="<b>Швидкість RX / TX:</b>"
MSG_DEV_CONFIRM_KICK="Ви впевнені, що хочете <b>відключити</b> пристрій <b>%s</b>?"
MSG_DEV_CONFIRM_BLOCK="Ви впевнені, що хочете <b>заблокувати</b> пристрій <b>%s</b>?"
MSG_DEV_CONFIRM_UNBLOCK="Ви впевнені, що хочете <b>розблокувати</b> пристрій <b>%s</b>?"
MSG_DEV_KICKED="🔌 Пристрій <b>%s</b> успішно відключено"
MSG_DEV_BLOCKED="🚫 Пристрій <b>%s</b> заблоковано та відключено"
MSG_DEV_UNBLOCKED="🔓 Пристрій <b>%s</b> успішно розблоковано"
MSG_DEV_KICK_RESP="Пристрій відключено"
MSG_DEV_BLOCK_RESP="Пристрій заблоковано"
MSG_DEV_UNBLOCK_RESP="Пристрій розблоковано"
MSG_DEV_STATUS_NEW="Нове"
MSG_DEV_STATUS_KNOWN="Пристрій"
MSG_REFRESH_SUCCESS="Оновлено"
MSG_REFRESH_ERROR="Помилка"
MSG_BLOCKED_STATUS="Заблоковано"
MSG_BLOCKED_DEVICES_HEADER="🚫 <b>Заблоковані пристрої</b>"


# ── Interfaces ──
MSG_IFACES_HEADER="⚡ <b>Мережеві інтерфейси</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Ви впевнені, що хочете <b>увімкнути</b> інтерфейс <b>%s</b>?"
MSG_IFACE_CONFIRM_DOWN="Ви впевнені, що хочете <b>вимкнути</b> інтерфейс <b>%s</b>?"
MSG_IFACE_CONFIRM_REBOOT="Ви впевнені, що хочете <b>перезапустити</b> інтерфейс <b>%s</b>?"
MSG_IFACE_DONE_UP="✅ Інтерфейс <b>%s</b> <b>увімкнено</b>"
MSG_IFACE_DONE_DOWN="❌ Інтерфейс <b>%s</b> <b>вимкнено</b>"
MSG_IFACE_ERROR="⚠️ Не вдалося змінити стан інтерфейсу <b>%s</b>"
BTN_IFACE_UP="🟢 Увімкнути"
BTN_IFACE_DOWN="🔴 Вимкнути"
BTN_IFACE_RESTART="🔄 Перезапустити"
MSG_IFACE_STATUS="<b>Статус:</b>"
MSG_IFACE_PROTO="<b>Протокол:</b>"
MSG_IFACE_UPTIME="<b>Аптайм:</b>"
MSG_IFACE_MAC="<b>MAC:</b>"
MSG_IFACE_IPV4="<b>IPv4:</b>"
MSG_IFACE_IPV6="<b>IPv6:</b>"
MSG_IFACE_STATE_UP="Увімкнено"
MSG_IFACE_STATE_DOWN="Вимкнено"

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

NOTIFY_NEW_DEVICE="📱 <b>%s підключено до мережі!</b>\n\nІм'я: %s\nІнтерфейс: %s\nIP: <tg-spoiler>%s</tg-spoiler>\nMAC: <tg-spoiler>%s</tg-spoiler>"
NOTIFY_WAN_IP="🌐 <b>WAN IP змінився!</b>\n\nСтарий: <tg-spoiler>%s</tg-spoiler>\nНовий: <tg-spoiler>%s</tg-spoiler>"
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

# ── Нові функції (Діагностика, WoL, Трафик, Порти) ──
# Кнопки
BTN_DIAG="🔍 Діагностика"
BTN_WOL="🔔 Wake on Lan"
BTN_PORTS="🔀 Порти"
BTN_PORT_ADD="➕ Додати порт"
BTN_PORT_PROTO_TCP="TCP"
BTN_PORT_PROTO_UDP="UDP"
BTN_PORT_PROTO_ALL="TCP+UDP"
BTN_TRAFFIC_HOUR="🕒 За годину"
BTN_TRAFFIC_DAY="📅 За день"
BTN_TRAFFIC_MONTH="📆 За місяць"
BTN_TRAFFIC_DEVICE="📱 За пристроями"

# Діагностика
MSG_DIAG_HEADER="🔍 <b>Діагностика мережі</b>"
MSG_DIAG_PING_REQ="Введіть IP або хост для <b>Ping</b> (наприклад, <code>8.8.8.8</code> або <code>google.com</code>):"
MSG_DIAG_TRACE_REQ="Введіть IP або хост для <b>Traceroute</b> (наприклад, <code>1.1.1.1</code>):"
MSG_DIAG_DNS_REQ="Введіть домен для <b>DNS Lookup</b> (наприклад, <code>github.com</code>):"
MSG_DIAG_PORT_REQ="Введіть хост та порт у форматі <code>хост:порт</code> для <b>Port Check</b> (наприклад, <code>192.168.1.1:80</code>):"
MSG_DIAG_INVALID_INPUT="⚠️ Невірний формат введення або присутні недопустимі символи."
MSG_DIAG_RUNNING="⏳ Виконую команду..."
MSG_DIAG_RESULT="📝 <b>Результат:</b>\n<pre>%s</pre>"

# WoL
MSG_WOL_CONFIRM="🔔 Ви дійсно хочете відправити WoL-пакет на пристрій <b>%s</b>?"
MSG_WOL_SENT="🔔 WoL-пакет успішно відправлено на %s"
MSG_WOL_ERROR="❌ Утиліти etherwake або wol не знайдені в системі."

# Трафік
MSG_TRAFFIC_HEADER="📊 <b>Статистика трафіку</b>"
MSG_TRAFFIC_ERR_VNSTAT="❌ Пакет <b>vnStat</b> не встановлено в системі.\n\nВстановіть його за допомогою:\n<code>%s</code>"
MSG_TRAFFIC_ERR_NLBWMON="❌ Пакет <b>nlbwmon</b> не встановлено в системі.\n\nВстановіть його за допомогою:\n<code>%s</code>"
MSG_TRAFFIC_HOUR_TITLE="🕒 <b>Трафік за останні 24 години</b>\n\n"
MSG_TRAFFIC_DAY_TITLE="📅 <b>Трафік по днях</b>\n\n"
MSG_TRAFFIC_MONTH_TITLE="📆 <b>Трафік по місяцях</b>\n\n"
MSG_TRAFFIC_DEVICE_TITLE="📱 <b>Топ-10 пристроїв за трафіком</b>\n\n"

# Порти
MSG_PORTS_HEADER="🔀 <b>Перенаправлення портів (Port Forwarding)</b>"
MSG_PORTS_NONE="Правила перенаправлення портів не знайдені."
MSG_PORT_DETAILS="🔀 <b>Правило: %s</b>\n\n<b>Протокол:</b> %s\n<b>Зовнішній порт:</b> %s\n<b>Внутрішній IP:</b> %s\n<b>Внутрішній порт:</b> %s\n<b>Статус:</b> %s"
MSG_PORT_CONFIRM_DELETE="⚠️ Ви впевнені, що хочете <b>видалити</b> правило <b>%s</b>?"
MSG_PORT_DELETED="✅ Правило %s успішно видалено."
MSG_PORT_ADD_NAME="✍️ Введіть <b>назву</b> нового правила (наприклад, <code>Web Server</code>):"
MSG_PORT_ADD_EXT="✍️ Введіть <b>зовнішній порт</b> (наприклад, <code>8080</code>):"
MSG_PORT_ADD_IP="✍️ Введіть <b>внутрішню IP-адресу</b> пристрою (наприклад, <code>192.168.1.10</code>):"
MSG_PORT_ADD_INT="✍️ Введіть <b>внутрішній порт</b> (наприклад, <code>80</code>):"
MSG_PORT_ADD_PROTO="✍️ Виберіть <b>протокол</b> для правила:"
MSG_PORT_ADD_SUCCESS="✅ Правило %s успішно додано!"
MSG_PORT_INVALID_PORT="⚠️ Невірний порт. Введіть число від 1 до 65535."
MSG_PORT_INVALID_IP="⚠️ Невірна IP-адреса. Введіть коректний локальний IP."
MSG_CANCEL_MSG="↩️ Дію скасовано."
