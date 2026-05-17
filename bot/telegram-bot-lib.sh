#!/bin/sh
# OpenWRT Telegram Bot Library
# Functions for API calls, system monitoring and localization

# Directories and files
BOT_DIR="/tmp/telegram-bot"
PID_FILE="${BOT_DIR}/bot.pid"
OFFSET_FILE="${BOT_DIR}/last_update_id"
RESP_FILE="${BOT_DIR}/response.json"

# Variables initialized from config
API_TOKEN=""
ADMIN_IDS=""
POLL_TIMEOUT=30
CURL_CONNECT_TIMEOUT=10
CURL_MAX_TIME=30
LANG_CODE="en"
GITHUB_REPO="vlam1n-dev/OpenWRT-TelegramBot"
BOT_VERSION="1.0.0"
[ -f "/usr/lib/telegram-bot/VERSION" ] && BOT_VERSION=$(cat /usr/lib/telegram-bot/VERSION)
[ -f "./VERSION" ] && BOT_VERSION=$(cat ./VERSION)

# Rate Limiting memory
RATE_LIMIT_COUNT=10
RATE_LIMIT_WINDOW=3
RATE_LIMIT_FILE="${BOT_DIR}/rate_limits"

mkdir -p "$BOT_DIR"

load_config() {
    # Load settings from UCI
    API_TOKEN=$(uci -q get telegram.bot.api_token)
    POLL_TIMEOUT=$(uci -q get telegram.bot.poll_timeout)
    [ -z "$POLL_TIMEOUT" ] && POLL_TIMEOUT=30
    
    CURL_CONNECT_TIMEOUT=$(uci -q get telegram.bot.curl_connect_timeout)
    [ -z "$CURL_CONNECT_TIMEOUT" ] && CURL_CONNECT_TIMEOUT=10
    
    CURL_MAX_TIME=$(uci -q get telegram.bot.curl_max_time)
    [ -z "$CURL_MAX_TIME" ] && CURL_MAX_TIME=30
    
    LANG_CODE=$(uci -q get telegram.bot.language)
    [ -z "$LANG_CODE" ] && LANG_CODE="en"
    
    RATE_LIMIT_COUNT=$(uci -q get telegram.bot.rate_limit_count)
    [ -z "$RATE_LIMIT_COUNT" ] && RATE_LIMIT_COUNT=10
    
    RATE_LIMIT_WINDOW=$(uci -q get telegram.bot.rate_limit_window)
    [ -z "$RATE_LIMIT_WINDOW" ] && RATE_LIMIT_WINDOW=3
    
    ADMIN_IDS=$(uci -q get telegram.admins.admin_id)
    
    # Load language file
    if [ -f "/usr/lib/telegram-bot/lang/${LANG_CODE}.sh" ]; then
        . "/usr/lib/telegram-bot/lang/${LANG_CODE}.sh"
    elif [ -f "./lang/${LANG_CODE}.sh" ]; then
        . "./lang/${LANG_CODE}.sh"
    fi
}

# Escape text for safe JSON embedding (newlines, quotes, backslashes)
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\\\\n/\\n/g' | awk '{printf "%s%s", (NR>1?"\\n":""), $0}'
}

tg_api_call() {
    local method="$1"
    local data="$2"
    
    curl -s --connect-timeout "$CURL_CONNECT_TIMEOUT" \
         --max-time "$CURL_MAX_TIME" \
         -H "Content-Type: application/json" \
         -X POST -d "$data" \
         "https://api.telegram.org/bot${API_TOKEN}/${method}"
}

tg_send_message() {
    local chat_id="$1"
    local text=$(json_escape "$2")
    local keyboard="$3"
    
    local payload="{\"chat_id\": \"${chat_id}\", \"text\": \"${text}\", \"parse_mode\": \"HTML\""
    
    if [ -n "$keyboard" ]; then
        payload="${payload}, \"reply_markup\": {\"inline_keyboard\": ${keyboard}}"
    fi
    payload="${payload}}"
    
    tg_api_call "sendMessage" "$payload"
}

tg_edit_message_text() {
    local chat_id="$1"
    local message_id="$2"
    local text=$(json_escape "$3")
    local keyboard="$4"
    
    local payload="{\"chat_id\": \"${chat_id}\", \"message_id\": ${message_id}, \"text\": \"${text}\", \"parse_mode\": \"HTML\""
    
    if [ -n "$keyboard" ]; then
        payload="${payload}, \"reply_markup\": {\"inline_keyboard\": ${keyboard}}"
    fi
    payload="${payload}}"
    
    tg_api_call "editMessageText" "$payload"
}

