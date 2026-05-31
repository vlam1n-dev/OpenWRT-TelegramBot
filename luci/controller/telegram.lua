module("luci.controller.telegram", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/telegram") then
        return
    end

    entry({"admin", "services", "telegram"}, cbi("telegram"), _("Telegram Bot"), 60).dependent = true
    entry({"admin", "services", "telegram", "status"}, call("action_status"))
    entry({"admin", "services", "telegram", "test_api"}, post("action_test_api"))
    entry({"admin", "services", "telegram", "check_update"}, call("action_check_update"))
    entry({"admin", "services", "telegram", "read_log", "*"}, call("action_read_log"))
    entry({"admin", "services", "telegram", "clear_log", "*"}, post("action_clear_log"))
end

function action_status()
    local sys = require "luci.sys"
    local enabled = sys.exec("uci -q get telegram.bot.enabled")
    local pid = sys.exec("cat /tmp/telegram-bot/bot.pid 2>/dev/null")
    local running = false
    
    if pid and pid ~= "" then
        running = (sys.exec("kill -0 " .. pid .. " 2>/dev/null && echo 1") == "1\n")
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        enabled = (enabled == "1\n"),
        running = running,
        pid = string.gsub(pid, "\n", "")
    })
end

function action_test_api()
    local sys = require "luci.sys"
    local token = sys.exec("uci -q get telegram.bot.api_token")
    token = string.gsub(token, "\n", "")
    
    if token == "" then
        luci.http.prepare_content("application/json")
        luci.http.write_json({ ok = false, error = "Token not found" })
        return
    end
    
    -- Validate token: only allow alphanumeric and colon characters (bot tokens are digits:alphanumeric)
    if not token:match("^[%w:_-]+$") then
        luci.http.prepare_content("application/json")
        luci.http.write_json({ ok = false, error = "Invalid token format" })
        return
    end
    
    local cmd = string.format("curl -s --connect-timeout 10 'https://api.telegram.org/bot%s/getMe'", token)
    local resp = sys.exec(cmd)
    
    luci.http.prepare_content("application/json")
    luci.http.write(resp)
end

function action_check_update()
    local sys = require "luci.sys"
    local local_ver = sys.exec("cat /usr/lib/telegram-bot/VERSION 2>/dev/null")
    if not local_ver or local_ver == "" then
        local_ver = sys.exec("cat ./VERSION 2>/dev/null")
    end
    if not local_ver or local_ver == "" then
        local_ver = "1.0.32"
    end
    local_ver = string.gsub(local_ver, "%s+", "")

    local cmd = "curl -s -A 'OpenWRT-TelegramBot-LuCI' --connect-timeout 10 https://api.github.com/repos/vlam1n-dev/OpenWRT-TelegramBot/releases/latest"
    local resp = sys.exec(cmd)
    
    local json = require "luci.jsonc"
    local parsed = nil
    if resp and resp ~= "" then
        parsed = json.parse(resp)
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        local_version = local_ver,
        github = parsed
    })
end

function action_read_log(log_type)
    local path = ""
    if log_type == "bot" then
        path = "/tmp/telegram-bot/bot.log"
    elseif log_type == "auth" then
        path = "/tmp/telegram-bot/unauth.log"
    elseif log_type == "error" then
        path = "/tmp/telegram-bot/error.log"
    else
        luci.http.prepare_content("application/json")
        luci.http.write_json({ content = nil, error = "Invalid log type" })
        return
    end

    local content = ""
    local f = io.open(path, "r")
    if f then
        content = f:read("*all")
        f:close()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({ content = content })
end

function action_clear_log(log_type)
    local path = ""
    if log_type == "bot" then
        path = "/tmp/telegram-bot/bot.log"
    elseif log_type == "auth" then
        path = "/tmp/telegram-bot/unauth.log"
    elseif log_type == "error" then
        path = "/tmp/telegram-bot/error.log"
    else
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Invalid log type" })
        return
    end

    local f = io.open(path, "w")
    if f then
        f:write("")
        f:close()
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = true })
    else
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Failed to clear log" })
    end
end
