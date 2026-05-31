# Was ist das?

**OpenWRT Telegram Bot** ist ein leichtgewichtiger, schneller und sicherer Telegram-Bot zur Fernüberwachung und -steuerung von OpenWRT-basierten Routern. Vollständig in reinem Shell unter Verwendung der integrierten Router-API (`ubus`, `uci`, `jsonfilter`) und der Telegram-API geschrieben.

Die Konfiguration der Einstellungsdatei ist sowohl über die Konfigurationsdatei `/etc/config/telegram` als auch über die **LuCI**-Weboberfläche verfügbar - Einstellung des Tokens, der Liste der Administratoren, der Bot-Benachrichtigungen, Überprüfung von Updates und Protokollausgabe unter `Services -> Telegram Bot`

<img width="1144" height="679" alt="image" src="https://github.com/user-attachments/assets/67f7a903-57cf-43e2-9999-6b75a10ab279" />

---

## README

* [Русский](README.md)
* [English](README_EN.md)
* [Український](README_UK.md)
* [Deutsches](README_DE.md)
  
---

## Inhaltsverzeichnis
- [Architektur](#architektur)
- [Systemanforderungen](#systemanforderungen)
- [Hauptfunktionen](#hauptfunktionen)
- [Ressourcenverbrauch](#ressourcenverbrauch)
- [Installation und Updates](#installation)
- [Deinstallation](#deinstallation)
- [Lizenz](#lizenz)
- [Entwickler unterstützen](#entwickler-unterstützen)

---

## Architektur

- **Shell**: Reines `/bin/sh`;
- **Low-Level-Dienstprogramme**: Zum Parsen von JSON wird der integrierte Binärparser `jsonfilter` verwendet;
- **Datenaustausch**: Netzwerkanfragen werden über `curl` durchgeführt;
- **Schonung des Flash-Speichers**: Temporäre Dateien befinden sich im Verzeichnis `/tmp`;
- **Integrierter Daemon**: Der Bot läuft als Systemdienst unter der Verwaltung des `procd`-Supervisors.

---

## Systemanforderungen

- **Betriebssystem**: OpenWRT **Version 19.07 und höher**;
- **Basisabhängigkeiten** (werden automatisch installiert):
  - `curl`;
  - `jsonfilter`;
  - `ca-certificates` / `ca-bundle`.
- **Zusätzliche Abhängigkeiten** (werden optional in `install.sh` für erweiterte Module installiert):
  - `etherwake` oder `wol` - für die Wake-on-LAN-Funktion;
  - `vnstat` / `vnstatd` - zum Sammeln allgemeiner Verkehrsstatistiken;
  - `nlbwmon` - zur Erfassung des Netzwerkverbrauchs durch lokale Clients.

---

## Hauptfunktionen

- **📊 Systemüberwachung**:
  - Anzeige von **Uptime**, **Softwareversion**, **freiem RAM/Flash-Speicher**, **Prozessorauslastung** (CPU), **WAN-IP**-Adressen;
  - **Ausführung** von Standard-**Netzwerk-Dienstprogrammen** mit dynamischer Echtzeitausgabe (Ping, Traceroute, DNS Lookup, Port Check).
- **⚡ Verwaltung von Netzwerkschnittstellen**:
  - **Aktivieren/Deaktivieren** jeder in OpenWRT verfügbaren **Netzwerkschnittstelle**;
  - Anzeige detaillierter Informationen zu jeder Netzwerkschnittstelle.
- **📱 Liste verbundener Geräte**
  - Sofortige **Ausgabe aktiver DHCP-Leases** mit detaillierten Informationen wie IP-Adresse, Verbindungsschnittstelle und mehr;
  - Möglichkeit, jedes Gerät vom Netzwerk zu trennen;
  - Möglichkeit, ein Gerät für die nachfolgende Verbindung mit dieser Netzwerkschnittstelle zu sperren;
  - Möglichkeit, ein **Wake-on-LAN**-Paket zu senden.
- **🔀 Portweiterleitung (NAT)**
  - **Firewall-Verwaltung** des Routers ohne Anmeldung bei LuCI;
  - Erstellen, Ändern, Aktivieren/Deaktivieren bereits vorhandener Regeln.
- **🔄 Neustart**
  - Neustart jeder Netzwerkschnittstelle, einschließlich des Routers selbst.
- **🔔 Benachrichtigungen**
  - **Konfiguration von Benachrichtigungen** über den Telegram-Bot (Geräteverbindung / WAN-IP-Änderung / Hohe Systemlast).
- **🌐 Lokalisierung**
  - **Unterstützung für 4 Sprachen**, einschließlich Russisch, Englisch, Ukrainisch, Deutsch.
- **📁 LuCI-Integration**
  - Konfiguration des API-Schlüssels, der Administrator-IDs, der Benachrichtigungen über den Bot, der Update-Prüfung und mehr;
  - Anzeige detaillierter Protokolle des Telegram-Bots.

---

## Ressourcenverbrauch

* **RAM**: **weniger als 2 MB** während des Betriebs. Im Standby-Modus ist die Last praktisch null;
* **Flash-Speicher**: **weniger als 60 KB** für die gesamte Installation;
  - Alle veränderlichen Dateien (Datenbank für Benutzerstatus, temporäre FIFO-Kanäle, PID-Dateien, Protokolle) werden in das Verzeichnis `/tmp` ausgelagert.
* **CPU-Last**: Weniger als **1%**.

---

## Installation

Für die Installation ist OpenWRT Version `19.07` und höher erforderlich.

**ACHTUNG**: Die Tests wurden nur von mir auf Version `25.12.0` durchgeführt, auf anderen Versionen können Fehler auftreten!

1. Verbinden Sie sich mit dem Router (z. B. mit [Putty](https://github.com/putty-org-ru/PuTTY/releases));
2. Führen Sie den **Befehl zum automatischen Herunterladen** und Starten des Installationsprogramms aus:
   ```bash
   wget -qO- https://raw.githubusercontent.com/vlam1n-dev/OpenWRT-TelegramBot/main/install.sh | sh
   ```
3. Folgen Sie den Anweisungen des Installationsprogramms.

Gehen Sie nach erfolgreicher Installation zur LuCI-Weboberfläche des Routers (falls installiert): `Services -> Telegram Bot`, geben Sie Ihr Bot-Token ein (erhalten von [@BotFather](https://t.me/BotFather)) und fügen Sie Ihre **Telegram-ID** zur Liste der Administratoren hinzu.

Die Aktualisierung erfolgt auf die gleiche Weise. Geben Sie beim Ausführen von `install.sh` die **neue Version** an oder installieren Sie **automatisch**.

---

## Deinstallation

Um den Bot und alle seine Komponenten vollständig und sicher zu entfernen, führen Sie das Deinstallationsprogramm aus:
```bash
wget -qO- https://raw.githubusercontent.com/vlam1n-dev/OpenWRT-TelegramBot/main/uninstall.sh | sh
```

Sie können wählen, welche **Komponenten entfernt** und welche **beibehalten** werden sollen, einschließlich der **Konfigurationsdatei**.

---

## Lizenz

Das Projekt wird unter der **MIT**-Lizenz verbreitet. Projekt-Autor: [VLaM1N-Dev](https://github.com/vlam1n-dev).

---

## Entwickler unterstützen

USDT TRC20 ```TWxCEaSNwbXwXs82ad9q9x9EifPQxMwGbb```

USDT ERC20 ```0x0755c77914fc933e029073ad4773643dfdc7a6b1```

ETH ```0x0755c77914fc933e029073ad4773643dfdc7a6b1```

BTC ```194ehsjJWGvrqCsbLmwLz8gTbHA2zTv2Cu```