tg_answer_callback() {
    local callback_id="$1"
    local text="$2"
    local show_alert="$3"
    
    local payload="{\"callback_query_id\": \"${callback_id}\""
    
    if [ -n "$text" ]; then
        payload="${payload}, \"text\": \"${text}\"" 
    fi
    if [ "$show_alert" = "true" ]; then
        payload="${payload}, \"show_alert\": true"
    fi
    payload="${payload}}"
    
    tg_api_call "answerCallbackQuery" "$payload"
}

check_admin() {
    local chat_id="$1"
    for admin in $ADMIN_IDS; do
        if [ "$admin" = "$chat_id" ]; then
            return 0
        fi
    done
    return 1
}

write_to_log_file() {
    local log_type="$1"
    local message="$2"
    
    local log_file=""
    local max_lines=1000
    local reset_time=86400
    
    if [ "$log_type" = "bot" ]; then
        log_file="/tmp/telegram-bot/bot.log"
        max_lines=$(uci -q get telegram.bot.log_bot_max_lines || echo 1000)
        reset_time=$(uci -q get telegram.bot.log_bot_reset_time || echo 86400)
    else
        log_file="/tmp/telegram-bot/unauth.log"
        max_lines=$(uci -q get telegram.bot.log_auth_max_lines || echo 1000)
        reset_time=$(uci -q get telegram.bot.log_auth_reset_time || echo 86400)
    fi
    
    mkdir -p "/tmp/telegram-bot"
    
    if [ "$reset_time" -gt 0 ] && [ -f "$log_file" ]; then
        local now=$(date +%s)
        local file_time=$(date -r "$log_file" +%s 2>/dev/null || stat -c %Y "$log_file" 2>/dev/null || echo 0)
        if [ "$file_time" -gt 0 ] && [ "$((now - file_time))" -ge "$reset_time" ]; then
            echo -n "" > "$log_file"
        fi
    fi
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] ${message}" >> "$log_file"
    
    if [ "$max_lines" -gt 0 ] && [ -f "$log_file" ]; then
        local line_count=$(wc -l < "$log_file")
        if [ "$line_count" -gt "$max_lines" ]; then
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Log cleared (reached max limit of ${max_lines} lines)" > "$log_file"
        fi
    fi
}

log_info() {
    local msg="$1"
    logger -t telegram-bot.info "$msg"
    write_to_log_file "bot" "INFO: $msg"
}

log_error() {
    local msg="$1"
    logger -t telegram-bot.error "$msg"
    write_to_log_file "bot" "ERROR: $msg"
}

log_unauthorized() {
    local user_id="$1"
    local username="$2"
    local chat_id="$3"
    local message="$4"
    
    local msg="[auth] UNAUTHORIZED access attempt: user_id=${user_id}, username=${username}, chat_id=${chat_id}, message=\"${message}\""
    logger -t telegram-bot.warn -p user.warning "$msg"
    write_to_log_file "auth" "$msg"
}

check_rate_limit() {
    local user_id="$1"
    local now=$(date +%s)
    local history_file="${RATE_LIMIT_FILE}_${user_id}"
    
    # Remove old entries
    if [ -f "$history_file" ]; then
        awk -v threshold="$((now - RATE_LIMIT_WINDOW))" '$1 > threshold' "$history_file" > "${history_file}.tmp"
        mv "${history_file}.tmp" "$history_file"
    else
        touch "$history_file"
    fi
    
    local req_count=$(wc -l < "$history_file")
    
    if [ "$req_count" -ge "$RATE_LIMIT_COUNT" ]; then
        return 1
    fi
    
    echo "$now" >> "$history_file"
    return 0
}

