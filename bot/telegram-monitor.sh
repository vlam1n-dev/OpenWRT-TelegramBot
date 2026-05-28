#!/bin/sh
# OpenWRT Telegram Bot — Monitoring & Notifications

BOT_BASE_DIR="/usr/lib/telegram-bot"
[ ! -d "$BOT_BASE_DIR" ] && BOT_BASE_DIR="$(pwd)"

if [ -f "${BOT_BASE_DIR}/telegram-bot-lib.sh" ]; then
    . "${BOT_BASE_DIR}/telegram-bot-lib.sh"
else
    exit 1
fi

load_config

# Redirect stderr to error log
ERROR_FIFO="${BOT_DIR}/stderr_mon_$$"
if mkfifo "$ERROR_FIFO" 2>/dev/null; then
    (
        while read -r line; do
            log_err "sh: $line"
        done < "$ERROR_FIFO"
    ) &
    ERROR_LOGGER_PID=$!
    exec 2> "$ERROR_FIFO"
    trap 'exec 2>&-; [ -n "$ERROR_LOGGER_PID" ] && kill "$ERROR_LOGGER_PID" 2>/dev/null; rm -f "$ERROR_FIFO"' EXIT INT TERM
fi

echo $$ > "${BOT_DIR}/monitor.pid"

[ -z "$API_TOKEN" ] || [ -z "$ADMIN_IDS" ] && exit 0

# Initialize active MACs on startup to prevent spamming notifications on reboot/restart
mkdir -p "${BOT_DIR}"
[ ! -f "/etc/telegram-known-macs" ] && touch "/etc/telegram-known-macs"
get_active_macs > "${BOT_DIR}/active_macs"
while read -r mac; do
    if [ -n "$mac" ] && ! grep -qi "^${mac}$" "/etc/telegram-known-macs"; then
        echo "$mac" >> "/etc/telegram-known-macs"
    fi
done < "${BOT_DIR}/active_macs"

send_notification() {
    local message="$1"
    for admin in $ADMIN_IDS; do
        tg_send_message "$admin" "$message" ""
    done
}

check_cpu() {
    local enabled=$(uci -q get telegram.notifications.high_cpu || echo 0)
    [ "$enabled" != "1" ] && return
    
    local threshold=$(uci -q get telegram.notifications.high_cpu_threshold || echo 90)
    local cpu_idle=$(top -n 1 | grep '^CPU:' | awk '{print $8}' | sed 's/%//')
    [ -z "$cpu_idle" ] && return
    
    local cpu_load=$((100 - cpu_idle))
    
    if [ "$cpu_load" -ge "$threshold" ]; then
        local msg=$(printf "$NOTIFY_HIGH_CPU" "$cpu_load" "$threshold")
        send_notification "$msg"
    fi
}

check_ram() {
    local enabled=$(uci -q get telegram.notifications.high_ram || echo 0)
    [ "$enabled" != "1" ] && return
    
    local threshold=$(uci -q get telegram.notifications.high_ram_threshold || echo 90)
    
    local mem=$(free -m 2>/dev/null)
    local mem_total mem_free
    if [ -z "$mem" ]; then
        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        [ -z "$mem_free" ] && mem_free=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    else
        mem_total=$(echo "$mem" | awk '/Mem:/ {print $2}')
        mem_free=$(echo "$mem" | awk '/Mem:/ {print $4}')
        # Convert to KB for consistent math
        mem_total=$((mem_total * 1024))
        mem_free=$((mem_free * 1024))
    fi
    
    local mem_used=$((mem_total - mem_free))
    local mem_pct=$(( mem_used * 100 / mem_total ))
    
    if [ "$mem_pct" -ge "$threshold" ]; then
        local msg=$(printf "$NOTIFY_HIGH_RAM" "$mem_pct" "$threshold")
        send_notification "$msg"
    fi
}

