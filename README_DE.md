# 🤖 OpenWRT Telegram Bot

**OpenWRT Telegram Bot** ist ein extrem leichtgewichtiger, schneller und sicherer Telegram-Bot zur Fernüberwachung und -verwaltung von Routern unter OpenWRT. Er wurde vollständig in reinem POSIX Shell geschrieben und nutzt die nativen APIs des Routers (`ubus`, `jsonfilter`), was ihn zur perfekten Lösung für ressourcenbeschränkte eingebettete Systeme macht.

Das Projekt verfügt über eine vollständige administrative **LuCI**-Weboberfläche, mit der Sie das Token, die Administratorliste, Benachrichtigungen und Protokolle direkt über das Standard-Webmenü des Routers konfigurieren können.

---

## 📈 Funktionsweise & Architektur

Der Bot wurde unter Berücksichtigung der strengen Grenzwerte eingebetteter Systeme entwickelt:
1. **Reines Shell**: Es werden keine schweren Abhängigkeiten wie Python, Node.js oder Lua-Skripte geladen. Der Bot ist komplett in `/bin/sh` geschrieben.
2. **Low-Level-Dienstprogramme**: Zum Parsen von JSON-Strings wird das in OpenWRT integrierte, schnelle binäre Dienstprogramm `jsonfilter` verwendet.
3. **Datenkommunikation**: Netzwerkaufrufe werden über `curl` mit strengen Verbindungs- und Long-Polling-Timeouts verwaltet, um Hänger des Prozesses zu verhindern.
4. **Schutz des Flash-Speichers**: Alle temporären Dateien, der Update-Cache und die Protokolldateien verbleiben ausschließlich in `/tmp` (RAM-basiertes `tmpfs`), wodurch der physikalische Flash-Speicher Ihres Routers vollständig vor Abnutzung durch Schreibvorgänge geschützt wird.
5. **System-Daemon**: Implementiert als standardmäßiger Systemdienst (`init.d`) mit automatischer Startunterstützung beim Booten.

---

## ⚡ RAM- & Flash-Speicherbedarf

* **RAM-Nutzung**: **unter 2 MB** während der aktiven Ausführung (in Spitzenzeiten von Long Polling). Im Leerlauf ist die CPU- und RAM-Last nahezu Null.
* **Flash-Speicherplatz**: **unter 60 KB** für die gesamte Installation (einschließlich aller Skripte, Übersetzungen, LuCI-Controller und Templates).
* **CPU-Last**: Unter **0,1 %** auf Standard-Hardware (Berechnungen werden nur bei der Verarbeitung von Benutzerbefehlen ausgelöst).

---

## ✨ Features

* **📊 Systemüberwachung**: Anzeige von Betriebszeit, Softwareversionen, freiem RAM/Flash, CPU-Last und WAN-IP-Adressen.
* **⚡ Schnittstellensteuerung**: Aktivieren/Deaktivieren jeder Netzwerkschnittstelle direkt im Chat mit Bestätigungsschaltflächen.
* **📱 Verbundene Geräte**: Anzeige aktiver DHCP-Leases mit Gerätenamen, IP- und MAC-Adressen.
* **🔄 Router-Neustart**: Sicheres und ferngesteuertes Neustarten des Routers direkt über die Tastatur des Bots.
* **🌐 Mehrsprachigkeit (Lokalisierung)**: Unterstützung von 4 Sprachen direkt nach der Installation (Russisch 🇷🇺, Englisch 🇬🇧, Ukrainisch 🇺🇦, Deutsch 🇩🇪), im Bot oder in LuCI umschaltbar.
* **🔔 Intelligente Benachrichtigungen**:
  * Bei Verbindung eines neuen Geräts mit dem Netzwerk (überwacht MAC-Adressen).
  * Bei Änderung der externen WAN-IP-Adresse.
  * Bei kritischer CPU-Last oder geringem RAM (konfigurierbare Schwellenwerte in %).
  * Bei Veröffentlichung neuer Bot-Updates.
* **🔐 Sicherheit & Zugriffskontrolle**: Der Zugriff ist streng auf Administratoren beschränkt, die der UCI-Whitelist hinzugefügt wurden. Unbefugte Interaktionen werden blockiert und protokolliert.
* **📁 Protokollverwaltung in LuCI**: Ein wunderschönes, themenadaptives modales Fenster zur Anzeige von Logs mit automatischen Bereinigungseinstellungen basierend auf dem Alter (Sekunden) oder der maximalen Zeilenanzahl.

---

## 🛠 Schnelle Installation

Erfordert `root`-Rechte und OpenWRT v24+ (mit `apk`-Unterstützung).

1. Verbinden Sie sich über SSH mit Ihrem Router.
2. Laden Sie das Projektarchiv nach `/tmp` herunter:
   ```bash
   wget -O /tmp/bot.tar.gz https://github.com/vlam1n-dev/OpenWRT-TelegramBot/archive/refs/heads/main.tar.gz
   ```
3. Entpacken Sie das Archiv und öffnen Sie das Verzeichnis:
   ```bash
   tar -xzf /tmp/bot.tar.gz -C /tmp/
   cd /tmp/OpenWRT-TelegramBot-main
   ```
4. Führen Sie das Installationsskript aus:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

Gehen Sie nach der Installation in der LuCI-Weboberfläche auf **Dienste ➡️ Telegram Bot**, geben Sie Ihr API-Token (von `@BotFather`) ein, fügen Sie Ihre Telegram-User-ID der Administratorliste hinzu und aktivieren Sie den Dienst.

---

## 🧹 Deinstallation

So deinstallieren Sie den Bot und all seine Elemente vollständig und sicher, ohne andere LuCI-Komponenten zu beeinträchtigen:
```bash
cd /tmp/OpenWRT-TelegramBot-main 2>/dev/null || cd /tmp/telegram-bot
chmod +x uninstall.sh
./uninstall.sh
```

---

## 📄 Lizenz

Dieses Projekt ist unter den Bedingungen der **MIT**-Lizenz lizenziert. Erstellt von **VLaM1N-Dev**.
