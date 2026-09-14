[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Dies ist eine Übersetzung des [englischen README](./README.md). Bei Abweichungen ist die englische Version maßgeblich.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Erstellt ein [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) aus Ihrer Ruby-on-Rails-Anwendung.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Demoseite](https://koedame.github.io/rails-mermaid_erd/example.html)

Das ERD kann jederzeit erzeugt werden.
Das erzeugte ERD kann im Markdown-Format kopiert werden und lässt sich so einfach auf GitHub teilen.
Es kann auch als Bild gespeichert werden, sodass es in Umgebungen ohne Mermaid-Unterstützung verwendet werden kann.
Der Editor ist eine einzelne HTML-Datei, weshalb der gesamte Editor weitergegeben werden kann.

## Installation

Fügen Sie diese Zeile zum Gemfile Ihrer Anwendung hinzu:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Führen Sie anschließend aus:

```bash
$ bundle install
```

Fügen Sie diese Zeile zum Rakefile Ihrer Anwendung hinzu:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Verwendung

Das Ausführen des Rake-Tasks `mermaid_erd` erzeugt `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Öffnen Sie die erzeugte Datei `<app_root>/mermaid_erd/index.html` einfach in Ihrem Browser.

Diese Datei wird für die Git-Verwaltung nicht benötigt, daher können Sie sie bei Bedarf zu `.gitignore` hinzufügen.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` ist eine einzelne, in sich geschlossene HTML-Datei. Alle Frontend-Abhängigkeiten (Tailwind, Mermaid, Vue) sind inline eingebettet, sodass die Datei offline und hinter strengen Unternehmens-Proxys funktioniert — beim Anzeigen ist kein CDN-Zugriff erforderlich. Die Datei ist etwa 4 MB groß, da die Bundles darin enthalten sind.

Wenn Sie diese Datei teilen, kann sie auch von Personen ohne Ruby-on-Rails-Umgebung verwendet werden. Alternativ können Sie die Datei auf einen Webserver hochladen und über dieselbe URL teilen.

Es wäre sehr sinnvoll, sie mithilfe von CI automatisch zu erzeugen.

### Die Mermaid-Quelle auf stdout ausgeben

Führen Sie den Rake-Task `mermaid_erd:print` aus, um die rohe `erDiagram`-Quelle auf stdout auszugeben, anstatt den HTML-Viewer zu schreiben. Damit lässt sich die Ausgabe direkt in andere Tools weiterleiten:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2               |
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

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Lizenz
Das Gem ist als Open Source unter den Bedingungen der [MIT License](https://opensource.org/licenses/MIT) verfügbar.
