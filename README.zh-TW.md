[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> 本文件是 [英文 README](./README.md) 的翻譯版本。如有差異，以英文版為準。

<div align="center">

# Rails Mermaid ERD

**將你的 Rails 應用程式產生為單一自包含 HTML 檔案形式的互動式 Mermaid ERD。**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="Rails Mermaid ERD 檢視器，顯示五個帶有主鍵與外鍵的模型，並以關聯線連接。" src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[示範頁面](https://koedame.github.io/rails-mermaid_erd/example.html) · [安裝](#安裝) · [使用方式](#使用方式) · [支援的版本](#支援的版本) · [設定](#設定)

</div>

執行 `rails mermaid_erd`，即可將你的 Rails 資料庫結構產生為單一、自包含的 HTML 檔案，不需要額外的 gem 或服務。Tailwind、Mermaid 與 Vue 都已內嵌其中，因此可以離線開啟，在企業 Proxy 內也能正常使用。在瀏覽器中選擇需要的資料表，即可匯出為 Mermaid 程式碼、SVG 或 PNG；分享時只需傳送該 HTML 檔案，或放到 Web 伺服器上。

## 亮點

- **一個檔案，不需另外安裝。** 輸出是約 4 MB 的單一 HTML 檔案，內嵌了 Tailwind、Mermaid 與 Vue，因此可以離線開啟，在企業 Proxy 內也能使用。
- **只畫你需要的部分。** 可選擇模型，顯示全部欄位、僅鍵或不顯示欄位，也可加入註解與關聯標籤。
- **匯出與分享。** 可複製 Mermaid 或 Markdown 程式碼，下載 SVG 或 PNG，也可複製能還原目前檢視的連結。
- **廣泛支援 Rails。** CI 涵蓋 Rails 5.2 到 8.1，以及 Ruby 2.7 到 4.0。
- **12 種語言。** 檢視器會依瀏覽器語言顯示，並支援由右至左書寫的阿拉伯文。

## 安裝

將以下行加入你的應用程式 Gemfile 中：

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

然後執行：

```bash
bundle install
```

將以下行加入你的應用程式 Rakefile 中：

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

必須放在 `Rails.application.load_tasks` **之前**。任務在 `load_tasks` 執行期間註冊，如果寫在它之後（例如檔案末尾），會因 `Unrecognized command "mermaid_erd"` 而失敗。

## 使用方式

執行 Rake 任務 `mermaid_erd` 將會產生 `<app_root>/mermaid_erd/index.html`。

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

直接在瀏覽器中開啟產生的 `<app_root>/mermaid_erd/index.html` 即可。

此檔案不需要納入 Git 管理，如有需要可以將其加入 `.gitignore`

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` 是一個自包含的單一 HTML 檔案。所有前端相依套件（Tailwind、Mermaid、Vue）均已內嵌，因此在離線環境和嚴格的企業代理後面也能正常運作——檢視時無需存取 CDN。由於套件組合內嵌其中，檔案大小約為 4 MB。

如果你分享此檔案，沒有 Ruby on Rails 環境的人也可以使用。或者，你可以將檔案上傳到 Web 伺服器，透過相同 URL 進行共享。

產生的檔案包含應用程式的 schema，包括資料表名稱、欄位名稱與註解。請僅在可以公開 schema 本身的範圍內分享或託管它。

使用 CI 自動產生是非常明智的做法。

### 將 Mermaid 原始碼輸出到標準輸出

執行 Rake 任務 `mermaid_erd:print`，將原始 `erDiagram` 原始碼輸出到標準輸出，而不是產生 HTML 查看器。這可以直接管道傳輸給其他工具：

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

輸出包含完整的圖表——所有資料表、欄位、鍵、註解和關聯——相當於啟用了 HTML 查看器所有詳細資訊切換後的狀態。

## 語言

查看器 UI 支援 12 種語言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский 和 العربية（由右至左）。載入時自動偵測瀏覽器語言（`navigator.language`），不支援的語言退回英語，也可以從右上角的選擇器手動切換。

## 支援的版本

每次推送和拉取請求時 CI 驗證的 Ruby × Rails 組合：

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

其他組合可能也能運行，但未經驗證。

## 設定

透過 `./config/mermaid_erd.yml` 自訂設定。
設定範例請參閱 [./docs/example.yml](./docs/example.yml)。

設定項目如下：

| 鍵 | 說明 | 預設值 |
| --- | --- | --- |
| `result_path` | 產生檔案的輸出路徑。 | `mermaid_erd/index.html` |
| `ignore_tables` | 正規表示式字串陣列。`table_name` 與任意模式相符的資料表，連同指向它們的所有關聯，都將從產生的 ERD 中排除。適用於排除稽核日誌模型、軟刪除/舊版資料表或其他不想渲染的大量雜訊。模式透過 `Regexp.new` 編譯，因此在 YAML 字串中需要跳脫反斜線（例如 `"\\Aaudit_"`）。 | `[]` |
| `viewer_defaults` | URL 中沒有已儲存狀態時檢視器開啟的初始檢視，也是按下**重設**後回到的檢視；帶有自身狀態的連結一律優先。`models`：初始選取的模型名稱陣列（不在 ERD 中的名稱會在產生檔案時顯示警告並被忽略）。`columns`：`all` / `keys`（僅主鍵與外鍵）/ `none`，與側邊欄「欄位」的選項相同。適合在大型應用程式中從常用的模型開始檢視。 | `models: []`（不選取任何模型），`columns: all` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## 商標

本專案與 Rails、The Rails Foundation、Mermaid 專案、Mermaid Chart Inc. 均無關聯，也未獲得它們的認可或贊助。Rails 與 Ruby on Rails 是 David Heinemeier Hansson 的註冊商標。Mermaid Chart Inc. 已在美國註冊或申請註冊 MERMAID CHART 與 MERMAID 商標。其他商標歸各自權利人所有。

## 授權條款
該 gem 以開源形式提供，遵循 [MIT License](https://opensource.org/licenses/MIT) 條款。
