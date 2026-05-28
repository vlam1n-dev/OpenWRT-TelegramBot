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
BOT_VERSION="1.0.24"
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
    
    local wan_ip=$(ubus call network.interface.wan status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
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

toggle_interface() {
    local iface="$1"
    local action="$2" # up or down
    ubus call network.interface "$action" "{\"interface\":\"$iface\"}"
}

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
        local is_auth=$(ubus call "$wlan" get_clients 2>/dev/null | jsonfilter -e "@.clients['$mac_lower'].authorized" -e "@.clients['$mac_upper'].authorized" 2>/dev/null | head -n 1)
        if [ "$is_auth" = "true" ]; then
            local dev_name="${wlan#hostapd.}"
            wlan_iface=$(ubus call iwinfo info "{\"device\":\"$dev_name\"}" 2>/dev/null | jsonfilter -e '@.ssid' 2>/dev/null)
            [ -z "$wlan_iface" ] && wlan_iface=$(iwinfo "$dev_name" info 2>/dev/null | grep "ESSID:" | sed -n 's/.*ESSID: "\([^"]*\)".*/\1/p')
            [ -z "$wlan_iface" ] && wlan_iface=$(ubus call "$wlan" get_config 2>/dev/null | jsonfilter -e '@.ssid' 2>/dev/null)
            [ -z "$wlan_iface" ] && wlan_iface="$dev_name"
            
            local rx_val=$(ubus call "$wlan" get_clients 2>/dev/null | jsonfilter -e "@.clients['$mac_lower'].rate.rx" -e "@.clients['$mac_upper'].rate.rx" 2>/dev/null | head -n 1)
            local tx_val=$(ubus call "$wlan" get_clients 2>/dev/null | jsonfilter -e "@.clients['$mac_lower'].rate.tx" -e "@.clients['$mac_upper'].rate.tx" 2>/dev/null | head -n 1)
            
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
    
    printf "🚫 <b>%s (Заблокирован)</b>\n\n<b>%s</b> %s\n" \
        "$name" \
        "$MSG_DEVICE_MAC" "$mac_str"
}

