[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Ceci est une traduction du [README en anglais](./README.md). En cas de divergence, la version anglaise fait foi.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Générez un [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) à partir de votre application Ruby on Rails.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Page de démonstration](https://koedame.github.io/rails-mermaid_erd/example.html)

Le diagramme ERD peut être généré à volonté.
Le diagramme généré peut être copié au format Markdown, ce qui permet de le partager facilement sur GitHub.
Vous pouvez également l'enregistrer en tant qu'image, afin de l'utiliser dans des environnements où Mermaid n'est pas disponible.
L'éditeur est un fichier HTML unique, ce qui permet de partager l'éditeur dans son intégralité.

## Installation

Ajoutez cette ligne au Gemfile de votre application :

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Puis exécutez :

```bash
$ bundle install
```

Ajoutez cette ligne au Rakefile de votre application :

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Utilisation

Exécuter la tâche rake `mermaid_erd` génère `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Ouvrez simplement le fichier généré `<app_root>/mermaid_erd/index.html` dans votre navigateur.

Ce fichier n'est pas nécessaire à la gestion Git, vous pouvez donc l'ajouter à `.gitignore` si besoin.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` est un fichier HTML unique et autonome. Toutes les dépendances front-end (Tailwind, Mermaid, Vue) sont intégrées en ligne, de sorte qu'il fonctionne hors ligne et derrière des proxies d'entreprise stricts — aucun accès à un CDN n'est nécessaire lors de la consultation. Le fichier pèse environ 4 Mo car les bundles y sont inclus.

Si vous partagez ce fichier, il peut être utilisé par ceux qui ne disposent pas d'un environnement Ruby on Rails. Vous pouvez également télécharger le fichier sur un serveur web et le partager via la même URL.

Il serait très judicieux de le générer automatiquement à l'aide d'un CI.

### Imprimer la source Mermaid sur stdout

Exécutez la tâche rake `mermaid_erd:print` pour imprimer la source `erDiagram` brute sur stdout au lieu d'écrire le visualiseur HTML. Cela se redirige facilement vers d'autres outils :

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

La sortie est le diagramme complet — chaque table, colonne, clé, commentaire et relation — équivalant au visualiseur HTML avec tous les contrôles de détail activés.

## Langues

L'interface du visualiseur est disponible en 12 langues : English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский, et العربية (de droite à gauche). La langue du navigateur (`navigator.language`) est détectée automatiquement au chargement, l'anglais est utilisé par défaut pour les langues non prises en charge, et la langue peut être changée manuellement depuis le sélecteur en haut à droite.

## Versions prises en charge

Les combinaisons Ruby × Rails vérifiées par CI à chaque push et pull request :

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

D'autres combinaisons peuvent fonctionner, mais ne sont pas vérifiées.

## Configuration

Utilisez `./config/mermaid_erd.yml` pour personnaliser la configuration.
Consultez [./docs/example.yml](./docs/example.yml) pour un exemple de configuration.

Les paramètres de configuration sont les suivants.

| clé | description | par défaut |
| --- | --- | --- |
| `result_path` | Destination des fichiers générés. | `mermaid_erd/index.html` |
| `ignore_tables` | Tableau de chaînes d'expressions régulières. Les tables dont le `table_name` correspond à l'un des motifs sont exclues du diagramme ERD généré, ainsi que toutes les relations qui les ciblent. Utile pour exclure les modèles de journaux d'audit, les tables supprimées logiquement ou héritées, ou tout autre bruit que vous ne souhaitez pas afficher. Les motifs sont compilés avec `Regexp.new`, il faut donc échapper les barres obliques inverses dans les chaînes YAML (par ex. `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Licence
La gem est disponible en open source selon les termes de la [MIT License](https://opensource.org/licenses/MIT).
