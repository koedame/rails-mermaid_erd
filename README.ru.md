[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Это перевод [README на английском](./README.md). При расхождениях приоритет имеет английская версия.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Генерация [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) из вашего приложения Ruby on Rails.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Демонстрационная страница](https://koedame.github.io/rails-mermaid_erd/example.html)

ERD можно генерировать в любое время.
Сгенерированную ERD можно скопировать в формате Markdown, что позволяет легко делиться ею на GitHub.
Также есть возможность сохранить диаграмму в виде изображения — это удобно в средах, где Mermaid недоступен.
Редактор представляет собой единый HTML-файл, который можно целиком передавать другим пользователям.

## Установка

Добавьте следующую строку в Gemfile вашего приложения:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Затем выполните:

```bash
$ bundle install
```

Добавьте следующую строку в Rakefile вашего приложения:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Использование

Запуск Rake-задачи `mermaid_erd` сгенерирует файл `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Просто откройте сгенерированный файл `<app_root>/mermaid_erd/index.html` в браузере.

Этот файл не нужно добавлять в Git, поэтому при необходимости его можно исключить с помощью `.gitignore`:

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` — самодостаточный HTML-файл. Все внешние зависимости (Tailwind, Mermaid, Vue) встроены в него, поэтому он работает в офлайн-режиме и за строгими корпоративными прокси — CDN не требуется. Размер файла составляет около 4 МБ из-за встроенных бандлов.

Если поделиться этим файлом, им смогут воспользоваться те, у кого нет среды Ruby on Rails. Также можно загрузить файл на веб-сервер и открыть доступ по единому URL.

Особенно удобно автоматизировать генерацию с помощью CI.

### Вывод исходного кода Mermaid в stdout

Запустите Rake-задачу `mermaid_erd:print`, чтобы вывести исходный код `erDiagram` в stdout вместо создания HTML-просмотрщика. Вывод можно передать в другие инструменты по каналу:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

Вывод содержит полную диаграмму — все таблицы, столбцы, ключи, комментарии и связи — эквивалентно HTML-просмотрщику со всеми включёнными переключателями детализации.

## Языки

Интерфейс просмотрщика доступен на 12 языках: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский и العربية (справа налево). При загрузке язык определяется автоматически по настройке браузера (`navigator.language`); для неподдерживаемых локалей используется английский. Язык можно переключить вручную с помощью селектора в правом верхнем углу.

## Поддерживаемые версии

Сочетания Ruby и Rails, проверяемые в CI при каждом push и pull request:

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

Другие сочетания могут работать, но не проверяются.

## Настройка

Разместите файл `./config/mermaid_erd.yml` для изменения параметров конфигурации.
Пример конфигурации см. в [./docs/example.yml](./docs/example.yml).

Доступные параметры:

| ключ | описание | по умолчанию |
| --- | --- | --- |
| `result_path` | Путь для сохранения сгенерированных файлов. | `mermaid_erd/index.html` |
| `ignore_tables` | Массив строк регулярных выражений. Таблицы, чей `table_name` совпадает с любым шаблоном, исключаются из генерируемой ERD вместе со всеми связями, ссылающимися на них. Удобно для исключения моделей журналов аудита, таблиц с мягким удалением (soft delete) и устаревших таблиц или других избыточных объектов. Шаблоны компилируются через `Regexp.new`, поэтому в YAML-строках нужно экранировать обратные слеши (например, `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Лицензия

Gem распространяется как открытое программное обеспечение на условиях [лицензии MIT](https://opensource.org/licenses/MIT).
