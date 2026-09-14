[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> 本文档是 [英文 README](./README.md) 的翻译版本。如有差异，以英文版为准。

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

从你的 Ruby on Rails 应用生成 [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram)。

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[演示页面](https://koedame.github.io/rails-mermaid_erd/example.html)

可以随时生成 Mermaid ERD。
生成的 ERD 可以以 Markdown 格式复制，因此可以轻松在 GitHub 上分享。
还可以保存为图片，在不支持 Mermaid 的环境中也能使用。
编辑器是单个 HTML 文件，因此可以直接共享整个编辑器。

## 安装

将以下行添加到你的应用 Gemfile 中：

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

然后执行：

```bash
$ bundle install
```

将以下行添加到你的应用 Rakefile 中：

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## 使用方法

运行 Rake 任务 `mermaid_erd` 将生成 `<app_root>/mermaid_erd/index.html`。

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

直接在浏览器中打开生成的 `<app_root>/mermaid_erd/index.html` 即可。

该文件不需要纳入 Git 管理，如有需要可以将其添加到 `.gitignore`

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` 是一个自包含的单 HTML 文件。所有前端依赖（Tailwind、Mermaid、Vue）均已内联，因此在离线环境和严格的企业代理后面也能正常工作——查看时无需访问 CDN。由于捆绑包内嵌其中，文件大小约为 4 MB。

如果你分享此文件，没有 Ruby on Rails 环境的人也可以使用。或者，你可以将文件上传到 Web 服务器，通过同一 URL 进行共享。

使用 CI 自动生成是非常明智的做法。

### 将 Mermaid 源码输出到标准输出

运行 Rake 任务 `mermaid_erd:print`，将原始 `erDiagram` 源码输出到标准输出，而不是生成 HTML 查看器。这可以直接管道传输给其他工具：

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

输出包含完整的图表——所有表、列、键、注释和关联——相当于启用了 HTML 查看器所有详细信息切换后的状态。

## 语言

查看器 UI 支持 12 种语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский 和 العربية（从右到左）。加载时自动检测浏览器语言（`navigator.language`），不支持的语言回退到英语，也可以从右上角的选择器手动切换。

## 支持的版本

每次推送和拉取请求时 CI 验证的 Ruby × Rails 组合：

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

其他组合可能也能运行，但未经验证。

## 配置

通过 `./config/mermaid_erd.yml` 自定义配置。
配置示例请参阅 [./docs/example.yml](./docs/example.yml)。

配置项如下：

| 键 | 说明 | 默认值 |
| --- | --- | --- |
| `result_path` | 生成文件的输出路径。 | `mermaid_erd/index.html` |
| `ignore_tables` | 正则表达式字符串数组。`table_name` 与任意模式匹配的表，连同指向它们的所有关联，都将从生成的 ERD 中排除。适用于排除审计日志模型、软删除/遗留表或其他不想渲染的大量噪声。模式通过 `Regexp.new` 编译，因此在 YAML 字符串中需要转义反斜杠（例如 `"\\Aaudit_"`）。 | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## 许可证
该 gem 以开源形式提供，遵循 [MIT License](https://opensource.org/licenses/MIT) 条款。
