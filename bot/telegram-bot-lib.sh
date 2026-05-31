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
BOT_VERSION="1.0.67"
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
    
    local resp_file="/tmp/telegram-bot/api_call_temp_$$.json"
    local err_file="/tmp/telegram-bot/api_call_err_$$.txt"
    
    curl -s --connect-timeout "$CURL_CONNECT_TIMEOUT" \
         --max-time "$CURL_MAX_TIME" \
         -H "Content-Type: application/json" \
         -X POST -d "$data" \
         "https://api.telegram.org/bot${API_TOKEN}/${method}" > "$resp_file" 2> "$err_file"
         
    local curl_status=$?
    
    if [ $curl_status -ne 0 ]; then
        local err_msg="curl failed with code ${curl_status} in ${method}: $(cat "$err_file" 2>/dev/null)"
        log_err "$err_msg"
        cat "$resp_file" 2>/dev/null
        rm -f "$resp_file" "$err_file"
        return $curl_status
    fi
    
    local ok=$(jsonfilter -i "$resp_file" -e '@.ok' 2>/dev/null)
    if [ "$ok" = "false" ]; then
        local desc=$(jsonfilter -i "$resp_file" -e '@.description' 2>/dev/null)
        local err_code=$(jsonfilter -i "$resp_file" -e '@.error_code' 2>/dev/null)
        log_err "Telegram API error in ${method}: [${err_code}] ${desc}"
    elif [ "$ok" != "true" ]; then
        log_err "Invalid JSON response or empty response in ${method}: $(cat "$resp_file" 2>/dev/null)"
    fi
    
    cat "$resp_file" 2>/dev/null
    rm -f "$resp_file" "$err_file"
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
        local escaped_text=$(json_escape "$text")
        payload="${payload}, \"text\": \"${escaped_text}\"" 
    fi
    if [ "$show_alert" = "true" ]; then
        payload="${payload}, \"show_alert\": true"
    fi
    payload="${payload}}"
    
    tg_api_call "answerCallbackQuery" "$payload"
}

check_admin() {
    local user_id="$1"
    # Validate user_id is numeric
    case "$user_id" in
        ''|*[!0-9-]*) return 1 ;;
    esac
    for admin in $ADMIN_IDS; do
        # Validate admin_id is numeric
        case "$admin" in
            ''|*[!0-9-]*) continue ;;
        esac
        if [ "$admin" = "$user_id" ]; then
            return 0
        fi
    done
    return 1
}

# Validate MAC address format (XX:XX:XX:XX:XX:XX)
validate_mac() {
    local mac="$1"
    echo "$mac" | grep -qiE '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'
}

# Validate interface name (alphanumeric, dots, dashes, underscores only)
validate_iface_name() {
    local name="$1"
    echo "$name" | grep -qE '^[a-zA-Z0-9._-]+$'
}

