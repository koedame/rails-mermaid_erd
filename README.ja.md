[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> これは [英語版 README](./README.md) の翻訳です。内容に差異がある場合は英語版が正です。

<div align="center">

# Rails Mermaid ERD

**RailsアプリのMermaid ERDを、自己完結した1枚のHTMLファイルとして生成します。**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="主キーと外部キーを持つ5つのモデルが関連線でつながれた、Rails Mermaid ERDのビューア。" src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[デモページ](https://koedame.github.io/rails-mermaid_erd/example.html) · [インストール手順](#インストール手順) · [使い方](#使い方) · [動作確認済みバージョン](#動作確認済みバージョン) · [設定](#設定)

</div>

`rails mermaid_erd` を実行するだけで、Railsのスキーマを自己完結した1枚のHTMLファイルにします。追加のGemやサービスは不要です。Tailwind・Mermaid・Vueが埋め込み済みなので、オフラインでも社内プロキシの内側でも開けます。ブラウザ上で見たいテーブルを選び、Mermaidコード・SVG・PNGとして書き出せます。共有するときは、HTMLファイルを渡すか、Webサーバーに置くだけです。

## ハイライト

- **1ファイルで完結。** Tailwind・Mermaid・Vueを埋め込んだ約4MBのHTML 1枚なので、オフラインでも社内プロキシの内側でも開けます。
- **必要なところだけ描画。** モデルを選び、カラムは全部・キーのみ・なしから選べて、コメントやリレーションのラベルも付けられます。
- **書き出しと共有。** MermaidやMarkdownのコードをコピーし、SVGやPNGをダウンロードし、表示を復元するリンクをコピーできます。
- **幅広いRails対応。** CIはRails 5.2から8.1まで、Ruby 2.7から4.0までを検証しています。
- **12言語。** ブラウザの言語に合わせて表示し、右から左に書くアラビア語にも対応します。

## インストール手順

導入したいRailsアプリケーションのGemfileに以下の行を追加してください。

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

次に、以下のコマンドを実行してGemをインストールします。

```bash
bundle install
```

次に、Rakefileに以下の行を追加してください。

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## 使い方

Rakeタスク `mermaid_erd` を実行すると `<app_root>/mermaid_erd/index.html` が生成されます。

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

生成された `<app_root>/mermaid_erd/index.html` をお使いのブラウザで開くだけです。
このファイルをGit管理から除外したい場合は `.gitignore` に以下の行を追加してください。

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` は自己完結したシングル HTML ファイルです。Tailwind / Mermaid / Vue を含むすべてのフロントエンド依存は HTML 内にインライン展開されているため、CDN への接続が無いオフライン環境や厳格なプロキシ下でも動作します。バンドルが同梱されている都合上、ファイルサイズは約 4 MB 程度になります。

このファイルを共有すれば、Ruby on Rails環境が無くても使用できます。サーバーにアップロードすれば、同じURLを共有することもできます。
生成したファイルには、テーブル名・カラム名・コメントなど、アプリケーションのスキーマがそのまま含まれます。スキーマそのものを公開してよい範囲にだけ共有・配置してください。
CIと連携して生成から共有までを自動化するのはとても有効な手段です。

### Mermaid ソースを標準出力する

Rakeタスク `mermaid_erd:print` を実行すると、HTML ビューアを書き出す代わりに `erDiagram` のソースを標準出力します。他のツールへそのままパイプできます。

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

出力はすべてのテーブル・カラム・キー・コメント・リレーションを含む完全な図で、HTML ビューアの詳細表示トグルをすべて有効にした状態に相当します。

## 対応言語

ビューア UI は 12 言語に対応しています: English / 日本語 / 简体中文 / 繁體中文 / 한국어 / Español / Français / Deutsch / Italiano / Português (Brasil) / Русский / العربية (右から左)。読み込み時にブラウザの言語(`navigator.language`)を自動判定し、未対応の言語は英語にフォールバックします。右上のセレクタから手動で切り替えることもできます。

## 動作確認済みバージョン

push / pull request ごとに CI で検証している Ruby × Rails の組み合わせは以下のとおりです。

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

これ以外の組み合わせでも動作する可能性はありますが、検証対象には含まれていません。

## 設定

`./config/mermaid_erd.yml` を設置することで設定を変更できます。
設定例は [./docs/example.yml](./docs/example.yml) を参照してください。

設定項目は次のとおりです。

| キー | 説明 | 初期値 |
| --- | --- | --- |
| `result_path` | 生成されるファイルのパス。 | `mermaid_erd/index.html` |
| `ignore_tables` | 正規表現文字列の配列。`table_name` がいずれかのパターンに一致するテーブルは、それに紐づく関連線も含めて生成されるERDから除外されます。監査ログ系のモデル・論理削除済み/レガシーなテーブル・ノイズが多くて描画したくないテーブルを除外したい場合に有用です。パターンは `Regexp.new` でコンパイルされるため、YAML文字列内ではバックスラッシュをエスケープしてください(例: `"\\Aaudit_"`)。 | `[]` |
| `viewer_defaults` | URL に保存済みの状態が無いときにビューアが最初に開く表示と、**リセット**で戻る表示。状態を持つリンクは常にそちらが優先されます。`models`: 最初に選択しておくモデル名の配列(ERD に無い名前は、ファイル生成時に警告を出して無視されます)。`columns`: `all` / `keys`(主キーと外部キーのみ)/ `none`。サイドバーの「カラム」と同じ選択肢です。大きなアプリで、いつも最初に見るモデルから開きたいときに使います。 | `models: []`(何も選択しない)、`columns: all` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## 商標

このプロジェクトは、Rails、The Rails Foundation、Mermaid プロジェクト、Mermaid Chart Inc. と提携しておらず、これらの公認・後援も受けていません。Rails と Ruby on Rails は David Heinemeier Hansson の登録商標です。Mermaid Chart Inc. は、米国で MERMAID CHART と MERMAID の商標を登録または出願しています。そのほかの商標は、それぞれの権利者に帰属します。

## ライセンス

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
