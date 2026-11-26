[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Dies ist eine Übersetzung des [englischen README](./README.md). Bei Abweichungen ist die englische Version maßgeblich.

<div align="center">

# Rails Mermaid ERD

**Erzeugen Sie ein interaktives Mermaid-ERD Ihrer Rails-Anwendung als einzelne, in sich geschlossene HTML-Datei.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="Der Rails-Mermaid-ERD-Viewer mit fünf Modellen samt Primär- und Fremdschlüsseln, verbunden durch Beziehungslinien." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[Demoseite](https://koedame.github.io/rails-mermaid_erd/example.html) · [Installation](#installation) · [Verwendung](#verwendung) · [Unterstützte Versionen](#unterstützte-versionen) · [Konfiguration](#konfiguration)

</div>

Mit `rails mermaid_erd` entsteht eine einzelne, in sich geschlossene HTML-Datei mit dem Schema Ihrer Rails-Anwendung – ohne zusätzliche Gems oder Dienste. Tailwind, Mermaid und Vue sind eingebettet, sodass sie offline und hinter einem Unternehmens-Proxy geöffnet werden kann. Im Browser wählen Sie die gewünschten Tabellen aus und exportieren sie als Mermaid-Code, SVG oder PNG; zum Teilen genügt es, die HTML-Datei weiterzugeben oder auf einen Webserver zu legen.

## Highlights

- **Eine Datei, sonst nichts zu installieren.** Das Ergebnis ist eine einzelne HTML-Datei von etwa 4 MB mit eingebetteten Tailwind-, Mermaid- und Vue-Bundles. Sie öffnet sich offline und hinter einem Unternehmens-Proxy.
- **Zeichnen Sie nur, was Sie brauchen.** Wählen Sie Modelle aus, zeigen Sie alle Spalten, nur Schlüssel oder keine an und ergänzen Sie Kommentare und Beziehungsbeschriftungen.
- **Exportieren und teilen.** Kopieren Sie Mermaid- oder Markdown-Code, laden Sie SVG oder PNG herunter oder kopieren Sie einen Link, der Ihre Ansicht wiederherstellt.
- **Breite Rails-Unterstützung.** Die CI deckt Rails 5.2 bis 8.1 auf Ruby 2.7 bis 4.0 ab.
- **12 Sprachen.** Der Viewer folgt der Browsersprache, einschließlich des von rechts nach links geschriebenen Arabisch.

## Installation

Fügen Sie diese Zeile zum Gemfile Ihrer Anwendung hinzu:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Führen Sie anschließend aus:

```bash
bundle install
```

Fügen Sie diese Zeile zum Rakefile Ihrer Anwendung hinzu:

```ruby
# Rakefile
require_relative "config/application"

begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end

Rails.application.load_tasks
```

Setzen Sie sie **vor** `Rails.application.load_tasks`. Die Task wird registriert, während `load_tasks` läuft; ein `require` danach (etwa am Dateiende) scheitert mit `Unrecognized command "mermaid_erd"`.

## Verwendung

Das Ausführen des Rake-Tasks `mermaid_erd` erzeugt `<app_root>/mermaid_erd/index.html`.

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

Öffnen Sie die erzeugte Datei `<app_root>/mermaid_erd/index.html` einfach in Ihrem Browser.

Diese Datei wird für die Git-Verwaltung nicht benötigt, daher können Sie sie bei Bedarf zu `.gitignore` hinzufügen.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` ist eine einzelne, in sich geschlossene HTML-Datei. Alle Frontend-Abhängigkeiten (Tailwind, Mermaid, Vue) sind inline eingebettet, sodass die Datei offline und hinter strengen Unternehmens-Proxys funktioniert — beim Anzeigen ist kein CDN-Zugriff erforderlich. Die Datei ist etwa 4 MB groß, da die Bundles darin enthalten sind.

Wenn Sie diese Datei teilen, kann sie auch von Personen ohne Ruby-on-Rails-Umgebung verwendet werden. Alternativ können Sie die Datei auf einen Webserver hochladen und über dieselbe URL teilen.

Die erzeugte Datei enthält das Schema Ihrer Anwendung, einschließlich Tabellen- und Spaltennamen sowie Kommentaren. Geben Sie sie nur in dem Kreis weiter oder hosten Sie sie nur dort, in dem Sie auch das Schema selbst teilen würden.

Es wäre sehr sinnvoll, sie mithilfe von CI automatisch zu erzeugen.

### Die Mermaid-Quelle auf stdout ausgeben

Führen Sie den Rake-Task `mermaid_erd:print` aus, um die rohe `erDiagram`-Quelle auf stdout auszugeben, anstatt den HTML-Viewer zu schreiben. Damit lässt sich die Ausgabe direkt in andere Tools weiterleiten:

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

Die Ausgabe ist das vollständige Diagramm — jede Tabelle, Spalte, Schlüssel, Kommentar und Relation — gleichwertig mit dem HTML-Viewer bei aktivierten Detailansichten.

## Sprachen

Die Viewer-Oberfläche ist in 12 Sprachen verfügbar: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский und العربية (von rechts nach links). Beim Laden wird die Browsersprache (`navigator.language`) automatisch erkannt, bei nicht unterstützten Sprachen wird auf Englisch zurückgegriffen, und die Sprache kann manuell über den Selektor oben rechts gewechselt werden.

## Unterstützte Versionen

Die Ruby-×-Rails-Kombinationen, die CI bei jedem Push und Pull Request überprüft:

| Rails | Ruby                             |
| ----- | -------------------------------- |
| 5.2   | 2.7                              |
| 6.0   | 2.7, 3.0                         |
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.0   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.1   | 3.1, 3.2, 3.3, 3.4               |
| 7.2   | 3.1, 3.2, 3.3, 3.4               |
| 8.0   | 3.2, 3.3, 3.4, 4.0               |
| 8.1   | 3.2, 3.3, 3.4, 4.0               |

Andere Kombinationen können funktionieren, werden jedoch nicht geprüft.

## Konfiguration

Verwenden Sie `./config/mermaid_erd.yml`, um die Konfiguration anzupassen.
Ein Beispiel finden Sie unter [./docs/example.yml](./docs/example.yml).

Die Konfigurationsparameter sind wie folgt.

| Schlüssel | Beschreibung | Standard |
| --- | --- | --- |
| `result_path` | Zielverzeichnis der erzeugten Dateien. | `mermaid_erd/index.html` |
| `ignore_tables` | Array von regulären Ausdrücken als Zeichenketten. Tabellen, deren `table_name` einem Muster entspricht, werden zusammen mit allen darauf verweisenden Relationen aus dem erzeugten ERD ausgeschlossen. Nützlich, um Audit-Log-Modelle, weich gelöschte oder veraltete Tabellen oder anderes störendes Rauschen auszublenden. Die Muster werden mit `Regexp.new` kompiliert, daher müssen Backslashes innerhalb von YAML-Zeichenketten escapet werden (z. B. `"\\Aaudit_"`). | `[]` |
| `viewer_defaults` | Ansicht, mit der sich der Viewer öffnet, wenn die URL keinen gespeicherten Zustand enthält, und zu der **Zurücksetzen** zurückkehrt; ein Link mit eigenem Zustand hat immer Vorrang. `models`: Array der Modellnamen, die anfangs ausgewählt sind (ein Name, der nicht im ERD vorkommt, wird beim Erzeugen der Datei mit einer Warnung übersprungen). `columns`: `all`, `keys` (nur Primär- und Fremdschlüssel) oder `none` – dieselben Optionen wie „Spalten“ in der Seitenleiste. Praktisch, um eine große Anwendung mit den Modellen zu öffnen, bei denen man meist beginnt. | `models: []` (keine Auswahl), `columns: all` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Marken

Dieses Projekt steht in keiner Verbindung zu Rails, der Rails Foundation, dem Mermaid-Projekt oder Mermaid Chart Inc. und wird von ihnen weder unterstützt noch gesponsert. Rails und Ruby on Rails sind eingetragene Marken von David Heinemeier Hansson. Mermaid Chart Inc. hat die Marken MERMAID CHART und MERMAID in den USA eingetragen oder angemeldet. Alle übrigen Marken sind Eigentum ihrer jeweiligen Inhaber.

## Lizenz
Das Gem ist als Open Source unter den Bedingungen der [MIT License](https://opensource.org/licenses/MIT) verfügbar.