# --- System Functions ---
get_system_info() {
    local hostname=$(uci -q get system.@system[0].hostname || cat /proc/sys/kernel/hostname)
    local openwrt_ver=$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_RELEASE | cut -d"'" -f2)
    local kernel_ver=$(uname -r)
    
    local uptime_s=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
    local d=$((uptime_s / 86400))
    local h=$((uptime_s % 86400 / 3600))
    local m=$((uptime_s % 3600 / 60))
    local uptime_str="${d}d ${h}h ${m}m"
    
    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    [ -z "$mem_free" ] && mem_free=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    mem_total=$((mem_total / 1024))
    mem_free=$((mem_free / 1024))
    local mem_used=$((mem_total - mem_free))
    local mem_pct=$(( mem_used * 100 / mem_total ))
    
    local flash_total=$(df -k / | tail -1 | awk '{print $2}')
    local flash_used=$(df -k / | tail -1 | awk '{print $3}')
    flash_total=$((flash_total / 1024))
    flash_used=$((flash_used / 1024))
    local flash_pct=$(( flash_used * 100 / flash_total ))
    
    local wan_ip=$(network_get_ipaddr wan 2>/dev/null)
    [ -z "$wan_ip" ] && wan_ip=$(ip -4 addr show br-wan 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [ -z "$wan_ip" ] && wan_ip=$(wget -qO- http://checkip.amazonaws.com 2>/dev/null)
    [ -z "$wan_ip" ] && wan_ip="Unknown"
    
    local wifi_status="Unknown"
    if [ -x "/sbin/wifi" ]; then
        local wifi_clients=$(iw dev | grep Interface | awk '{print $2}' | xargs -I {} iw dev {} station dump 2>/dev/null | grep Station | wc -l)
        wifi_status="$wifi_clients clients"
    fi
    
    printf "%s\n%s %s\n%s %s\n%s %s\n%s %s\n%s %s/%s MB (%s%%)\n%s %s/%s MB (%s%%)\n%s %s\n%s %s\n" \
        "$MSG_SYS_INFO_HEADER" \
        "$MSG_HOSTNAME" "$hostname" \
        "$MSG_VERSION" "$openwrt_ver" \
        "$MSG_KERNEL" "$kernel_ver" \
        "$MSG_UPTIME" "$uptime_str" \
        "$MSG_RAM" "$mem_used" "$mem_total" "$mem_pct" \
        "$MSG_FLASH" "$flash_used" "$flash_total" "$flash_pct" \
        "$MSG_WAN_IP" "$wan_ip" \
        "$MSG_WIFI_STATUS" "$wifi_status"
}

get_system_stats() {
    local cpu_idle=$(top -n 1 | grep '^CPU:' | awk '{print $8}' | sed 's/%//')
    local cpu_load="Unknown"
    if [ -n "$cpu_idle" ]; then
        cpu_load=$((100 - cpu_idle))
    else
        # fallback for different top format
        local load_avg=$(cat /proc/loadavg | awk '{print $1}')
        cpu_load="$load_avg"
    fi
    
    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    [ -z "$mem_free" ] && mem_free=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    mem_total=$((mem_total / 1024))
    mem_free=$((mem_free / 1024))
    local mem_used=$((mem_total - mem_free))
    
    local flash_total=$(df -m / | tail -1 | awk '{print $2}')
    local flash_used=$(df -m / | tail -1 | awk '{print $3}')
    local flash_free=$(df -m / | tail -1 | awk '{print $4}')
    
    local load_avg_full=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local processes=$(ps -e 2>/dev/null | wc -l)
    [ "$processes" = "0" ] && processes=$(ps | wc -l)
    
    printf "%s\n\n%s %s%%\n%s %s MB\n%s %s MB\n%s %s MB\n\n%s %s MB\n%s %s MB\n%s %s MB\n\n%s %s\n%s %s\n" \
        "$MSG_STATS_HEADER" \
        "$MSG_CPU" "$cpu_load" \
        "$MSG_RAM_USED" "$mem_used" \
        "$MSG_RAM_FREE" "$mem_free" \
        "$MSG_RAM_TOTAL" "$mem_total" \
        "$MSG_FLASH_USED" "$flash_used" \
        "$MSG_FLASH_FREE" "$flash_free" \
        "$MSG_FLASH_TOTAL" "$flash_total" \
        "$MSG_LOAD_AVG" "$load_avg_full" \
        "$MSG_PROCESSES" "$processes"
}

get_connected_devices() {
    local leases="/tmp/dhcp.leases"
    local output=""
    local count=0
    
    if [ -f "$leases" ]; then
        while read -r lease_time mac ip name client_id; do
            [ "$name" = "*" ] && name="Unknown"
            output="${output}<b>${MSG_DEVICE_NAME}</b> ${name}
<b>${MSG_DEVICE_IP}</b> ${ip}
<b>${MSG_DEVICE_MAC}</b> ${mac}

"
            count=$((count + 1))
        done < "$leases"
    fi
    
    local dev_list=""
    if [ "$count" -eq 0 ]; then
        dev_list="${MSG_DEVICES_NONE}
"
    else
        dev_list="$output"
    fi
    
    printf "%s

%s
<b>%s</b> %s" "$MSG_DEVICES_HEADER" "$dev_list" "$MSG_DEVICES_COUNT" "$count"
}

get_interfaces() {
    ubus call network.interface dump 2>/dev/null | jsonfilter -e '@.interface[*].interface' -e '@.interface[*].up' 2>/dev/null | awk 'ORS=NR%2?" ":"\n"'
}

toggle_interface() {
    local iface="$1"
    local action="$2" # up or down
    ubus call network.interface "$action" "{\"interface\":\"$iface\"}"
}
