#!/bin/sh
# OpenWRT Telegram Bot — Main Loop
# shellcheck disable=SC2154

BOT_BASE_DIR="/usr/lib/telegram-bot"
[ ! -d "$BOT_BASE_DIR" ] && BOT_BASE_DIR="$(pwd)"

if [ -f "${BOT_BASE_DIR}/telegram-bot-lib.sh" ]; then
    . "${BOT_BASE_DIR}/telegram-bot-lib.sh"
else
    echo "Error: telegram-bot-lib.sh not found!"
    exit 1
fi

load_config

cleanup() {
    exec 2>&-
    [ -n "$ERROR_LOGGER_PID" ] && kill "$ERROR_LOGGER_PID" 2>/dev/null
    [ -n "$ERROR_FIFO" ] && rm -f "$ERROR_FIFO"
    rm -f "$PID_FILE"
}
trap cleanup EXIT
trap 'exit 1' INT TERM

# Redirect stderr to error log
ERROR_FIFO="${BOT_DIR}/stderr_bot_$$"
if mkfifo "$ERROR_FIFO" 2>/dev/null; then
    (
        while read -r line; do
            log_err "sh: $line"
        done < "$ERROR_FIFO"
    ) &
    ERROR_LOGGER_PID=$!
    exec 2> "$ERROR_FIFO"
fi

if [ -z "$API_TOKEN" ]; then
    log_error "Bot token not configured! Exiting."
    exit 1
fi

echo $$ > "$PID_FILE"
log_info "Bot started, PID=$$"

get_main_keyboard() {
    echo "[[{\"text\":\"${BTN_RESTART}\",\"callback_data\":\"btn_reboot\"},{\"text\":\"${BTN_INTERFACES}\",\"callback_data\":\"btn_ifaces\"}], [{\"text\":\"${BTN_STATS}\",\"callback_data\":\"btn_stats\"},{\"text\":\"${BTN_DEVICES}\",\"callback_data\":\"btn_devices\"}], [{\"text\":\"${BTN_DIAG}\",\"callback_data\":\"btn_diag\"},{\"text\":\"${BTN_PORTS}\",\"callback_data\":\"btn_ports\"}], [{\"text\":\"${BTN_SETTINGS}\",\"callback_data\":\"btn_settings\"},{\"text\":\"${BTN_ABOUT}\",\"callback_data\":\"btn_about\"}], [{\"text\":\"${BTN_REFRESH}\",\"callback_data\":\"btn_refresh\"}]]"
}

get_diag_keyboard() {
    echo "[[{\"text\":\"Ping\",\"callback_data\":\"diag_ping\"},{\"text\":\"Traceroute\",\"callback_data\":\"diag_traceroute\"}], [{\"text\":\"DNS Lookup\",\"callback_data\":\"diag_dns\"},{\"text\":\"Port Check\",\"callback_data\":\"diag_port\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
}

get_ifaces_keyboard() {
    local tmp_file="${BOT_DIR}/ifaces_raw.txt"
    ubus call network.interface dump 2>/dev/null | jsonfilter -e '@.interface[*].interface' 2>/dev/null > "$tmp_file"
    
    local kb="["
    local first=1
    
    if [ -f "$tmp_file" ]; then
        while read -r iface; do
            [ -z "$iface" ] && continue
            [ "$iface" = "loopback" ] && continue
            
            # Get up status locally
            local status_json=$(ubus call network.interface."$iface" status 2>/dev/null)
            local up=$(echo "$status_json" | jsonfilter -e '@.up' 2>/dev/null)
            
            local btn_text="$iface"
            if [ "$up" = "true" ]; then
                btn_text="${btn_text} ${MSG_IFACE_ON}"
            else
                btn_text="${btn_text} ${MSG_IFACE_OFF}"
            fi
            
            local action="if_view_${iface}"
            
            if [ "$first" -eq 1 ]; then
                kb="${kb}[{\"text\":\"${btn_text}\",\"callback_data\":\"${action}\"}]"
                first=0
            else
                kb="${kb},[{\"text\":\"${btn_text}\",\"callback_data\":\"${action}\"}]"
            fi
        done < "$tmp_file"
        rm -f "$tmp_file"
    fi
    
    if [ "$first" -eq 1 ]; then
        kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    else
        kb="${kb},[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    fi
    echo "$kb"
}

get_iface_details_keyboard() {
    local iface="$1"
    local status_json=$(ubus call network.interface."$iface" status 2>/dev/null)
    local up=$(echo "$status_json" | jsonfilter -e '@.up' 2>/dev/null)
    
    local btn_toggle=""
    if [ "$up" = "true" ]; then
        btn_toggle="{\"text\":\"${BTN_IFACE_DOWN}\",\"callback_data\":\"if_action_down_${iface}\"}"
    else
        btn_toggle="{\"text\":\"${BTN_IFACE_UP}\",\"callback_data\":\"if_action_up_${iface}\"}"
    fi
    
    echo "[[${btn_toggle}], [{\"text\":\"${BTN_IFACE_RESTART}\",\"callback_data\":\"if_action_restart_${iface}\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_ifaces\"}]]"
}

