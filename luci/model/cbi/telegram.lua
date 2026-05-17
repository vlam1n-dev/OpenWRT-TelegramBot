m = Map("telegram", translate("Telegram Bot"), translate("Configuration for Telegram Bot. Create a bot using @BotFather and get the API Token."))

s = m:section(NamedSection, "bot", "telegram", translate("General Settings"))

e = s:option(Flag, "enabled", translate("Enable Service"))
e.rmempty = false

t = s:option(Value, "api_token", translate("API Token"))
t.password = true
t.rmempty = false

l = s:option(ListValue, "language", translate("Bot Language"))
l:value("en", "English")
l:value("ru", "Русский")
l:value("uk", "Українська")
l:value("de", "Deutsch")
l.default = "en"

p = s:option(Value, "poll_timeout", translate("Long Polling Timeout (s)"))
p.datatype = "uinteger"
p.default = "30"

c = s:option(Value, "curl_connect_timeout", translate("Connection Timeout (s)"))
c.datatype = "uinteger"
c.default = "10"

rl = s:option(Value, "rate_limit_count", translate("Rate Limit Count"))
rl.datatype = "uinteger"
rl.default = "10"

rw = s:option(Value, "rate_limit_window", translate("Rate Limit Window (s)"))
rw.datatype = "uinteger"
rw.default = "3"

-- Log File Limits
l_bot_max = s:option(Value, "log_bot_max_lines", translate("Bot Log Max Lines"), translate("Maximum lines in bot log file before auto-clearing"))
l_bot_max.datatype = "uinteger"
l_bot_max.default = "1000"

l_bot_reset = s:option(Value, "log_bot_reset_time", translate("Bot Log Reset Interval (s)"), translate("Time in seconds before clearing bot log (0 to disable)"))
l_bot_reset.datatype = "uinteger"
l_bot_reset.default = "86400"

l_auth_max = s:option(Value, "log_auth_max_lines", translate("Auth Log Max Lines"), translate("Maximum lines in unauthorized attempts log file before auto-clearing"))
l_auth_max.datatype = "uinteger"
l_auth_max.default = "1000"

l_auth_reset = s:option(Value, "log_auth_reset_time", translate("Auth Log Reset Interval (s)"), translate("Time in seconds before clearing auth log (0 to disable)"))
l_auth_reset.datatype = "uinteger"
l_auth_reset.default = "86400"

-- Admins Section
a = m:section(NamedSection, "admins", "telegram", translate("Administrators"))

aid = a:option(DynamicList, "admin_id", translate("Admin Chat IDs"), translate("Add your Telegram User ID or Chat ID here"))

-- Notifications Section
n = m:section(NamedSection, "notifications", "telegram", translate("Notifications"))

nd = n:option(Flag, "new_device", translate("New Device Connected"))
nd.rmempty = false

wi = n:option(Flag, "wan_ip_change", translate("WAN IP Changed"))
wi.rmempty = false

hc = n:option(Flag, "high_cpu", translate("High CPU Load"))
hc.rmempty = false

hct = n:option(Value, "high_cpu_threshold", translate("CPU Threshold (%)"))
hct.datatype = "uinteger"
hct.default = "90"
hct:depends("high_cpu", "1")

hr = n:option(Flag, "high_ram", translate("High RAM Usage"))
hr.rmempty = false

hrt = n:option(Value, "high_ram_threshold", translate("RAM Threshold (%)"))
hrt.datatype = "uinteger"
hrt.default = "90"
hrt:depends("high_ram", "1")

ua = n:option(Flag, "update_available", translate("Update Available"))
ua.rmempty = false

-- Add status template
st = s:option(DummyValue, "_status")
st.template = "telegram/status"

-- Add project info template at the very end
local info = m:section(SimpleSection, nil, nil)
info.template = "telegram/project_info"

-- Apply custom apply logic
m.on_after_commit = function(self)
    luci.sys.call("/etc/init.d/telegram restart >/dev/null 2>&1")
end

return m
