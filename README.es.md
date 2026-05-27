[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Esta es una traducción del [README en inglés](./README.md). En caso de divergencia, la versión en inglés es la autoritativa.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Genera un [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) a partir de tu aplicación Ruby on Rails.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Página de demostración](https://koedame.github.io/rails-mermaid_erd/example.html)

El ERD se puede generar a voluntad.
El ERD generado puede copiarse en formato Markdown, por lo que se puede compartir fácilmente en GitHub.
También puedes guardarlo como imagen, así puede usarse en entornos donde Mermaid no está disponible.
El editor es un único archivo HTML, por lo que el editor completo puede compartirse.

## Instalación

Añade esta línea al Gemfile de tu aplicación:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Luego ejecuta:

```bash
$ bundle install
```

Añade esta línea al Rakefile de tu aplicación:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Uso

Ejecutar la tarea rake `mermaid_erd` generará `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Simplemente abre el archivo generado `<app_root>/mermaid_erd/index.html` en tu navegador.

Este archivo no es necesario para la gestión de Git, por lo que puedes añadirlo a `.gitignore` si es necesario.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` es un único archivo HTML autocontenido. Todas las dependencias de front-end (Tailwind, Mermaid, Vue) están incluidas en línea, por lo que funciona sin conexión y detrás de proxies corporativos estrictos — no se necesita acceso a CDN al visualizarlo. El archivo pesa aproximadamente 4 MB porque los bundles se incluyen dentro de él.

Si compartes este archivo, puede ser usado por quienes no tengan un entorno Ruby on Rails. O bien, puedes subir el archivo a un servidor web y compartirlo con la misma URL.

Sería muy inteligente generarlo automáticamente usando CI.

### Imprimir el código fuente de Mermaid en stdout

Ejecuta la tarea rake `mermaid_erd:print` para imprimir el código fuente `erDiagram` en stdout en lugar de escribir el visor HTML. Esto se puede redirigir fácilmente a otras herramientas:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

La salida es el diagrama completo — cada tabla, columna, clave, comentario y relación — equivalente al visor HTML con todos los controles de detalle activados.

## Idiomas

La interfaz del visor viene en 12 idiomas: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский, y العربية (de derecha a izquierda). Detecta automáticamente el idioma del navegador (`navigator.language`) al cargar, utiliza inglés como alternativa para idiomas no admitidos, y puede cambiarse manualmente desde el selector en la esquina superior derecha.

## Versiones compatibles

Las combinaciones de Ruby × Rails verificadas por CI en cada push y pull request:

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

Otras combinaciones pueden funcionar, pero no están verificadas.

## Configuración

Usa `./config/mermaid_erd.yml` para personalizar la configuración.
Consulta [./docs/example.yml](./docs/example.yml) para ver un ejemplo de configuración.

Los parámetros de configuración son los siguientes.

| clave | descripción | predeterminado |
| --- | --- | --- |
| `result_path` | Destino de los archivos generados. | `mermaid_erd/index.html` |
| `ignore_tables` | Array de cadenas de expresiones regulares. Las tablas cuyo `table_name` coincida con algún patrón se excluyen del ERD generado, junto con cualquier relación que apunte a ellas. Es útil para excluir modelos de registro de auditoría, tablas eliminadas lógicamente o legadas, u otro ruido que no desees renderizar. Los patrones se compilan con `Regexp.new`, así que escapa las barras invertidas dentro de las cadenas YAML (p. ej. `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Licencia
La gem está disponible como código abierto bajo los términos de la [MIT License](https://opensource.org/licenses/MIT).
