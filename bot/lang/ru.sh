#!/bin/sh
# OpenWRT Telegram Bot — Russian language file
# shellcheck disable=SC2034

# ── Главное меню ──
MSG_SYS_INFO_HEADER="📊 <b>Информация о системе</b>"
MSG_HOSTNAME="🖥 <b>Имя хоста:</b>"
MSG_VERSION="📦 <b>Версия:</b>"
MSG_KERNEL="🐧 <b>Ядро:</b>"
MSG_UPTIME="⏱ <b>Аптайм:</b>"
MSG_RAM="💾 <b>ОЗУ:</b>"
MSG_FLASH="💿 <b>Flash:</b>"
MSG_WAN_IP="🌐 <b>WAN IP:</b>"
MSG_WIFI_STATUS="📶 <b>WiFi:</b>"
MSG_BOT_VER="🤖 <b>Бот v:</b>"

BTN_RESTART="🔄 Перезагрузка"
BTN_INTERFACES="⚡ Интерфейсы"
BTN_STATS="📊 Статистика"
BTN_DEVICES="📱 Устройства"
BTN_SETTINGS="⚙️ Настройки"
BTN_REFRESH="🔃 Обновить"

# ── Статистика ──
MSG_STATS_HEADER="📊 <b>Статистика системы</b>"
MSG_CPU="🔲 <b>CPU:</b>"
MSG_RAM_USED="💾 <b>ОЗУ занято:</b>"
MSG_RAM_FREE="💾 <b>ОЗУ свободно:</b>"
MSG_RAM_TOTAL="💾 <b>ОЗУ всего:</b>"
MSG_FLASH_USED="💿 <b>Flash занято:</b>"
MSG_FLASH_FREE="💿 <b>Flash свободно:</b>"
MSG_FLASH_TOTAL="💿 <b>Flash всего:</b>"
MSG_LOAD_AVG="📈 <b>Нагрузка:</b>"
MSG_PROCESSES="⚙️ <b>Процессы:</b>"
MSG_NET_RX="📥 <b>Загрузка:</b>"
MSG_NET_TX="📤 <b>Отдача:</b>"
BTN_BACK="◀️ Назад"

# ── Устройства ──
MSG_DEVICES_HEADER="📱 <b>Подключённые устройства</b>"
MSG_DEVICES_NONE="Устройства не найдены"
MSG_DEVICE_IP="IP:"
MSG_DEVICE_MAC="MAC:"
MSG_DEVICE_NAME="Имя:"
MSG_DEVICES_COUNT="Всего:"

# ── Интерфейсы ──
MSG_IFACES_HEADER="⚡ <b>Сетевые интерфейсы</b>"
MSG_IFACE_ON="✅"
MSG_IFACE_OFF="❌"
MSG_IFACE_CONFIRM_UP="Вы уверены, что хотите <b>включить</b> интерфейс <b>%s</b>?"
MSG_IFACE_CONFIRM_DOWN="Вы уверены, что хотите <b>выключить</b> интерфейс <b>%s</b>?"
MSG_IFACE_DONE_UP="✅ Интерфейс <b>%s</b> был <b>включён</b>"
MSG_IFACE_DONE_DOWN="❌ Интерфейс <b>%s</b> был <b>выключен</b>"
MSG_IFACE_ERROR="⚠️ Не удалось переключить интерфейс <b>%s</b>"

# ── Перезагрузка ──
MSG_REBOOT_CONFIRM="⚠️ Вы уверены, что хотите <b>перезагрузить</b> роутер?"
MSG_REBOOT_OK="🔄 Роутер перезагружается..."
MSG_REBOOT_CANCEL="↩️ Перезагрузка отменена"
BTN_YES="✅ Да"
BTN_NO="❌ Нет"

# ── Настройки ──
MSG_SETTINGS_HEADER="⚙️ <b>Настройки</b>"
BTN_NOTIFICATIONS="🔔 Уведомления"
BTN_LANGUAGE="🌐 Язык"

# ── Уведомления ──
MSG_NOTIFY_HEADER="🔔 <b>Настройки уведомлений</b>"
MSG_NOTIFY_HINT="Нажмите для включения/выключения:"
BTN_NOTIFY_NEWDEV="📱 Новое устройство"
BTN_NOTIFY_WANIP="🌐 Смена WAN IP"
BTN_NOTIFY_CPU="🔲 Высокая нагрузка CPU"
BTN_NOTIFY_RAM="💾 Высокое потребление ОЗУ"
BTN_NOTIFY_UPD="📦 Обновление бота"
MSG_NOTIFY_ENABLED="✅"
MSG_NOTIFY_DISABLED="❌"

NOTIFY_NEW_DEVICE="📱 <b>Новое устройство подключено!</b>\n\nИмя: %s\nIP: %s\nMAC: %s"
NOTIFY_WAN_IP="🌐 <b>WAN IP изменился!</b>\n\nСтарый: %s\nНовый: %s"
NOTIFY_HIGH_CPU="🔲 <b>Высокая нагрузка CPU!</b>\n\nНагрузка: %s%%\nПорог: %s%%"
NOTIFY_HIGH_RAM="💾 <b>Высокое потребление ОЗУ!</b>\n\nЗанято: %s%%\nПорог: %s%%"
NOTIFY_UPDATE="📦 <b>Доступно обновление бота!</b>\n\nТекущая: %s\nНовая: %s\nРепозиторий: %s"

# ── Язык ──
MSG_LANG_HEADER="🌐 <b>Language / Язык</b>"
MSG_LANG_CURRENT="Текущий язык: <b>Русский</b>"
MSG_LANG_CHANGED="🌐 Язык изменён на <b>Русский</b>"
BTN_LANG_EN="🇬🇧 English"
BTN_LANG_RU="🇷🇺 Русский"
BTN_LANG_UK="🇺🇦 Українська"
BTN_LANG_DE="🇩🇪 Deutsch"

# ── Авторизация ──
MSG_ACCESS_DENIED="⛔ <b>Доступ запрещён</b>\n\nВы не авторизованы для использования этого бота.\nВаш ID: <code>%s</code>"

# ── Ошибки ──
MSG_API_ERROR="⚠️ Ошибка Telegram API"
MSG_RATE_LIMITED="⏳ Слишком много запросов. Подождите."
MSG_UNKNOWN_CMD="❓ Неизвестная команда. Используйте /start"

# ── О боте & Обновления ──
BTN_ABOUT="ℹ️ О боте"
MSG_ABOUT_HEADER="ℹ️ <b>О боте OpenWRT Telegram Bot</b>"
MSG_ABOUT_TEXT="<b>OpenWRT Telegram Bot</b>\n\n👤 <b>Автор:</b> VLaM1N-Dev\n🌐 <b>GitHub:</b> <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>\n📄 <b>Лицензия:</b> MIT\n🤖 <b>Версия:</b> %s"
BTN_CHECK_UPDATES="📥 Проверить обновления"
MSG_CHECKING_UPDATES="⏳ Проверка обновлений..."
MSG_UPD_LATEST="✅ У вас установлена последняя версия (v%s)."
MSG_UPD_AVAILABLE="📥 <b>Доступно новое обновление!</b>\n\nНовая версия: <b>v%s</b>\nСкачать: <a href=\"https://github.com/vlam1n-dev/OpenWRT-TelegramBot\">vlam1n-dev/OpenWRT-TelegramBot</a>"
MSG_UPD_ERROR="❌ Не удалось проверить обновления. Пожалуйста, попробуйте позже."
MSG_UPD_COOLDOWN="⏳ Пожалуйста, подождите %s сек. перед повторной проверкой."