get_devices_keyboard() {
    local leases="/tmp/dhcp.leases"
    local kb="["
    local first=1
    
    if [ -f "$leases" ]; then
        local sorted_leases="${BOT_DIR}/sorted_leases"
        sort -rn "$leases" > "$sorted_leases" 2>/dev/null
        while read -r lease_time mac ip name client_id; do
            [ -z "$mac" ] && continue
            [ "$name" = "*" ] && name="Unknown"
            
            local display_name="$name"
            if [ ${#display_name} -gt 20 ]; then
                display_name="$(echo "$display_name" | cut -c 1-17)..."
            fi
            
            if [ "$first" -eq 1 ]; then
                kb="${kb}[{\"text\":\"${display_name}\",\"callback_data\":\"dev_view_${mac}\"}]"
                first=0
            else
                kb="${kb},[{\"text\":\"${display_name}\",\"callback_data\":\"dev_view_${mac}\"}]"
            fi
        done < "$sorted_leases"
        rm -f "$sorted_leases"
    fi
    
    if [ "$first" -eq 1 ]; then
        kb="[[{\"text\":\"${BTN_BLOCKED_DEVICES}\",\"callback_data\":\"dev_blocked_list\"}], [{\"text\":\"${BTN_REFRESH}\",\"callback_data\":\"btn_devices_refresh\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    else
        kb="${kb},[{\"text\":\"${BTN_BLOCKED_DEVICES}\",\"callback_data\":\"dev_blocked_list\"}], [{\"text\":\"${BTN_REFRESH}\",\"callback_data\":\"btn_devices_refresh\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    fi
    echo "$kb"
}

get_blocked_devices_keyboard() {
    local kb="["
    local first=1
    
    local list=$(get_blocked_devices)
    local old_ifs="$IFS"
    IFS=$'\n'
    for line in $list; do
        IFS="$old_ifs"
        [ -z "$line" ] && continue
        local mac="${line%%|*}"
        local name="${line##*|}"
        [ -z "$mac" ] && continue
        
        local display_name="$name"
        if [ ${#display_name} -gt 20 ]; then
            display_name="$(echo "$display_name" | cut -c 1-17)..."
        fi
        
        if [ "$first" -eq 1 ]; then
            kb="${kb}[{\"text\":\"${display_name}\",\"callback_data\":\"dev_blocked_view_${mac}\"}]"
            first=0
        else
            kb="${kb},[{\"text\":\"${display_name}\",\"callback_data\":\"dev_blocked_view_${mac}\"}]"
        fi
        IFS=$'\n'
    done
    IFS="$old_ifs"
    
    if [ "$first" -eq 1 ]; then
        kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_devices\"}]]"
    else
        kb="${kb},[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_devices\"}]]"
    fi
    echo "$kb"
}

get_device_details_keyboard() {
    local mac="$1"
    echo "[[{\"text\":\"${BTN_REFRESH}\",\"callback_data\":\"dev_refresh_${mac}\"}], [{\"text\":\"${BTN_KICK}\",\"callback_data\":\"dev_action_kick_${mac}\"},{\"text\":\"${BTN_BLOCK}\",\"callback_data\":\"dev_action_block_${mac}\"}], [{\"text\":\"${BTN_WOL}\",\"callback_data\":\"dev_wol_${mac}\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_devices\"}]]"
}

get_traffic_keyboard() {
    echo "[[{\"text\":\"${BTN_REFRESH}\",\"callback_data\":\"btn_stats_refresh\"}], [{\"text\":\"${BTN_TRAFFIC_HOUR}\",\"callback_data\":\"btn_traffic_hour\"},{\"text\":\"${BTN_TRAFFIC_DAY}\",\"callback_data\":\"btn_traffic_day\"}], [{\"text\":\"${BTN_TRAFFIC_MONTH}\",\"callback_data\":\"btn_traffic_month\"},{\"text\":\"${BTN_TRAFFIC_DEVICE}\",\"callback_data\":\"btn_traffic_device\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
}

get_ports_keyboard() {
    local kb="["
    local first=1
    local list=$(get_port_rules)
    local old_ifs="$IFS"
    IFS=$'\n'
    for line in $list; do
        IFS="$old_ifs"
        [ -z "$line" ] && continue
        local name="${line%%|*}"
        [ -z "$name" ] && continue
        
        # Parse enabled status
        local temp="${line#*|}"
        local enabled="${temp%%|*}"
        
        local btn_text="$name"
        if [ "$enabled" = "1" ]; then
            btn_text="${btn_text} ✅"
        else
            btn_text="${btn_text} ❌"
        fi
        
        if [ "$first" -eq 1 ]; then
            kb="${kb}[{\"text\":\"${btn_text}\",\"callback_data\":\"port_view_${name}\"}]"
            first=0
        else
            kb="${kb},[{\"text\":\"${btn_text}\",\"callback_data\":\"port_view_${name}\"}]"
        fi
        IFS=$'\n'
    done
    IFS="$old_ifs"
    
    if [ "$first" -eq 1 ]; then
        kb="[[{\"text\":\"${BTN_PORT_ADD}\",\"callback_data\":\"port_add\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    else
        kb="${kb},[{\"text\":\"${BTN_PORT_ADD}\",\"callback_data\":\"port_add\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
    fi
    echo "$kb"
}

get_port_details_keyboard() {
    local name="$1"
    local enabled="$2"
    local btn_toggle=""
    if [ "$enabled" = "1" ]; then
        btn_toggle="{\"text\":\"🔴 Выключить\",\"callback_data\":\"port_toggle_${name}_0\"}"
    else
        btn_toggle="{\"text\":\"🟢 Включить\",\"callback_data\":\"port_toggle_${name}_1\"}"
    fi
    
    echo "[[${btn_toggle}], [{\"text\":\"🗑 Удалить\",\"callback_data\":\"port_delete_${name}\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_ports\"}]]"
}

get_port_proto_keyboard() {
    echo "[[{\"text\":\"${BTN_PORT_PROTO_TCP}\",\"callback_data\":\"port_add_proto_tcp\"},{\"text\":\"${BTN_PORT_PROTO_UDP}\",\"callback_data\":\"port_add_proto_udp\"}], [{\"text\":\"${BTN_PORT_PROTO_ALL}\",\"callback_data\":\"port_add_proto_all\"}]]"
}

get_blocked_device_details_keyboard() {
    local mac="$1"
    echo "[[{\"text\":\"${BTN_UNBLOCK}\",\"callback_data\":\"dev_action_unblock_${mac}\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"dev_blocked_list\"}]]"
}

get_settings_keyboard() {
    echo "[[{\"text\":\"${BTN_NOTIFICATIONS}\",\"callback_data\":\"btn_notify\"},{\"text\":\"${BTN_LANGUAGE}\",\"callback_data\":\"btn_lang\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
}

get_lang_keyboard() {
    echo "[[{\"text\":\"${BTN_LANG_EN}\",\"callback_data\":\"lang_en\"},{\"text\":\"${BTN_LANG_RU}\",\"callback_data\":\"lang_ru\"}], [{\"text\":\"${BTN_LANG_UK}\",\"callback_data\":\"lang_uk\"},{\"text\":\"${BTN_LANG_DE}\",\"callback_data\":\"lang_de\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_settings\"}]]"
}

get_notify_keyboard() {
    local kb="["
    local n_newdev=$(uci -q get telegram.notifications.new_device || echo 0)
    local n_wanip=$(uci -q get telegram.notifications.wan_ip_change || echo 0)
    local n_cpu=$(uci -q get telegram.notifications.high_cpu || echo 0)
    local n_ram=$(uci -q get telegram.notifications.high_ram || echo 0)
    local n_upd=$(uci -q get telegram.notifications.update_available || echo 0)
    
    local c_newdev="${BTN_NOTIFY_NEWDEV} $( [ "$n_newdev" = "1" ] && echo "$MSG_NOTIFY_ENABLED" || echo "$MSG_NOTIFY_DISABLED" )"
    local c_wanip="${BTN_NOTIFY_WANIP} $( [ "$n_wanip" = "1" ] && echo "$MSG_NOTIFY_ENABLED" || echo "$MSG_NOTIFY_DISABLED" )"
    local c_cpu="${BTN_NOTIFY_CPU} $( [ "$n_cpu" = "1" ] && echo "$MSG_NOTIFY_ENABLED" || echo "$MSG_NOTIFY_DISABLED" )"
    local c_ram="${BTN_NOTIFY_RAM} $( [ "$n_ram" = "1" ] && echo "$MSG_NOTIFY_ENABLED" || echo "$MSG_NOTIFY_DISABLED" )"
    local c_upd="${BTN_NOTIFY_UPD} $( [ "$n_upd" = "1" ] && echo "$MSG_NOTIFY_ENABLED" || echo "$MSG_NOTIFY_DISABLED" )"
    
    kb="${kb}[{\"text\":\"${c_newdev}\",\"callback_data\":\"notif_newdev\"}],"
    kb="${kb}[{\"text\":\"${c_wanip}\",\"callback_data\":\"notif_wanip\"}],"
    kb="${kb}[{\"text\":\"${c_cpu}\",\"callback_data\":\"notif_cpu\"}],"
    kb="${kb}[{\"text\":\"${c_ram}\",\"callback_data\":\"notif_ram\"}],"
    kb="${kb}[{\"text\":\"${c_upd}\",\"callback_data\":\"notif_upd\"}],"
    kb="${kb}[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_settings\"}]]"
    echo "$kb"
}

process_message() {
    local chat_id="$1"
    local user_id="$2"
    local username="$3"
    local text="$4"
    
    if ! check_admin "$user_id"; then
        log_unauthorized "$user_id" "$username" "$chat_id" "$text"
        local denied_msg=$(printf "$MSG_ACCESS_DENIED" "$user_id")
        tg_send_message "$chat_id" "$denied_msg" ""
        return
    fi
    
    if ! check_rate_limit "$user_id"; then
        tg_send_message "$chat_id" "$MSG_RATE_LIMITED" ""
        return
    fi
    
    # Handle cancellation
    if [ "$text" = "/cancel" ]; then
        clear_user_state "$user_id"
        tg_send_message "$chat_id" "$MSG_CANCEL_MSG" "$(get_main_keyboard)"
        return
    fi
    
    # Reset state on /start
    if [ "$text" = "/start" ]; then
        clear_user_state "$user_id"
    fi

    # Read user state
    local state=$(get_user_state "$user_id")
    if [ -n "$state" ]; then
        # ─── Diagnostics Handling ───
        if [ "$state" = "diag_ping" ] || [ "$state" = "diag_traceroute" ] || [ "$state" = "diag_dns" ] || [ "$state" = "diag_port" ]; then
            # Validate input to prevent command injection
            # Only allow alphanumeric, dots, dashes, colons, underscores
            if ! echo "$text" | grep -qE '^[a-zA-Z0-9._-]+(:[0-9]+)?$'; then
                tg_send_message "$chat_id" "$MSG_DIAG_INVALID_INPUT" "$(get_diag_keyboard)"
                clear_user_state "$user_id"
                return
            fi
            
            local run_msg_resp=$(tg_send_message "$chat_id" "$MSG_DIAG_RUNNING" "")
            local run_msg_id=$(echo "$run_msg_resp" | jsonfilter -e '@.result.message_id' 2>/dev/null)
            local result=""
            
            if [ "$state" = "diag_ping" ]; then
                result=$(ping -w 5 -c 4 "$text" 2>&1)
            elif [ "$state" = "diag_traceroute" ]; then
                result=$(traceroute -q 1 -w 2 -m 15 "$text" 2>&1)
            elif [ "$state" = "diag_dns" ]; then
                result=$(nslookup "$text" 2>&1)
            elif [ "$state" = "diag_port" ]; then
                local host="${text%%:*}"
                local port="${text##*:}"
                if [ "$host" = "$text" ] || [ -z "$port" ] || ! echo "$port" | grep -qE '^[0-9]+$'; then
                    if [ -n "$run_msg_id" ]; then
                        tg_edit_message_text "$chat_id" "$run_msg_id" "$MSG_DIAG_INVALID_INPUT" "$(get_diag_keyboard)"
                    else
                        tg_send_message "$chat_id" "$MSG_DIAG_INVALID_INPUT" "$(get_diag_keyboard)"
                    fi
                    clear_user_state "$user_id"
                    return
                fi
                result=$(nc -w 3 -z "$host" "$port" 2>&1)
                if [ $? -eq 0 ]; then
                    result="Connection to ${host} ${port} port [tcp/*] succeeded!"
                else
                    result="Connection to ${host} ${port} port [tcp/*] failed: Connection timed out"
                fi
            fi
            
            # Format and edit/send result
            local formatted_res=$(printf "$MSG_DIAG_RESULT" "$result")
            if [ -n "$run_msg_id" ]; then
                tg_edit_message_text "$chat_id" "$run_msg_id" "$formatted_res" "$(get_diag_keyboard)"
            else
                tg_send_message "$chat_id" "$formatted_res" "$(get_diag_keyboard)"
            fi
            clear_user_state "$user_id"
            return
        
        # ─── Port Forwarding Wizard Handling ───
        elif echo "$state" | grep -q "^port_add_"; then
            local step="${state%%|*}"
            
            if [ "$step" = "port_add_name" ]; then
                # Validate rule name (letters, numbers, dash, underscore, space allowed, max 25 chars)
                if [ ${#text} -gt 25 ] || ! echo "$text" | grep -qE '^[a-zA-Z0-9_ -]+$'; then
                    tg_send_message "$chat_id" "$MSG_DIAG_INVALID_INPUT" ""
                    return
                fi
                set_user_state "$user_id" "port_add_ext|name=${text}"
                tg_send_message "$chat_id" "$MSG_PORT_ADD_EXT" ""
                return
                
            elif [ "$step" = "port_add_ext" ]; then
                local name="${state#*name=}"
                name="${name%%|*}"
                # Validate port (1-65535)
                if ! echo "$text" | grep -qE '^[0-9]+$' || [ "$text" -lt 1 ] 2>/dev/null || [ "$text" -gt 65535 ] 2>/dev/null; then
                    tg_send_message "$chat_id" "$MSG_PORT_INVALID_PORT" ""
                    return
                fi
                set_user_state "$user_id" "port_add_ip|name=${name}|ext=${text}"
                tg_send_message "$chat_id" "$MSG_PORT_ADD_IP" ""
                return
                
            elif [ "$step" = "port_add_ip" ]; then
                local name="${state#*name=}"
                name="${name%%|*}"
                local ext="${state#*ext=}"
                ext="${ext%%|*}"
                # Validate local IP address format
                if ! echo "$text" | grep -qE '^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$' && ! echo "$text" | grep -qE '^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' && ! echo "$text" | grep -qE '^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                    tg_send_message "$chat_id" "$MSG_PORT_INVALID_IP" ""
                    return
                fi
                set_user_state "$user_id" "port_add_int|name=${name}|ext=${ext}|ip=${text}"
                tg_send_message "$chat_id" "$MSG_PORT_ADD_INT" ""
                return
                
            elif [ "$step" = "port_add_int" ]; then
                local name="${state#*name=}"
                name="${name%%|*}"
                local ext="${state#*ext=}"
                ext="${ext%%|*}"
                local ip="${state#*ip=}"
                ip="${ip%%|*}"
                # Validate port (1-65535)
                if ! echo "$text" | grep -qE '^[0-9]+$' || [ "$text" -lt 1 ] 2>/dev/null || [ "$text" -gt 65535 ] 2>/dev/null; then
                    tg_send_message "$chat_id" "$MSG_PORT_INVALID_PORT" ""
                    return
                fi
                set_user_state "$user_id" "port_add_proto|name=${name}|ext=${ext}|ip=${ip}|int=${text}"
                tg_send_message "$chat_id" "$MSG_PORT_ADD_PROTO" "$(get_port_proto_keyboard)"
                return
            fi
        fi
    fi
    
    case "$text" in
        /start)
            local info=$(get_system_info)
            local kb=$(get_main_keyboard)
            tg_send_message "$chat_id" "$info" "$kb"
            ;;
        *)
            tg_send_message "$chat_id" "$MSG_UNKNOWN_CMD" ""
            ;;
    esac
}

process_callback() {
    local cb_id="$1"
    local chat_id="$2"
    local msg_id="$3"
    local data="$4"
    local user_id="$5"
    local username="$6"
    
    if ! check_admin "$user_id"; then
        log_unauthorized "$user_id" "$username" "$chat_id" "$data"
        tg_answer_callback "$cb_id" "Access Denied" "true"
        return
    fi
    
    if ! check_rate_limit "$user_id"; then
        tg_answer_callback "$cb_id" "$MSG_RATE_LIMITED" "true"
        return
    fi
    
    case "$data" in
        btn_main)
            local info=$(get_system_info)
            local kb=$(get_main_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$info" "$kb" >/dev/null
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_refresh)
            local info=$(get_system_info)
            local kb=$(get_main_keyboard)
            local resp=$(tg_edit_message_text "$chat_id" "$msg_id" "$info" "$kb")
            local ok=$(echo "$resp" | jsonfilter -e '@.ok' 2>/dev/null)
            local desc=$(echo "$resp" | jsonfilter -e '@.description' 2>/dev/null)
            if [ "$ok" = "true" ] || echo "$desc" | grep -qi "not modified"; then
                tg_answer_callback "$cb_id" "$MSG_REFRESH_SUCCESS" "false"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "false"
            fi
            ;;
        btn_reboot)
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"do_reboot\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"btn_main\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_REBOOT_CONFIRM" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        do_reboot)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_REBOOT_OK" ""
            tg_answer_callback "$cb_id" "Rebooting..." "false"
            log_info "Reboot initiated by user $user_id"
            sleep 2
            reboot
            ;;
        btn_stats)
            local stats=$(get_system_stats)
            local kb=$(get_traffic_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$stats" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_stats_refresh)
            local stats=$(get_system_stats)
            local kb=$(get_traffic_keyboard)
            local resp=$(tg_edit_message_text "$chat_id" "$msg_id" "$stats" "$kb")
            local ok=$(echo "$resp" | jsonfilter -e '@.ok' 2>/dev/null)
            local desc=$(echo "$resp" | jsonfilter -e '@.description' 2>/dev/null)
            if [ "$ok" = "true" ] || echo "$desc" | grep -qi "not modified"; then
                tg_answer_callback "$cb_id" "$MSG_REFRESH_SUCCESS" "false"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "false"
            fi
            ;;
        btn_traffic_hour)
            local res=$(get_traffic_stats_vnstat "-h")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_stats\"}]]"
            if [ "$res" = "ERR_VNSTAT" ]; then
                local cmd=$(get_pkg_install_cmd "vnstatd vnstat")
                local msg=$(printf "$MSG_TRAFFIC_ERR_VNSTAT" "$cmd")
                tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            else
                tg_edit_message_text "$chat_id" "$msg_id" "${MSG_TRAFFIC_HOUR_TITLE}${res}" "$kb"
            fi
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_traffic_day)
            local res=$(get_traffic_stats_vnstat "-d")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_stats\"}]]"
            if [ "$res" = "ERR_VNSTAT" ]; then
                local cmd=$(get_pkg_install_cmd "vnstatd vnstat")
                local msg=$(printf "$MSG_TRAFFIC_ERR_VNSTAT" "$cmd")
                tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            else
                tg_edit_message_text "$chat_id" "$msg_id" "${MSG_TRAFFIC_DAY_TITLE}${res}" "$kb"
            fi
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_traffic_month)
            local res=$(get_traffic_stats_vnstat "-m")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_stats\"}]]"
            if [ "$res" = "ERR_VNSTAT" ]; then
                local cmd=$(get_pkg_install_cmd "vnstatd vnstat")
                local msg=$(printf "$MSG_TRAFFIC_ERR_VNSTAT" "$cmd")
                tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            else
                tg_edit_message_text "$chat_id" "$msg_id" "${MSG_TRAFFIC_MONTH_TITLE}${res}" "$kb"
            fi
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_traffic_device)
            local res=$(get_traffic_stats_nlbwmon)
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_stats\"}]]"
            if [ "$res" = "ERR_NLBWMON" ]; then
                local cmd=$(get_pkg_install_cmd "nlbwmon")
                local msg=$(printf "$MSG_TRAFFIC_ERR_NLBWMON" "$cmd")
                tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            elif [ -z "$res" ]; then
                tg_edit_message_text "$chat_id" "$msg_id" "${MSG_TRAFFIC_DEVICE_TITLE}Пока нет данных о трафике по устройствам." "$kb"
            else
                tg_edit_message_text "$chat_id" "$msg_id" "${MSG_TRAFFIC_DEVICE_TITLE}${res}" "$kb"
            fi
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_devices)
            local kb=$(get_devices_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DEVICES_HEADER" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_devices_refresh)
            local kb=$(get_devices_keyboard)
            local resp=$(tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DEVICES_HEADER" "$kb")
            local ok=$(echo "$resp" | jsonfilter -e '@.ok' 2>/dev/null)
            local desc=$(echo "$resp" | jsonfilter -e '@.description' 2>/dev/null)
            if [ "$ok" = "true" ] || echo "$desc" | grep -qi "not modified"; then
                tg_answer_callback "$cb_id" "$MSG_REFRESH_SUCCESS" "false"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "false"
            fi
            ;;
        dev_blocked_list)
            local kb=$(get_blocked_devices_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_BLOCKED_DEVICES_HEADER" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_view_*)
            local mac="${data#dev_view_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local msg=$(get_device_details_text "$mac")
            local kb=$(get_device_details_keyboard "$mac")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_refresh_*)
            local mac="${data#dev_refresh_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local msg=$(get_device_details_text "$mac")
            local kb=$(get_device_details_keyboard "$mac")
            local resp=$(tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb")
            local ok=$(echo "$resp" | jsonfilter -e '@.ok' 2>/dev/null)
            local desc=$(echo "$resp" | jsonfilter -e '@.description' 2>/dev/null)
            if [ "$ok" = "true" ] || echo "$desc" | grep -qi "not modified"; then
                tg_answer_callback "$cb_id" "$MSG_REFRESH_SUCCESS" "false"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "false"
            fi
            ;;
        dev_blocked_view_*)
            local mac="${data#dev_blocked_view_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local msg=$(get_blocked_device_details_text "$mac")
            local kb=$(get_blocked_device_details_keyboard "$mac")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_action_kick_*)
            local mac="${data#dev_action_kick_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            local msg=$(printf "$MSG_DEV_CONFIRM_KICK" "$name")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"dev_do_kick_${mac}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"dev_view_${mac}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_action_block_*)
            local mac="${data#dev_action_block_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            local msg=$(printf "$MSG_DEV_CONFIRM_BLOCK" "$name")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"dev_do_block_${mac}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"dev_view_${mac}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_action_unblock_*)
            local mac="${data#dev_action_unblock_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            local msg=$(printf "$MSG_DEV_CONFIRM_UNBLOCK" "$name")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"dev_do_unblock_${mac}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"dev_blocked_view_${mac}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_wol_*)
            local mac="${data#dev_wol_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            local msg=$(printf "$MSG_WOL_CONFIRM" "$name")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"dev_do_wol_${mac}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"dev_view_${mac}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        dev_do_wol_*)
            local mac="${data#dev_do_wol_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            if send_wol_packet "$mac"; then
                local msg=$(printf "$MSG_WOL_SENT" "$name")
                tg_answer_callback "$cb_id" "$msg" "true"
            else
                tg_answer_callback "$cb_id" "$MSG_WOL_ERROR" "true"
            fi
            # Return to device view
            local msg_text=$(get_device_details_text "$mac")
            local kb=$(get_device_details_keyboard "$mac")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg_text" "$kb"
            ;;
        dev_do_kick_*)
            local mac="${data#dev_do_kick_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            local mac_lower=$(echo "$mac" | tr 'A-Z' 'a-z')
            for wlan in $(ubus list hostapd.* 2>/dev/null); do
                ubus call "$wlan" del_client "{\"addr\":\"$mac_lower\", \"mac\":\"$mac_lower\", \"reason\":1, \"deauth\":true, \"ban_time\":60000}" 2>/dev/null
            done
            if [ -f "/tmp/dhcp.leases" ]; then
                sed -i "/$mac_lower/d" /tmp/dhcp.leases
                sed -i "/$(echo "$mac_lower" | tr 'a-z' 'A-Z')/d" /tmp/dhcp.leases
                /etc/init.d/dnsmasq restart >/dev/null 2>&1
            fi
            local msg=$(printf "$MSG_DEV_KICKED" "$name")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_devices\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "$MSG_DEV_KICK_RESP" "false"
            ;;
        dev_do_block_*)
            local mac="${data#dev_do_block_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            block_device_mac "$mac" "$name"
            local msg=$(printf "$MSG_DEV_BLOCKED" "$name")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_devices\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "$MSG_DEV_BLOCK_RESP" "false"
            ;;
        dev_do_unblock_*)
            local mac="${data#dev_do_unblock_}"
            if ! validate_mac "$mac"; then
                tg_answer_callback "$cb_id" "Invalid MAC" "true"
                return
            fi
            local name=$(get_device_name_by_mac "$mac")
            unblock_device_mac "$mac"
            local msg=$(printf "$MSG_DEV_UNBLOCKED" "$name")
            local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"dev_blocked_list\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "$MSG_DEV_UNBLOCKED_RESP" "false"
            ;;
        btn_ifaces)
            local kb=$(get_ifaces_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_IFACES_HEADER" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        if_view_*)
            local iface="${data#if_view_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            local msg=$(get_iface_details "$iface")
            local kb=$(get_iface_details_keyboard "$iface")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        if_action_up_*)
            local iface="${data#if_action_up_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            local msg=$(printf "$MSG_IFACE_CONFIRM_UP" "$iface")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"if_do_up_${iface}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"if_view_${iface}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        if_action_down_*)
            local iface="${data#if_action_down_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            local msg=$(printf "$MSG_IFACE_CONFIRM_DOWN" "$iface")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"if_do_down_${iface}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"if_view_${iface}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        if_action_restart_*)
            local iface="${data#if_action_restart_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            local msg=$(printf "$MSG_IFACE_CONFIRM_REBOOT" "$iface")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"if_do_restart_${iface}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"if_view_${iface}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        if_do_up_*)
            local iface="${data#if_do_up_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            ubus call network.interface."$iface" up 2>/dev/null
            tg_answer_callback "$cb_id" "Interface $iface enabling..." "false"
            sleep 1
            local msg=$(get_iface_details "$iface")
            local kb=$(get_iface_details_keyboard "$iface")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            ;;
        if_do_down_*)
            local iface="${data#if_do_down_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            ubus call network.interface."$iface" down 2>/dev/null
            tg_answer_callback "$cb_id" "Interface $iface disabling..." "false"
            sleep 1
            local msg=$(get_iface_details "$iface")
            local kb=$(get_iface_details_keyboard "$iface")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            ;;
        if_do_restart_*)
            local iface="${data#if_do_restart_}"
            if ! validate_iface_name "$iface"; then
                tg_answer_callback "$cb_id" "Invalid interface" "true"
                return
            fi
            ubus call network.interface."$iface" down 2>/dev/null
            sleep 1
            ubus call network.interface."$iface" up 2>/dev/null
            tg_answer_callback "$cb_id" "Interface $iface restarting..." "false"
            sleep 1
            local msg=$(get_iface_details "$iface")
            local kb=$(get_iface_details_keyboard "$iface")
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            ;;
        btn_diag)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DIAG_HEADER" "$(get_diag_keyboard)"
            tg_answer_callback "$cb_id" "" "false"
            clear_user_state "$user_id"
            ;;
        diag_ping)
            set_user_state "$user_id" "diag_ping"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DIAG_PING_REQ" "[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_diag\"}]]"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        diag_traceroute)
            set_user_state "$user_id" "diag_traceroute"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DIAG_TRACE_REQ" "[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_diag\"}]]"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        diag_dns)
            set_user_state "$user_id" "diag_dns"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DIAG_DNS_REQ" "[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_diag\"}]]"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        diag_port)
            set_user_state "$user_id" "diag_port"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_DIAG_PORT_REQ" "[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_diag\"}]]"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_ports)
            local kb=$(get_ports_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_PORTS_HEADER" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            clear_user_state "$user_id"
            ;;
        port_view_*)
            local name="${data#port_view_}"
            # Validate name (letters, numbers, dash, underscore, space allowed)
            if ! echo "$name" | grep -qE '^[a-zA-Z0-9_ -]+$'; then
                tg_answer_callback "$cb_id" "Invalid rule name" "true"
                return
            fi
            # Find rule details
            local rule=$(get_port_rules | grep "^${name}|")
            if [ -n "$rule" ]; then
                local old_ifs="$IFS"
                IFS="|"
                read -r rname renable rproto rsrc_dport rdest_ip rdest_port <<EOF