check_wan_ip() {
    local enabled=$(uci -q get telegram.notifications.wan_ip_change || echo 0)
    [ "$enabled" != "1" ] && return
    
    local wan_ip=$(ubus call network.interface.wan status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
    [ -z "$wan_ip" ] && wan_ip=$(wget -qO- http://checkip.amazonaws.com 2>/dev/null)
    [ -z "$wan_ip" ] && return
    
    local last_ip_file="${BOT_DIR}/last_wan_ip"
    local last_ip=""
    [ -f "$last_ip_file" ] && last_ip=$(cat "$last_ip_file")
    
    if [ -n "$last_ip" ] && [ "$wan_ip" != "$last_ip" ]; then
        local msg=$(printf "$NOTIFY_WAN_IP" "$last_ip" "$wan_ip")
        send_notification "$msg"
    fi
    
    echo "$wan_ip" > "$last_ip_file"
}

check_new_devices() {
    local enabled=$(uci -q get telegram.notifications.new_device || echo 0)
    [ "$enabled" != "1" ] && return
    
    local leases="/tmp/dhcp.leases"
    local known_macs_file="/etc/telegram-known-macs"
    local active_macs_file="${BOT_DIR}/active_macs"
    
    [ ! -f "$known_macs_file" ] && touch "$known_macs_file"
    [ ! -f "$active_macs_file" ] && touch "$active_macs_file"
    
    local current_active=$(get_active_macs)
    
    for mac in $current_active; do
        if ! grep -qi "^${mac}$" "$active_macs_file"; then
            # Device just connected! Wait 2 seconds for DHCP lease to complete
            sleep 2
            
            local ip="-"
            local name="Unknown"
            if [ -f "$leases" ]; then
                local lease_line=$(grep -i "$mac" "$leases" | head -n 1)
                if [ -n "$lease_line" ]; then
                    ip=$(echo "$lease_line" | awk '{print $3}')
                    name=$(echo "$lease_line" | awk '{print $4}')
                    [ "$name" = "*" ] && name="Unknown"
                fi
            fi
            
            # Fallback to static leases in UCI if not found in active leases
            if [ "$name" = "Unknown" ] || [ "$ip" = "-" ]; then
                local idx=0
                while true; do
                    local cfg_mac=$(uci -q get dhcp.@host[$idx].mac)
                    [ -z "$cfg_mac" ] && break
                    if [ "$(echo "$cfg_mac" | tr 'A-Z' 'a-z')" = "$mac" ]; then
                        local s_name=$(uci -q get dhcp.@host[$idx].name)
                        local s_ip=$(uci -q get dhcp.@host[$idx].ip)
                        [ -n "$s_name" ] && name="$s_name"
                        [ -n "$s_ip" ] && ip="$s_ip"
                        break
                    fi
                    idx=$((idx + 1))
                done
            fi
            
            local dev_iface=$(get_device_interface "$mac")
            
            local status_msg=""
            if grep -qi "^${mac}$" "$known_macs_file"; then
                status_msg="$MSG_DEV_STATUS_KNOWN"
            else
                status_msg="$MSG_DEV_STATUS_NEW"
                echo "$mac" >> "$known_macs_file"
            fi
            
            local msg=$(printf "$NOTIFY_NEW_DEVICE" "$status_msg" "$name" "$dev_iface" "$ip" "$mac")
            send_notification "$msg"
        fi
    done
    
    echo "$current_active" > "$active_macs_file"
}

check_updates() {
    local enabled=$(uci -q get telegram.notifications.update_available || echo 0)
    [ "$enabled" != "1" ] && return
    
    local last_check_file="${BOT_DIR}/last_update_check"
    local now=$(date +%s)
    local interval=$(uci -q get telegram.bot.check_updates_interval || echo 86400)
    
    if [ -f "$last_check_file" ]; then
        local last_check=$(cat "$last_check_file")
        if [ "$((now - last_check))" -lt "$interval" ]; then
            return
        fi
    fi
    
    local repo="$GITHUB_REPO"
    [ -z "$repo" ] && return
    
    local url="https://api.github.com/repos/${repo}/releases/latest"
    local resp=$(curl -s --connect-timeout 10 --max-time 30 -H "Accept: application/vnd.github.v3+json" "$url")
    local latest=$(echo "$resp" | jsonfilter -e '@.tag_name' 2>/dev/null | sed 's/^v//')
    
    [ -z "$latest" ] && return
    
    local current="1.0.24"
    [ -f "${BOT_BASE_DIR}/VERSION" ] && current=$(cat "${BOT_BASE_DIR}/VERSION")
    
    if [ "$latest" != "$current" ]; then
        # Use simple string compare or assume latest is newer if not equal
        local msg=$(printf "$NOTIFY_UPDATE" "$current" "$latest" "$repo")
        send_notification "$msg"
    fi
    
    echo "$now" > "$last_check_file"
}

# Run all checks in a loop for procd
last_slow_check=0
slow_interval=60

while true; do
    # Fast checks (every 10 seconds)
    check_new_devices
    
    # Slow checks (every 60 seconds)
    now=$(date +%s)
    if [ "$((now - last_slow_check))" -ge "$slow_interval" ]; then
        check_cpu
        check_ram
        check_wan_ip
        check_updates
        last_slow_check=$now
    fi
    
    sleep 10
done
