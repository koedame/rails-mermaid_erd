[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Ceci est une traduction du [README en anglais](./README.md). En cas de divergence, la version anglaise fait foi.

<div align="center">

# Rails Mermaid ERD

**Générez un ERD Mermaid interactif de votre application Rails sous la forme d'un unique fichier HTML autonome.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="La visionneuse Rails Mermaid ERD affichant cinq modèles avec leurs clés primaires et étrangères, reliés par des lignes de relation." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[Page de démonstration](https://koedame.github.io/rails-mermaid_erd/example.html) · [Installation](#installation) · [Utilisation](#utilisation) · [Versions prises en charge](#versions-prises-en-charge) · [Configuration](#configuration)

</div>

Lancez `rails mermaid_erd` pour obtenir un unique fichier HTML autonome contenant le schéma de votre application Rails, sans gem ni service supplémentaire. Tailwind, Mermaid et Vue y sont intégrés : il s'ouvre hors ligne et derrière un proxy d'entreprise. Dans le navigateur, choisissez les tables voulues et exportez-les en code Mermaid, SVG ou PNG ; pour le partager, transmettez le fichier HTML ou déposez-le sur un serveur web.

## Points forts

- **Un seul fichier, rien d'autre à installer.** Le résultat est un unique fichier HTML d'environ 4 Mo avec Tailwind, Mermaid et Vue intégrés : il s'ouvre hors ligne et derrière un proxy d'entreprise.
- **Dessinez seulement ce qu'il vous faut.** Sélectionnez des modèles, affichez toutes les colonnes, seulement les clés ou aucune, et ajoutez des commentaires et des libellés de relation.
- **Exportez et partagez.** Copiez le code Mermaid ou Markdown, téléchargez un SVG ou un PNG, ou copiez un lien qui restaure votre vue.
- **Large compatibilité Rails.** La CI couvre Rails 5.2 à 8.1 avec Ruby 2.7 à 4.0.
- **12 langues.** La visionneuse suit la langue du navigateur, y compris l'arabe, écrit de droite à gauche.

## Installation

Ajoutez cette ligne au Gemfile de votre application :

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Puis exécutez :

```bash
bundle install
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
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

Ouvrez simplement le fichier généré `<app_root>/mermaid_erd/index.html` dans votre navigateur.

Ce fichier n'est pas nécessaire à la gestion Git, vous pouvez donc l'ajouter à `.gitignore` si besoin.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` est un fichier HTML unique et autonome. Toutes les dépendances front-end (Tailwind, Mermaid, Vue) sont intégrées en ligne, de sorte qu'il fonctionne hors ligne et derrière des proxies d'entreprise stricts — aucun accès à un CDN n'est nécessaire lors de la consultation. Le fichier pèse environ 4 Mo car les bundles y sont inclus.

Si vous partagez ce fichier, il peut être utilisé par ceux qui ne disposent pas d'un environnement Ruby on Rails. Vous pouvez également télécharger le fichier sur un serveur web et le partager via la même URL.

Le fichier généré contient le schéma de votre application, y compris les noms de tables et de colonnes ainsi que les commentaires. Ne le partagez ou ne l'hébergez qu'avec le même public que celui avec lequel vous partageriez le schéma lui-même.

Il serait très judicieux de le générer automatiquement à l'aide d'un CI.

### Imprimer la source Mermaid sur stdout

Exécutez la tâche rake `mermaid_erd:print` pour imprimer la source `erDiagram` brute sur stdout au lieu d'écrire le visualiseur HTML. Cela se redirige facilement vers d'autres outils :

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
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
| `viewer_defaults` | Vue avec laquelle le visualiseur s'ouvre quand l'URL ne porte aucun état enregistré, et à laquelle **Réinitialiser** revient ; un lien qui contient son propre état l'emporte toujours. `models` : tableau des noms de modèles sélectionnés au départ (un nom absent de l'ERD est ignoré avec un avertissement lors de la génération du fichier). `columns` : `all`, `keys` (clés primaires et étrangères uniquement) ou `none`, les mêmes choix que « Colonnes » dans la barre latérale. Utile pour ouvrir une grande application sur les modèles par lesquels on commence d'habitude. | `models: []` (aucune sélection), `columns: all` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Marques

Ce projet n'est affilié ni à Rails, ni à The Rails Foundation, ni au projet Mermaid, ni à Mermaid Chart Inc., et n'est ni approuvé ni parrainé par eux. Rails et Ruby on Rails sont des marques déposées de David Heinemeier Hansson. Mermaid Chart Inc. a déposé ou enregistré les marques MERMAID CHART et MERMAID aux États-Unis. Toutes les autres marques appartiennent à leurs propriétaires respectifs.

## Licence
La gem est disponible en open source selon les termes de la [MIT License](https://opensource.org/licenses/MIT).