$rule
EOF
                IFS="$old_ifs"
                local status_str="Выключено"
                [ "$renable" = "1" ] && status_str="Включено"
                
                local details=$(printf "$MSG_PORT_DETAILS" "$rname" "$rproto" "$rsrc_dport" "$rdest_ip" "$rdest_port" "$status_str")
                tg_edit_message_text "$chat_id" "$msg_id" "$details" "$(get_port_details_keyboard "$rname" "$renable")"
            fi
            tg_answer_callback "$cb_id" "" "false"
            ;;
        port_toggle_*)
            # Format: port_toggle_<name>_<action>
            local temp="${data#port_toggle_}"
            local action="${temp##*_}"
            local name="${temp%_*}"
            if ! echo "$name" | grep -qE '^[a-zA-Z0-9_ -]+$' || ! echo "$action" | grep -qE '^[01]$'; then
                tg_answer_callback "$cb_id" "Invalid action" "true"
                return
            fi
            toggle_port_rule "$name" "$action"
            # Refresh details
            local rule=$(get_port_rules | grep "^${name}|")
            if [ -n "$rule" ]; then
                local old_ifs="$IFS"
                IFS="|"
                read -r rname renable rproto rsrc_dport rdest_ip rdest_port <<EOF
$rule
EOF
                IFS="$old_ifs"
                local status_str="Выключено"
                [ "$renable" = "1" ] && status_str="Включено"
                
                local details=$(printf "$MSG_PORT_DETAILS" "$rname" "$rproto" "$rsrc_dport" "$rdest_ip" "$rdest_port" "$status_str")
                tg_edit_message_text "$chat_id" "$msg_id" "$details" "$(get_port_details_keyboard "$rname" "$renable")"
                tg_answer_callback "$cb_id" "$MSG_REFRESH_SUCCESS" "false"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "true"
            fi
            ;;
        port_delete_*)
            local name="${data#port_delete_}"
            if ! echo "$name" | grep -qE '^[a-zA-Z0-9_ -]+$'; then
                tg_answer_callback "$cb_id" "Invalid rule name" "true"
                return
            fi
            local msg=$(printf "$MSG_PORT_CONFIRM_DELETE" "$name")
            local kb="[[{\"text\":\"${BTN_YES}\",\"callback_data\":\"port_do_delete_${name}\"},{\"text\":\"${BTN_NO}\",\"callback_data\":\"port_view_${name}\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        port_do_delete_*)
            local name="${data#port_do_delete_}"
            if ! echo "$name" | grep -qE '^[a-zA-Z0-9_ -]+$'; then
                tg_answer_callback "$cb_id" "Invalid rule name" "true"
                return
            fi
            delete_port_rule "$name"
            tg_answer_callback "$cb_id" "$(printf "$MSG_PORT_DELETED" "$name")" "true"
            # Return to ports list
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_PORTS_HEADER" "$(get_ports_keyboard)"
            ;;
        port_add)
            set_user_state "$user_id" "port_add_name"
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_PORT_ADD_NAME" "[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_ports\"}]]"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        port_add_proto_*)
            local proto="${data#port_add_proto_}"
            local old_ifs="$IFS"
            local state=$(get_user_state "$user_id")
            clear_user_state "$user_id"
            
            if [ -n "$state" ] && echo "$state" | grep -q "^port_add_proto|"; then
                local name="${state#*name=}"
                name="${name%%|*}"
                local ext="${state#*ext=}"
                ext="${ext%%|*}"
                local ip="${state#*ip=}"
                ip="${ip%%|*}"
                local int="${state#*int=}"
                int="${int%%|*}"
                
                # Proto mapping
                local uci_proto="tcp"
                [ "$proto" = "udp" ] && uci_proto="udp"
                [ "$proto" = "all" ] && uci_proto="tcp udp"
                
                add_port_rule "$name" "$uci_proto" "$ext" "$ip" "$int"
                tg_answer_callback "$cb_id" "$(printf "$MSG_PORT_ADD_SUCCESS" "$name")" "true"
            else
                tg_answer_callback "$cb_id" "$MSG_REFRESH_ERROR" "true"
            fi
            # Return to list
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_PORTS_HEADER" "$(get_ports_keyboard)"
            ;;
        btn_about)
            local msg=$(printf "$MSG_ABOUT_TEXT" "$BOT_VERSION")
            local kb="[[{\"text\":\"${BTN_CHECK_UPDATES}\",\"callback_data\":\"btn_check_upd\"}], [{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_main\"}]]"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_check_upd)
            local now=$(date +%s)
            local last_check=0
            local cooldown_file="/tmp/telegram-bot/last_user_update_check"
            
            if [ -f "$cooldown_file" ]; then
                last_check=$(cat "$cooldown_file")
            fi
            
            local diff=$((now - last_check))
            if [ "$diff" -lt 5 ]; then
                local wait=$((5 - diff))
                local msg=$(printf "$MSG_UPD_COOLDOWN" "$wait")
                tg_answer_callback "$cb_id" "$msg" "true"
                return
            fi
            
            echo "$now" > "$cooldown_file"
            tg_answer_callback "$cb_id" "$MSG_CHECKING_UPDATES" "false"
            
            local url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
            local resp=$(curl -s -A "OpenWRT-TelegramBot" --connect-timeout 5 --max-time 10 -H "Accept: application/vnd.github.v3+json" "$url")
            local latest=$(echo "$resp" | jsonfilter -e '@.tag_name' 2>/dev/null | sed 's/^v//')
            
            if [ -z "$latest" ]; then
                tg_answer_callback "$cb_id" "$MSG_UPD_ERROR" "true"
            else
                # Semantic version comparison (0 = latest is newer, 1 = equal, 2 = current is newer)
                version_compare "$BOT_VERSION" "$latest"
                local cmp_result=$?
                if [ $cmp_result -eq 0 ]; then
                    # Current < latest — update available
                    local msg=$(printf "$MSG_UPD_AVAILABLE" "$latest")
                    local kb="[[{\"text\":\"${BTN_BACK}\",\"callback_data\":\"btn_about\"}]]"
                    tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
                else
                    # Current >= latest — no update
                    local msg=$(printf "$MSG_UPD_LATEST" "$BOT_VERSION")
                    tg_answer_callback "$cb_id" "$msg" "true"
                fi
            fi
            ;;
        btn_settings)
            local kb=$(get_settings_keyboard)
            tg_edit_message_text "$chat_id" "$msg_id" "$MSG_SETTINGS_HEADER" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_notify)
            local kb=$(get_notify_keyboard)
            local msg="${MSG_NOTIFY_HEADER}\n\n${MSG_NOTIFY_HINT}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        btn_lang)
            local kb=$(get_lang_keyboard)
            local msg="${MSG_LANG_HEADER}\n\n${MSG_LANG_CURRENT}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "" "false"
            ;;
        lang_en)
            uci set telegram.bot.language='en'
            uci commit telegram
            load_config
            local kb=$(get_lang_keyboard)
            local msg="${MSG_LANG_HEADER}\n\n${MSG_LANG_CHANGED}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "Language changed to English" "false"
            ;;
        lang_ru)
            uci set telegram.bot.language='ru'
            uci commit telegram
            load_config
            local kb=$(get_lang_keyboard)
            local msg="${MSG_LANG_HEADER}\n\n${MSG_LANG_CHANGED}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "Язык изменён на Русский" "false"
            ;;
        lang_uk)
            uci set telegram.bot.language='uk'
            uci commit telegram
            load_config
            local kb=$(get_lang_keyboard)
            local msg="${MSG_LANG_HEADER}\n\n${MSG_LANG_CHANGED}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "Мову змінено на Українську" "false"
            ;;
        lang_de)
            uci set telegram.bot.language='de'
            uci commit telegram
            load_config
            local kb=$(get_lang_keyboard)
            local msg="${MSG_LANG_HEADER}\n\n${MSG_LANG_CHANGED}"
            tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
            tg_answer_callback "$cb_id" "Sprache auf Deutsch geändert" "false"
            ;;
        notif_*)
            local setting="${data#notif_}"
            local uci_key=""
            case "$setting" in
                newdev) uci_key="telegram.notifications.new_device" ;;
                wanip) uci_key="telegram.notifications.wan_ip_change" ;;
                cpu) uci_key="telegram.notifications.high_cpu" ;;
                ram) uci_key="telegram.notifications.high_ram" ;;
                upd) uci_key="telegram.notifications.update_available" ;;
            esac
            
            if [ -n "$uci_key" ]; then
                local current=$(uci -q get "$uci_key" || echo 0)
                if [ "$current" = "1" ]; then
                    uci set "$uci_key=0"
                else
                    uci set "$uci_key=1"
                fi
                uci commit telegram
                local kb=$(get_notify_keyboard)
                local msg="${MSG_NOTIFY_HEADER}\n\n${MSG_NOTIFY_HINT}"
                tg_edit_message_text "$chat_id" "$msg_id" "$msg" "$kb"
                tg_answer_callback "$cb_id" "Notification setting saved" "false"
            fi
            ;;
        *)
            tg_answer_callback "$cb_id" "Unknown callback" "true"
            ;;
    esac
}

