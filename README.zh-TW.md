[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> 本文件是 [英文 README](./README.md) 的翻譯版本。如有差異，以英文版為準。

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

從你的 Ruby on Rails 應用程式產生 [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram)。

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[示範頁面](https://koedame.github.io/rails-mermaid_erd/example.html)

可以隨時產生 Mermaid ERD。
產生的 ERD 可以以 Markdown 格式複製，因此可以輕鬆在 GitHub 上分享。
也可以儲存為圖片，在不支援 Mermaid 的環境中也能使用。
編輯器是單一 HTML 檔案，因此可以直接共享整個編輯器。

## 安裝

將以下行加入你的應用程式 Gemfile 中：

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

然後執行：

```bash
$ bundle install
```

將以下行加入你的應用程式 Rakefile 中：

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## 使用方式

執行 Rake 任務 `mermaid_erd` 將會產生 `<app_root>/mermaid_erd/index.html`。

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

直接在瀏覽器中開啟產生的 `<app_root>/mermaid_erd/index.html` 即可。

此檔案不需要納入 Git 管理，如有需要可以將其加入 `.gitignore`

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` 是一個自包含的單一 HTML 檔案。所有前端相依套件（Tailwind、Mermaid、Vue）均已內嵌，因此在離線環境和嚴格的企業代理後面也能正常運作——檢視時無需存取 CDN。由於套件組合內嵌其中，檔案大小約為 4 MB。

如果你分享此檔案，沒有 Ruby on Rails 環境的人也可以使用。或者，你可以將檔案上傳到 Web 伺服器，透過相同 URL 進行共享。

使用 CI 自動產生是非常明智的做法。

### 將 Mermaid 原始碼輸出到標準輸出

執行 Rake 任務 `mermaid_erd:print`，將原始 `erDiagram` 原始碼輸出到標準輸出，而不是產生 HTML 查看器。這可以直接管道傳輸給其他工具：

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2               |
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

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## 授權條款
該 gem 以開源形式提供，遵循 [MIT License](https://opensource.org/licenses/MIT) 條款。
