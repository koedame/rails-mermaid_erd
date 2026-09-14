[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> 이 문서는 [영어 README](./README.md)의 번역본입니다. 내용이 다를 경우 영어판이 기준입니다.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Ruby on Rails 애플리케이션에서 [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram)를 생성합니다.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[데모 페이지](https://koedame.github.io/rails-mermaid_erd/example.html)

Mermaid ERD를 자유롭게 생성할 수 있습니다.
생성된 ERD는 Markdown 형식으로 복사할 수 있어 GitHub에서 쉽게 공유할 수 있습니다.
이미지로 저장할 수도 있어 Mermaid를 사용할 수 없는 환경에서도 활용 가능합니다.
에디터는 단일 HTML 파일이므로 에디터 자체를 공유할 수도 있습니다.

## 설치

애플리케이션의 Gemfile에 다음 줄을 추가하세요:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

그런 다음 실행하세요:

```bash
$ bundle install
```

애플리케이션의 Rakefile에 다음 줄을 추가하세요:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## 사용 방법

Rake 태스크 `mermaid_erd`를 실행하면 `<app_root>/mermaid_erd/index.html`이 생성됩니다.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

생성된 `<app_root>/mermaid_erd/index.html`을 브라우저에서 열기만 하면 됩니다.

이 파일은 Git 관리가 필요하지 않으므로 필요한 경우 `.gitignore`에 추가할 수 있습니다.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html`은 자체 포함된 단일 HTML 파일입니다. 모든 프론트엔드 의존성(Tailwind, Mermaid, Vue)이 인라인으로 포함되어 있어 오프라인 환경과 엄격한 기업 프록시 뒤에서도 동작합니다——열람 시 CDN 접근이 필요하지 않습니다. 번들이 파일 내에 포함되어 있어 파일 크기는 약 4 MB입니다.

이 파일을 공유하면 Ruby on Rails 환경이 없는 사람도 사용할 수 있습니다. 또는 파일을 웹 서버에 업로드하여 동일한 URL로 공유할 수도 있습니다.

CI를 사용하여 자동으로 생성하는 것이 매우 효율적입니다.

### Mermaid 소스를 표준 출력으로 출력

Rake 태스크 `mermaid_erd:print`를 실행하면 HTML 뷰어를 생성하는 대신 원시 `erDiagram` 소스를 표준 출력으로 인쇄합니다. 다른 도구로 바로 파이프할 수 있습니다:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

출력은 모든 테이블, 컬럼, 키, 주석, 관계를 포함한 완전한 다이어그램으로, HTML 뷰어의 모든 세부 정보 토글을 활성화한 상태와 동일합니다.

## 언어

뷰어 UI는 12개 언어를 지원합니다: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский, 그리고 العربية(오른쪽에서 왼쪽). 로드 시 브라우저 언어(`navigator.language`)를 자동으로 감지하고, 지원되지 않는 언어의 경우 영어로 대체되며, 오른쪽 상단의 선택기에서 수동으로 전환할 수도 있습니다.

## 지원 버전

모든 푸시 및 풀 리퀘스트마다 CI에서 검증하는 Ruby × Rails 조합:

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

다른 조합도 작동할 수 있지만 검증되지 않았습니다.

## 설정

`./config/mermaid_erd.yml`로 설정을 사용자 정의할 수 있습니다.
설정 예시는 [./docs/example.yml](./docs/example.yml)을 참고하세요.

설정 항목은 다음과 같습니다:

| 키 | 설명 | 기본값 |
| --- | --- | --- |
| `result_path` | 생성된 파일의 저장 경로. | `mermaid_erd/index.html` |
| `ignore_tables` | 정규식 문자열의 배열. `table_name`이 패턴 중 하나와 일치하는 테이블은 해당 테이블을 가리키는 모든 관계와 함께 생성된 ERD에서 제외됩니다. 감사 로그 모델, 소프트 삭제/레거시 테이블, 또는 렌더링하고 싶지 않은 대량의 노이즈를 제외하는 데 유용합니다. 패턴은 `Regexp.new`로 컴파일되므로 YAML 문자열 내에서 백슬래시를 이스케이프해야 합니다(예: `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## 라이선스
이 gem은 [MIT License](https://opensource.org/licenses/MIT) 조건에 따라 오픈 소스로 제공됩니다.
