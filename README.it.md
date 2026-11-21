[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Questa è una traduzione del [README in inglese](./README.md). In caso di discrepanze, fa fede la versione inglese.

<div align="center">

# Rails Mermaid ERD

**Genera un ERD Mermaid interattivo della tua applicazione Rails come un unico file HTML autonomo.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="Il visualizzatore Rails Mermaid ERD con cinque modelli, le loro chiavi primarie ed esterne e le linee di relazione che li collegano." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[Pagina Demo](https://koedame.github.io/rails-mermaid_erd/example.html) · [Installazione](#installazione) · [Utilizzo](#utilizzo) · [Versioni supportate](#versioni-supportate) · [Configurazione](#configurazione)

</div>

Esegui `rails mermaid_erd` per ottenere un unico file HTML autonomo con lo schema della tua applicazione Rails, senza gem o servizi aggiuntivi. Tailwind, Mermaid e Vue sono incorporati, quindi il file si apre offline e dietro un proxy aziendale. Nel browser scegli le tabelle che ti servono e le esporti come codice Mermaid, SVG o PNG; per condividerlo basta inviare il file HTML o metterlo su un web server.

## Punti di forza

- **Un solo file, nient'altro da installare.** L'output è un unico file HTML di circa 4 MB con Tailwind, Mermaid e Vue incorporati, quindi si apre offline e dietro un proxy aziendale.
- **Disegna solo ciò che ti serve.** Seleziona i modelli, mostra tutte le colonne, solo le chiavi o nessuna, e aggiungi commenti ed etichette alle relazioni.
- **Esporta e condividi.** Copia il codice Mermaid o Markdown, scarica SVG o PNG, oppure copia un link che ripristina la tua vista.
- **Ampio supporto di Rails.** La CI copre da Rails 5.2 a 8.1 con Ruby da 2.7 a 4.0.
- **12 lingue.** Il visualizzatore segue la lingua del browser, compreso l'arabo, scritto da destra a sinistra.

## Installazione

Aggiungi questa riga al Gemfile della tua applicazione:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Poi esegui:

```bash
bundle install
```

Aggiungi questo al Rakefile della tua applicazione, **prima** di `Rails.application.load_tasks` (il task viene registrato quando i task vengono caricati, quindi un `require` dopo quella riga lascia `rails mermaid_erd` non riconosciuto):

```ruby
require_relative "config/application"

begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end

Rails.application.load_tasks
```

## Utilizzo

Eseguendo il task rake `mermaid_erd` verrà generato `<app_root>/mermaid_erd/index.html`.

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

Apri semplicemente il file generato `<app_root>/mermaid_erd/index.html` nel tuo browser.

Questo file non è necessario per la gestione con Git, quindi puoi aggiungerlo a `.gitignore` se necessario.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` è un singolo file HTML autonomo e autocontenuto. Tutte le dipendenze front-end (Tailwind, Mermaid, Vue) sono incluse inline, quindi funziona offline e dietro proxy aziendali restrittivi — non è necessario alcun accesso a CDN al momento della visualizzazione. Il file è di circa 4 MB perché i bundle sono inclusi al suo interno.

Se condividi questo file, può essere utilizzato anche da chi non dispone di un ambiente Ruby on Rails. In alternativa, puoi caricare il file su un server web e condividerlo tramite lo stesso URL.

Il file generato contiene lo schema della tua applicazione, inclusi i nomi di tabelle e colonne e i commenti. Condividilo od ospitalo solo con la stessa cerchia con cui condivideresti lo schema stesso.

Sarebbe molto efficiente generarlo automaticamente tramite CI.

### Stampa la sorgente Mermaid sullo stdout

Esegui il task rake `mermaid_erd:print` per stampare la sorgente `erDiagram` grezza sullo stdout anziché scrivere il visualizzatore HTML. Questo si integra perfettamente con altri strumenti tramite pipe:

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
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
| `viewer_defaults` | Vista con cui si apre il visualizzatore quando l'URL non contiene uno stato salvato, e a cui torna **Reimposta**; un link con un proprio stato ha sempre la precedenza. `models`: array dei nomi dei modelli selezionati all'inizio (un nome che non è nell'ERD viene saltato con un avviso durante la generazione del file). `columns`: `all`, `keys` (solo chiavi primarie ed esterne) o `none`, le stesse scelte di "Colonne" nella barra laterale. Utile per aprire una grande applicazione sui modelli da cui si parte di solito. | `models: []` (nessuna selezione), `columns: all` |

## Marchi

Questo progetto non è affiliato a Rails, alla Rails Foundation, al progetto Mermaid né a Mermaid Chart Inc., e non è da essi approvato o sponsorizzato. Rails e Ruby on Rails sono marchi registrati di David Heinemeier Hansson. Mermaid Chart Inc. ha registrato o depositato i marchi MERMAID CHART e MERMAID negli Stati Uniti. Tutti gli altri marchi appartengono ai rispettivi proprietari.

## Licenza

Il gem è disponibile come open source nei termini della [Licenza MIT](https://opensource.org/licenses/MIT).
