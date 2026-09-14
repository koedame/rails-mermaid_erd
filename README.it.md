[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Questa è una traduzione del [README in inglese](./README.md). In caso di discrepanze, fa fede la versione inglese.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Genera un [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) dalla tua applicazione Ruby on Rails.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Pagina Demo](https://koedame.github.io/rails-mermaid_erd/example.html)

L'ERD può essere generato liberamente.
L'ERD generato può essere copiato in formato Markdown, quindi è facilmente condivisibile su GitHub.
Può essere salvato anche come immagine, quindi è utilizzabile in ambienti in cui Mermaid non è disponibile.
L'editor è un singolo file HTML, quindi l'intero editor può essere condiviso.

## Installazione

Aggiungi questa riga al Gemfile della tua applicazione:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Poi esegui:

```bash
$ bundle install
```

Aggiungi questa riga al Rakefile della tua applicazione:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Utilizzo

Eseguendo il task rake `mermaid_erd` verrà generato `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Apri semplicemente il file generato `<app_root>/mermaid_erd/index.html` nel tuo browser.

Questo file non è necessario per la gestione con Git, quindi puoi aggiungerlo a `.gitignore` se necessario.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` è un singolo file HTML autonomo e autocontenuto. Tutte le dipendenze front-end (Tailwind, Mermaid, Vue) sono incluse inline, quindi funziona offline e dietro proxy aziendali restrittivi — non è necessario alcun accesso a CDN al momento della visualizzazione. Il file è di circa 4 MB perché i bundle sono inclusi al suo interno.

Se condividi questo file, può essere utilizzato anche da chi non dispone di un ambiente Ruby on Rails. In alternativa, puoi caricare il file su un server web e condividerlo tramite lo stesso URL.

Sarebbe molto efficiente generarlo automaticamente tramite CI.

### Stampa la sorgente Mermaid sullo stdout

Esegui il task rake `mermaid_erd:print` per stampare la sorgente `erDiagram` grezza sullo stdout anziché scrivere il visualizzatore HTML. Questo si integra perfettamente con altri strumenti tramite pipe:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

L'output è il diagramma completo — ogni tabella, colonna, chiave, commento e relazione — equivalente al visualizzatore HTML con tutti i toggle di dettaglio attivati.

## Lingue

L'interfaccia del visualizzatore è disponibile in 12 lingue: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский e العربية (da destra a sinistra). Rileva automaticamente la lingua del browser (`navigator.language`) al caricamento, torna all'inglese per le lingue non supportate e può essere cambiata manualmente dal selettore nell'angolo in alto a destra.

## Versioni supportate

Le combinazioni Ruby × Rails verificate dalla CI ad ogni push e pull request:

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

Altre combinazioni potrebbero funzionare, ma non sono verificate.

## Configurazione

Utilizza `./config/mermaid_erd.yml` per personalizzare la configurazione.
Vedi [./docs/example.yml](./docs/example.yml) per un esempio di configurazione.

Le opzioni disponibili sono le seguenti.

| chiave | descrizione | predefinito |
| --- | --- | --- |
| `result_path` | Destinazione dei file generati. | `mermaid_erd/index.html` |
| `ignore_tables` | Array di stringhe di espressioni regolari. Le tabelle il cui `table_name` corrisponde a uno qualsiasi dei pattern vengono escluse dall'ERD generato, insieme a tutte le relazioni che le coinvolgono. Utile per escludere modelli di audit log, tabelle con eliminazione logica/legacy o altro rumore indesiderato nel diagramma. I pattern vengono compilati con `Regexp.new`, quindi è necessario fare l'escaping dei backslash nelle stringhe YAML (es. `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Licenza

Il gem è disponibile come open source nei termini della [Licenza MIT](https://opensource.org/licenses/MIT).