# Semantic version comparison: returns 0 if ver1 < ver2, 1 if equal, 2 if ver1 > ver2
version_compare() {
    local ver1="$1"
    local ver2="$2"
    
    # Strip leading 'v' if present
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
    elif [ "$log_type" = "error" ]; then
        log_file="/tmp/telegram-bot/error.log"
        max_lines=$(uci -q get telegram.bot.log_error_max_lines || echo 1000)
        reset_time=$(uci -q get telegram.bot.log_error_reset_time || echo 86400)
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

log_err() {
    local msg="$1"
    logger -t telegram-bot.err "$msg"
    write_to_log_file "error" "ERROR: $msg"
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

# Clean up stale rate limit files (older than 1 hour)
cleanup_rate_limits() {
    find "$BOT_DIR" -name 'rate_limits_*' -mmin +60 -delete 2>/dev/null
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
    
    # Determine WAN interface name from UCI (default: wan)
    local wan_iface=$(uci -q get network.wan.ifname 2>/dev/null)
    [ -z "$wan_iface" ] && wan_iface="wan"
    local wan_proto_iface="wan"
    # Try to get the logical interface name for WAN
    local wan_ip=$(ubus call network.interface.${wan_proto_iface} status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
    # Fallback: try all interfaces to find one with a public IP
    if [ -z "$wan_ip" ]; then
        for iface in $(ubus call network.interface dump 2>/dev/null | jsonfilter -e '@.interface[*].interface' 2>/dev/null); do
            local ip=$(ubus call network.interface."$iface" status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
            case "$ip" in
                10.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|192.168.*|127.*) continue ;;
            esac
            if [ -n "$ip" ]; then
                wan_ip="$ip"
                break
            fi
        done
    fi
    [ -z "$wan_ip" ] && wan_ip=$(wget -qO- http://checkip.amazonaws.com 2>/dev/null)
    [ -z "$wan_ip" ] && wan_ip="Unknown"
    if [ "$wan_ip" != "Unknown" ]; then
        wan_ip="<tg-spoiler>${wan_ip}</tg-spoiler>"
    fi
    
    local wifi_clients=0
    local has_hostapd=$(ubus list hostapd.* 2>/dev/null)
    if [ -n "$has_hostapd" ]; then
        for wlan in $has_hostapd; do
            local count=$(ubus call "$wlan" get_clients 2>/dev/null | jsonfilter -e '@.clients[*].authorized' 2>/dev/null | wc -l)
            wifi_clients=$((wifi_clients + count))
        done
    else
        if [ -x "/sbin/wifi" ]; then
            wifi_clients=$(iw dev | grep Interface | awk '{print $2}' | xargs -I {} iw dev {} station dump 2>/dev/null | grep Station | wc -l)
        fi
    fi
    local wifi_status="${wifi_clients} ${MSG_WIFI_CLIENTS}"
    
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
    local cpu_load="Unknown"
    # Reliable CPU measurement via /proc/stat (two samples, 1s apart)
    if [ -f /proc/stat ]; then
        local cpu1=$(head -1 /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
        local idle1=$(head -1 /proc/stat | awk '{print $5}')
        sleep 1
        local cpu2=$(head -1 /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
        local idle2=$(head -1 /proc/stat | awk '{print $5}')
        local total_diff=$((cpu2 - cpu1))
        local idle_diff=$((idle2 - idle1))
        if [ "$total_diff" -gt 0 ] 2>/dev/null; then
            cpu_load=$(( (total_diff - idle_diff) * 100 / total_diff ))
        fi
    fi
    # Fallback to load average if /proc/stat failed
    if [ "$cpu_load" = "Unknown" ]; then
        cpu_load=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
        [ -z "$cpu_load" ] && cpu_load="0"
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
<b>${MSG_DEVICE_IP}</b> <tg-spoiler>${ip}</tg-spoiler>
<b>${MSG_DEVICE_MAC}</b> <tg-spoiler>${mac}</tg-spoiler>

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

# toggle_interface() removed — dead code, interfaces are managed directly via ubus

get_iface_details() {
    local iface="$1"
    local status_json=$(ubus call network.interface."$iface" status 2>/dev/null)
    
    if [ -z "$status_json" ]; then
        echo "Interface $iface not found."
        return
    fi
    
    local up=$(echo "$status_json" | jsonfilter -e '@.up' 2>/dev/null)
    local proto=$(echo "$status_json" | jsonfilter -e '@.proto' 2>/dev/null)
    local uptime_s=$(echo "$status_json" | jsonfilter -e '@.uptime' 2>/dev/null)
    
    local device=$(echo "$status_json" | jsonfilter -e '@.l3_device' -e '@.device' 2>/dev/null | head -n 1)
    local mac=""
    [ -n "$device" ] && [ -f "/sys/class/net/${device}/address" ] && mac=$(cat "/sys/class/net/${device}/address")
    
    local ip4=$(echo "$status_json" | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
    local mask4=$(echo "$status_json" | jsonfilter -e '@["ipv4-address"][0].mask' 2>/dev/null)
    local ip6=$(echo "$status_json" | jsonfilter -e '@["ipv6-address"][0].address' 2>/dev/null)
    local mask6=$(echo "$status_json" | jsonfilter -e '@["ipv6-address"][0].mask' 2>/dev/null)
    
    local status_text="$MSG_IFACE_STATE_DOWN $MSG_IFACE_OFF"
    [ "$up" = "true" ] && status_text="$MSG_IFACE_STATE_UP $MSG_IFACE_ON"
    
    local uptime_str="-"
    if [ "$up" = "true" ] && [ -n "$uptime_s" ]; then
        local d=$((uptime_s / 86400))
        local h=$((uptime_s % 86400 / 3600))
        local m=$((uptime_s % 3600 / 60))
        local s=$((uptime_s % 60))
        uptime_str=""
        [ "$d" -gt 0 ] && uptime_str="${uptime_str}${d}d "
        [ "$h" -gt 0 ] && uptime_str="${uptime_str}${h}h "
        [ "$m" -gt 0 ] && uptime_str="${uptime_str}${m}m "
        uptime_str="${uptime_str}${s}s"
    fi
    
    [ -z "$proto" ] && proto="-"
    [ -z "$mac" ] && mac="-"
    
    local ipv4_str="-"
    [ -n "$ip4" ] && [ -n "$mask4" ] && ipv4_str="${ip4}/${mask4}"
    
    local ipv6_str="-"
    [ -n "$ip6" ] && [ -n "$mask6" ] && ipv6_str="${ip6}/${mask6}"
    
    # Apply spoilers
    [ "$mac" != "-" ] && mac="<tg-spoiler>${mac}</tg-spoiler>"
    [ "$ipv4_str" != "-" ] && ipv4_str="<tg-spoiler>${ipv4_str}</tg-spoiler>"
    [ "$ipv6_str" != "-" ] && ipv6_str="<tg-spoiler>${ipv6_str}</tg-spoiler>"
    
    printf "⚡ <b>%s</b>\n\n%s %s\n%s %s\n%s %s\n%s %s\n%s %s\n%s %s\n" \
        "$iface" \
        "$MSG_IFACE_STATUS" "$status_text" \
        "$MSG_IFACE_PROTO" "$proto" \
        "$MSG_IFACE_UPTIME" "$uptime_str" \
        "$MSG_IFACE_MAC" "$mac" \
        "$MSG_IFACE_IPV4" "$ipv4_str" \
        "$MSG_IFACE_IPV6" "$ipv6_str"
}

get_active_macs() {
    {
        for wlan in $(ubus list hostapd.* 2>/dev/null); do
            ubus call "$wlan" get_clients 2>/dev/null | grep -oE '"[0-9a-fA-F:]{17}":\s*\{' | awk -F'"' '{print $2}'
        done
        
        if [ -f /proc/net/arp ]; then
            tail -n +2 /proc/net/arp | awk '$3 == "0x2" {print $4}'
        fi
    } | tr 'A-Z' 'a-z' | sort -u
}

is_mac_blocked() {
    local mac="$1"
    local index=0
    while true; do
        local m=$(uci -q get telegram.@blocked_device[$index].mac)
        [ -z "$m" ] && return 1
        if [ "$(echo "$m" | tr 'A-Z' 'a-z')" = "$(echo "$mac" | tr 'A-Z' 'a-z')" ]; then
            return 0
        fi
        index=$((index + 1))
    done
}

block_device_mac() {
    local mac="$1"
    local name="$2"
    
    if is_mac_blocked "$mac"; then
        return 0
    fi
    
    uci add telegram blocked_device >/dev/null
    uci set telegram.@blocked_device[-1].mac="$mac"
    uci set telegram.@blocked_device[-1].name="$name"
    uci commit telegram
    
    local rule_name="block_tg_${mac//:/_}"
    uci -q delete firewall."$rule_name"
    uci set firewall."$rule_name"=rule
    uci set firewall."$rule_name".name="Block-$name"
    uci set firewall."$rule_name".src="lan"
    uci set firewall."$rule_name".src_mac="$mac"
    uci set firewall."$rule_name".target="DROP"
    uci commit firewall
    /etc/init.d/firewall reload >/dev/null 2>&1
    
    local mac_lower=$(echo "$mac" | tr 'A-Z' 'a-z')
    
    # 1. Update wireless config to block MAC on all WiFi interfaces
    local index=0
    while true; do
        local iface=$(uci -q get wireless.@wifi-iface[$index])
        [ -z "$iface" ] && break
        
        local filter=$(uci -q get wireless.@wifi-iface[$index].macfilter)
        if [ "$filter" != "allow" ]; then
            uci set wireless.@wifi-iface[$index].macfilter="deny"
            uci -q del_list wireless.@wifi-iface[$index].maclist="$mac_lower"
            uci -q del_list wireless.@wifi-iface[$index].maclist="$(echo "$mac_lower" | tr 'a-z' 'A-Z')"
            uci add_list wireless.@wifi-iface[$index].maclist="$mac_lower"
        fi
        index=$((index + 1))
    done
    uci commit wireless
    wifi reload >/dev/null 2>&1
    
    # 2. Deauth instantly via hostapd ubus calls
    for wlan in $(ubus list hostapd.* 2>/dev/null); do
        ubus call "$wlan" del_client "{\"addr\":\"$mac_lower\", \"mac\":\"$mac_lower\", \"reason\":1, \"deauth\":true, \"ban_time\":31536000000}" 2>/dev/null
    done

    if [ -f "/tmp/dhcp.leases" ]; then
        sed -i "/$mac_lower/d" /tmp/dhcp.leases
        sed -i "/$(echo "$mac_lower" | tr 'a-z' 'A-Z')/d" /tmp/dhcp.leases
        /etc/init.d/dnsmasq restart >/dev/null 2>&1
    fi
}

unblock_device_mac() {
    local mac="$1"
    
    local index=0
    while true; do
        local m=$(uci -q get telegram.@blocked_device[$index].mac)
        [ -z "$m" ] && break
        if [ "$(echo "$m" | tr 'A-Z' 'a-z')" = "$(echo "$mac" | tr 'A-Z' 'a-z')" ]; then
            uci delete telegram.@blocked_device[$index]
            break
        fi
        index=$((index + 1))
    done
    uci commit telegram
    
    local rule_name="block_tg_${mac//:/_}"
    uci -q delete firewall."$rule_name"
    uci commit firewall
    /etc/init.d/firewall reload >/dev/null 2>&1
    
    local mac_lower=$(echo "$mac" | tr 'A-Z' 'a-z')
    
    # Remove from wireless maclist
    local index=0
    while true; do
        local iface=$(uci -q get wireless.@wifi-iface[$index])
        [ -z "$iface" ] && break
        
        uci -q del_list wireless.@wifi-iface[$index].maclist="$mac_lower"
        uci -q del_list wireless.@wifi-iface[$index].maclist="$(echo "$mac_lower" | tr 'a-z' 'A-Z')"
        
        # If maclist is now empty, remove macfilter option
        local list=$(uci -q get wireless.@wifi-iface[$index].maclist)
        if [ -z "$list" ]; then
            uci -q delete wireless.@wifi-iface[$index].macfilter
        fi
        index=$((index + 1))
    done
    uci commit wireless
    wifi reload >/dev/null 2>&1
}

get_blocked_devices() {
    local index=0
    while true; do
        local mac=$(uci -q get telegram.@blocked_device[$index].mac)
        [ -z "$mac" ] && break
        local name=$(uci -q get telegram.@blocked_device[$index].name)
        [ -z "$name" ] && name="Unknown"
        echo "${mac}|${name}"
        index=$((index + 1))
    done
}

get_device_interface() {
    local target_mac="$1"
    local mac_lower=$(echo "$target_mac" | tr 'A-Z' 'a-z')
    local mac_upper=$(echo "$target_mac" | tr 'a-z' 'A-Z')
    
    for wlan in $(ubus list hostapd.* 2>/dev/null); do
        local is_auth=$(ubus call "$wlan" get_clients 2>/dev/null | jsonfilter -e "@.clients['$mac_lower'].authorized" -e "@.clients['$mac_upper'].authorized" 2>/dev/null | head -n 1)
        if [ "$is_auth" = "true" ]; then
            local dev_name="${wlan#hostapd.}"
            local ssid=$(ubus call iwinfo info "{\"device\":\"$dev_name\"}" 2>/dev/null | jsonfilter -e '@.ssid' 2>/dev/null)
            [ -z "$ssid" ] && ssid=$(iwinfo "$dev_name" info 2>/dev/null | grep "ESSID:" | sed -n 's/.*ESSID: "\([^"]*\)".*/\1/p')
            [ -z "$ssid" ] && ssid=$(ubus call "$wlan" get_config 2>/dev/null | jsonfilter -e '@.ssid' 2>/dev/null)
            [ -z "$ssid" ] && ssid="$dev_name"
            echo "$ssid"
            return
        fi
    done
    
    echo "Ethernet (LAN)"
}

get_device_name_by_mac() {
    local target_mac="$1"
    local leases="/tmp/dhcp.leases"
    
    if [ -f "$leases" ]; then
        while read -r lease_time mac ip_addr hostname client_id; do
            if [ "$(echo "$mac" | tr 'A-Z' 'a-z')" = "$(echo "$target_mac" | tr 'A-Z' 'a-z')" ]; then
                local name="$hostname"
                [ "$name" = "*" ] && name="Unknown"
                echo "$name"
                return
            fi
        done < "$leases"
    fi
    
    local index=0
    while true; do
        local m=$(uci -q get telegram.@blocked_device[$index].mac)
        [ -z "$m" ] && break
        if [ "$(echo "$m" | tr 'A-Z' 'a-z')" = "$(echo "$target_mac" | tr 'A-Z' 'a-z')" ]; then
            local name=$(uci -q get telegram.@blocked_device[$index].name)
            [ -z "$name" ] && name="Unknown"
            echo "$name"
            return
        fi
        index=$((index + 1))
    done
    
    echo "Unknown"
}

get_device_details_text() {
    local target_mac="$1"
    local leases="/tmp/dhcp.leases"
    local ip="-"
    local name="Unknown"
    local exp=0
    
    if [ -f "$leases" ]; then
        while read -r lease_time mac ip_addr hostname client_id; do
            if [ "$(echo "$mac" | tr 'A-Z' 'a-z')" = "$(echo "$target_mac" | tr 'A-Z' 'a-z')" ]; then
                ip="$ip_addr"
                name="$hostname"
                [ "$name" = "*" ] && name="Unknown"
                exp="$lease_time"
                break
            fi
        done < "$leases"
    fi
    
    local remaining="-"
    if [ "$exp" -gt 0 ]; then
        local now=$(date +%s)
        local diff=$((exp - now))
        if [ "$diff" -le 0 ]; then
            remaining="Expired"
        else
            local d=$((diff / 86400))
            local h=$((diff % 86400 / 3600))
            local m=$((diff % 3600 / 60))
            local s=$((diff % 60))
            remaining=""
            [ "$d" -gt 0 ] && remaining="${remaining}${d}d "
            [ "$h" -gt 0 ] && remaining="${remaining}${h}h "
            [ "$m" -gt 0 ] && remaining="${remaining}${m}m "
            remaining="${remaining}${s}s"
        fi
    fi
    
    local wlan_iface="Ethernet (LAN)"
    local rx_rate="-"
    local tx_rate="-"
    
    local mac_lower=$(echo "$target_mac" | tr 'A-Z' 'a-z')
    local mac_upper=$(echo "$target_mac" | tr 'a-z' 'A-Z')

    for wlan in $(ubus list hostapd.* 2>/dev/null); do
        # Cache the ubus call result to avoid redundant calls
        local clients_json=$(ubus call "$wlan" get_clients 2>/dev/null)
        local is_auth=$(echo "$clients_json" | jsonfilter -e "@.clients['$mac_lower'].authorized" -e "@.clients['$mac_upper'].authorized" 2>/dev/null | head -n 1)
        if [ "$is_auth" = "true" ]; then
            local dev_name="${wlan#hostapd.}"
            wlan_iface=$(ubus call iwinfo info "{\"device\":\"$dev_name\"}" 2>/dev/null | jsonfilter -e '@.ssid' 2>/dev/null)
            [ -z "$wlan_iface" ] && wlan_iface=$(iwinfo "$dev_name" info 2>/dev/null | grep "ESSID:" | sed -n 's/.*ESSID: "\([^"]*\)".*/\1/p')
            [ -z "$wlan_iface" ] && wlan_iface=$(echo "$clients_json" | jsonfilter -e '@.config.ssid' 2>/dev/null)
            [ -z "$wlan_iface" ] && wlan_iface="$dev_name"
            
            # Reuse cached clients_json for rate extraction
            local rx_val=$(echo "$clients_json" | jsonfilter -e "@.clients['$mac_lower'].rate.rx" -e "@.clients['$mac_upper'].rate.rx" 2>/dev/null | head -n 1)
            local tx_val=$(echo "$clients_json" | jsonfilter -e "@.clients['$mac_lower'].rate.tx" -e "@.clients['$mac_upper'].rate.tx" 2>/dev/null | head -n 1)
            
            if [ -n "$rx_val" ]; then
                if [ "$rx_val" -ge 1000000 ]; then
                    rx_rate="$((rx_val / 1000000)) Mbps"
                elif [ "$rx_val" -ge 1000 ]; then
                    rx_rate="$((rx_val / 1000)) Mbps"
                else
                    rx_rate="${rx_val} Mbps"
                fi
            fi
            if [ -n "$tx_val" ]; then
                if [ "$tx_val" -ge 1000000 ]; then
                    tx_rate="$((tx_val / 1000000)) Mbps"
                elif [ "$tx_val" -ge 1000 ]; then
                    tx_rate="$((tx_val / 1000)) Mbps"
                else
                    tx_rate="${tx_val} Mbps"
                fi
            fi
            break
        fi
    done
    
    local ip_str="$ip"
    [ "$ip_str" != "-" ] && ip_str="<tg-spoiler>${ip_str}</tg-spoiler>"
    
    local mac_str="<tg-spoiler>${target_mac}</tg-spoiler>"
    
    printf "📱 <b>%s</b>\n\n<b>%s</b> %s\n<b>%s</b> %s\n%s %s\n%s %s\n%s %s / %s\n" \
        "$name" \
        "$MSG_DEVICE_IP" "$ip_str" \
        "$MSG_DEVICE_MAC" "$mac_str" \
        "$MSG_DEV_REMAINING_LEASE" "$remaining" \
        "$MSG_DEV_WIFI_IFACE" "$wlan_iface" \
        "$MSG_DEV_RX_TX" "$rx_rate" "$tx_rate"
}

get_blocked_device_details_text() {
    local target_mac="$1"
    
    local name="Unknown"
    local index=0
    while true; do
        local m=$(uci -q get telegram.@blocked_device[$index].mac)
        [ -z "$m" ] && break
        if [ "$(echo "$m" | tr 'A-Z' 'a-z')" = "$(echo "$target_mac" | tr 'A-Z' 'a-z')" ]; then
            name=$(uci -q get telegram.@blocked_device[$index].name)
            [ -z "$name" ] && name="Unknown"
            break
        fi
        index=$((index + 1))
    done
    
    local mac_str="<tg-spoiler>${target_mac}</tg-spoiler>"
    
    printf "🚫 <b>%s (%s)</b>\n\n<b>%s</b> %s\n" \
        "$name" "$MSG_BLOCKED_STATUS" \
        "$MSG_DEVICE_MAC" "$mac_str"
}

# ── User State Management ──
set_user_state() {
    local user_id="$1"
    local state_val="$2"
    mkdir -p "/tmp/telegram-bot"
    echo "$state_val" > "/tmp/telegram-bot/state_${user_id}"
}

get_user_state() {
    local user_id="$1"
    cat "/tmp/telegram-bot/state_${user_id}" 2>/dev/null || echo ""
}

clear_user_state() {
    local user_id="$1"
    rm -f "/tmp/telegram-bot/state_${user_id}"
}

# ── Wake on Lan (WoL) ──
send_wol_packet() {
    local mac="$1"
    if command -v etherwake >/dev/null 2>&1; then
        etherwake -i br-lan "$mac"
        return 0
    elif command -v wol >/dev/null 2>&1; then
        wol -i 192.168.1.255 "$mac" >/dev/null 2>&1
        return 0
    else
        return 1
    fi
}

get_pkg_install_cmd() {
    local pkgs="$1"
    if command -v apk >/dev/null 2>&1; then
        echo "apk update && apk add ${pkgs}"
    else
        echo "opkg update && opkg install ${pkgs}"
    fi
}

# ── Traffic Statistics (vnStat & nlbwmon) ──
get_traffic_stats_vnstat() {
    local mode="$1" # "-h" (hours), "-d" (days), "-m" (months)
    if ! command -v vnstat >/dev/null 2>&1; then
        echo "ERR_VNSTAT"
        return
    fi
    
    # Get active WAN interface (as calculated in get_system_info)
    local wan_iface=$(uci -q get network.wan.ifname 2>/dev/null)
    [ -z "$wan_iface" ] && wan_iface="wan"
    local interface=$(ubus call network.interface."$wan_iface" status 2>/dev/null | jsonfilter -e '@.l3_device' 2>/dev/null)
    [ -z "$interface" ] && interface=$(vnstat --oneline | awk -F';' '{print $2}')
    [ -z "$interface" ] && interface="wan"

    # Make sure database exists for interface
    if ! vnstat -i "$interface" >/dev/null 2>&1; then
        vnstat "$mode" 2>/dev/null
    else
        vnstat -i "$interface" "$mode" 2>/dev/null
    fi
}

get_traffic_stats_nlbwmon() {
    if ! command -v nlbw >/dev/null 2>&1; then
        echo "ERR_NLBWMON"
        return
    fi
    nlbw -c csv -n 10 2>/dev/null | awk -F',' '
        function format_bytes(bytes) {
            if (bytes >= 1073741824) return sprintf("%.2f GB", bytes / 1073741824)
            if (bytes >= 1048576) return sprintf("%.2f MB", bytes / 1048576)
            if (bytes >= 1024) return sprintf("%.1f KB", bytes / 1024)
            return bytes " B"
        }
        NR == 1 {next}
        {
            ip=$1; rx=format_bytes($2); tx=format_bytes($3); total=format_bytes($4);
            # Try to resolve hostname for IP/MAC
            cmd = "grep -i " ip " /tmp/dhcp.leases 2>/dev/null | awk \x27{print $4}\x27"
            cmd | getline hostname
            close(cmd)
            if (!hostname || hostname == "*") {
                hostname = ip
            }
            if (length(hostname) > 15) {
                hostname = substr(hostname, 1, 12) "..."
            }
            printf "📱 <b>%s</b>: 📥 %s | 📤 %s (Total: %s)\n", hostname, rx, tx, total
        }
    '
}

# ── Port Forwarding (firewall redirect) ──
get_port_rules() {
    # Returns redirect rules in format: name|enabled|proto|src_dport|dest_ip|dest_port
    local index=0
    while true; do
        local name=$(uci -q get firewall.@redirect[$index].name)
        [ -z "$name" ] && break
        local enabled=$(uci -q get firewall.@redirect[$index].enabled || echo "1")
        local proto=$(uci -q get firewall.@redirect[$index].proto || echo "tcp")
        local src_dport=$(uci -q get firewall.@redirect[$index].src_dport)
        local dest_ip=$(uci -q get firewall.@redirect[$index].dest_ip)
        local dest_port=$(uci -q get firewall.@redirect[$index].dest_port)
        
        echo "${name}|${enabled}|${proto}|${src_dport}|${dest_ip}|${dest_port}"
        index=$((index + 1))
    done
}

toggle_port_rule() {
    local target_name="$1"
    local action="$2" # "1" to enable, "0" to disable
    local index=0
    while true; do
        local name=$(uci -q get firewall.@redirect[$index].name)
        [ -z "$name" ] && break
        if [ "$name" = "$target_name" ]; then
            uci set firewall.@redirect[$index].enabled="$action"
            uci commit firewall
            /etc/init.d/firewall reload >/dev/null 2>&1
            return 0
        fi
        index=$((index + 1))
    done
    return 1
}

delete_port_rule() {
    local target_name="$1"
    local index=0
    while true; do
        local name=$(uci -q get firewall.@redirect[$index].name)
        [ -z "$name" ] && break
        if [ "$name" = "$target_name" ]; then
            uci delete firewall.@redirect[$index]
            uci commit firewall
            /etc/init.d/firewall reload >/dev/null 2>&1
            return 0
        fi
        index=$((index + 1))
    done
    return 1
}

add_port_rule() {
    local name="$1"
    local proto="$2"
    local ext_port="$3"
    local int_ip="$4"
    local int_port="$5"
    
    # Check if name is already taken
    local index=0
    while true; do
        local existing_name=$(uci -q get firewall.@redirect[$index].name)
        [ -z "$existing_name" ] && break
        if [ "$existing_name" = "$name" ]; then
            # Append random suffix if name is duplicate
            name="${name}_$(hexdump -n 2 -e '/2 "%u"' /dev/urandom 2>/dev/null || echo $$)"
            break
        fi
        index=$((index + 1))
    done
    
    uci add firewall redirect >/dev/null
    uci set firewall.@redirect[-1].name="$name"
    uci set firewall.@redirect[-1].src="wan"
    uci set firewall.@redirect[-1].dest="lan"
    uci set firewall.@redirect[-1].proto="$proto"
    uci set firewall.@redirect[-1].src_dport="$ext_port"
    uci set firewall.@redirect[-1].dest_ip="$int_ip"
    uci set firewall.@redirect[-1].dest_port="$int_port"
    uci set firewall.@redirect[-1].target="DNAT"
    uci set firewall.@redirect[-1].enabled="1"
    uci commit firewall
    /etc/init.d/firewall reload >/dev/null 2>&1
    return 0
}


