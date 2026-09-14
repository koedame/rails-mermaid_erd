[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Esta é uma tradução do [README em inglês](./README.md). Em caso de divergências, a versão em inglês prevalece.

# Rails Mermaid ERD

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://badge.fury.io/rb/rails-mermaid_erd.svg)](https://rubygems.org/gems/rails-mermaid_erd)

Gere um [Mermaid ERD](https://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram) a partir da sua aplicação Ruby on Rails.

[<img src="./docs/screen_shot.png" width="50%">](./docs/screen_shot.png)

[Página de Demonstração](https://koedame.github.io/rails-mermaid_erd/example.html)

O ERD pode ser gerado a qualquer momento.
O ERD gerado pode ser copiado no formato Markdown, facilitando o compartilhamento no GitHub.
Também pode ser salvo como imagem, sendo utilizável em ambientes onde o Mermaid não está disponível.
O editor é um único arquivo HTML, portanto o editor completo pode ser compartilhado.

## Instalação

Adicione esta linha ao Gemfile da sua aplicação:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Em seguida, execute:

```bash
$ bundle install
```

Adicione esta linha ao Rakefile da sua aplicação:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Uso

Executar o rake task `mermaid_erd` irá gerar `<app_root>/mermaid_erd/index.html`.

```bash
$ bundle exec rails mermaid_erd
# or
$ bundle exec rake mermaid_erd
```

Basta abrir o arquivo gerado `<app_root>/mermaid_erd/index.html` no seu navegador.

Este arquivo não é necessário para o gerenciamento do Git, portanto você pode adicioná-lo ao `.gitignore` se quiser.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` é um único arquivo HTML autocontido. Todas as dependências front-end (Tailwind, Mermaid, Vue) estão embutidas inline, portanto funciona offline e atrás de proxies corporativos restritivos — sem necessidade de acesso a CDN no momento da visualização. O arquivo tem aproximadamente 4 MB porque os bundles estão incluídos nele.

Se você compartilhar este arquivo, ele poderá ser usado por quem não tem um ambiente Ruby on Rails. Você também pode fazer o upload para um servidor web e compartilhá-lo com a mesma URL.

Seria muito eficiente gerá-lo automaticamente usando CI.

### Imprimir a fonte Mermaid na saída padrão

Execute o rake task `mermaid_erd:print` para imprimir a fonte `erDiagram` bruta na saída padrão em vez de escrever o visualizador HTML. Isso se integra perfeitamente a outras ferramentas via pipe:

```bash
$ bundle exec rails mermaid_erd:print
$ bundle exec rails mermaid_erd:print > er.mmd
$ bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

A saída é o diagrama completo — cada tabela, coluna, chave, comentário e relação — equivalente ao visualizador HTML com todos os toggles de detalhe ativados.

## Idiomas

A interface do visualizador está disponível em 12 idiomas: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский e العربية (da direita para a esquerda). Detecta automaticamente o idioma do navegador (`navigator.language`) ao carregar, volta para o inglês em locais não suportados e pode ser trocado manualmente pelo seletor no canto superior direito.

## Versões suportadas

As combinações Ruby × Rails verificadas pela CI a cada push e pull request:

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

Outras combinações podem funcionar, mas não são verificadas.

## Configuração

Use `./config/mermaid_erd.yml` para personalizar a configuração.
Veja [./docs/example.yml](./docs/example.yml) para um exemplo de configuração.

As opções disponíveis são as seguintes.

| chave | descrição | padrão |
| --- | --- | --- |
| `result_path` | Destino dos arquivos gerados. | `mermaid_erd/index.html` |
| `ignore_tables` | Array de strings de expressões regulares. Tabelas cujo `table_name` corresponda a qualquer padrão são removidas do ERD gerado, junto com quaisquer relações que apontem para elas. Útil para excluir modelos de log de auditoria, tabelas com exclusão lógica/legadas ou outro ruído indesejado no diagrama. Os padrões são compilados com `Regexp.new`, portanto escape as barras invertidas dentro de strings YAML (ex.: `"\\Aaudit_"`). | `[]` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Licença

A gem está disponível como open source nos termos da [Licença MIT](https://opensource.org/licenses/MIT).