# ─── Main polling loop ───
# Read saved offset (no subshell — direct file read)
offset=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)

# Clean up stale rate limit files on startup
cleanup_rate_limits

# Periodic rate limit cleanup counter
rate_cleanup_counter=0

while true; do
    # Save response directly to a file (for jsonfilter -i)
    tg_api_call "getUpdates" "{\"offset\": ${offset}, \"timeout\": ${POLL_TIMEOUT}}" > "$RESP_FILE" 2>/dev/null
    
    # Check if curl failed
    if [ $? -ne 0 ] || [ ! -s "$RESP_FILE" ]; then
        sleep 2
        continue
    fi
    
    # Check API response
    ok=$(jsonfilter -i "$RESP_FILE" -e '@.ok' 2>/dev/null)
    
    if [ "$ok" != "true" ]; then
        log_error "API Error in getUpdates"
        sleep 2
        continue
    fi
    
    # Get all update IDs to determine the number of updates
    update_ids=$(jsonfilter -i "$RESP_FILE" -e '@.result[*].update_id' 2>/dev/null)
    
    # If no updates, continue polling
    [ -z "$update_ids" ] && continue
    
    # Process each update by index (NO subshell — offset updates correctly)
    idx=0
    for update_id in $update_ids; do
        # Check if this update is a callback_query or a message
        cb_data=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.data" 2>/dev/null)
        msg_text=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].message.text" 2>/dev/null)
        
        if [ -n "$cb_data" ]; then
            # ── Callback Query ──
            cb_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.id" 2>/dev/null)
            chat_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.message.chat.id" 2>/dev/null)
            msg_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.message.message_id" 2>/dev/null)
            user_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.from.id" 2>/dev/null)
            username=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].callback_query.from.username" 2>/dev/null)
            
            process_callback "$cb_id" "$chat_id" "$msg_id" "$cb_data" "$user_id" "$username"
            
        elif [ -n "$msg_text" ]; then
            # ── Text Message ──
            chat_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].message.chat.id" 2>/dev/null)
            user_id=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].message.from.id" 2>/dev/null)
            username=$(jsonfilter -i "$RESP_FILE" -e "@.result[${idx}].message.from.username" 2>/dev/null)
            
            process_message "$chat_id" "$user_id" "$username" "$msg_text"
        fi
        
        # Update offset in the MAIN shell (not a subshell!)
        offset=$((update_id + 1))
        echo "$offset" > "$OFFSET_FILE"
        
        idx=$((idx + 1))
    done
done
