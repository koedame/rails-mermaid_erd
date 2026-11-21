[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

> Esta é uma tradução do [README em inglês](./README.md). Em caso de divergências, a versão em inglês prevalece.

<div align="center">

# Rails Mermaid ERD

**Gere um ERD Mermaid interativo da sua aplicação Rails como um único arquivo HTML autocontido.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="O visualizador do Rails Mermaid ERD mostrando cinco modelos com suas chaves primárias e estrangeiras, ligados por linhas de relacionamento." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[Página de Demonstração](https://koedame.github.io/rails-mermaid_erd/example.html) · [Instalação](#instalação) · [Uso](#uso) · [Versões suportadas](#versões-suportadas) · [Configuração](#configuração)

</div>

Execute `rails mermaid_erd` e obtenha um único arquivo HTML autocontido com o esquema da sua aplicação Rails, sem gems ou serviços adicionais. Tailwind, Mermaid e Vue já vêm embutidos, então ele abre offline e atrás de um proxy corporativo. No navegador, escolha as tabelas que quiser e exporte-as como código Mermaid, SVG ou PNG; para compartilhar, basta enviar o arquivo HTML ou colocá-lo em um servidor web.

## Destaques

- **Um único arquivo, nada mais para instalar.** A saída é um único arquivo HTML de cerca de 4 MB com Tailwind, Mermaid e Vue embutidos, então ele abre offline e atrás de um proxy corporativo.
- **Desenhe só o que você precisa.** Selecione modelos, mostre todas as colunas, só as chaves ou nenhuma, e adicione comentários e rótulos de relacionamento.
- **Exporte e compartilhe.** Copie o código Mermaid ou Markdown, baixe SVG ou PNG, ou copie um link que restaura a sua visualização.
- **Ampla compatibilidade com Rails.** O CI cobre do Rails 5.2 ao 8.1 com Ruby 2.7 a 4.0.
- **12 idiomas.** O visualizador segue o idioma do navegador, incluindo o árabe, escrito da direita para a esquerda.

## Instalação

Adicione esta linha ao Gemfile da sua aplicação:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

Em seguida, execute:

```bash
bundle install
```

Adicione isto ao Rakefile da sua aplicação, **antes** de `Rails.application.load_tasks` (a tarefa é registrada quando as tarefas são carregadas, então um `require` depois dessa linha deixa `rails mermaid_erd` não reconhecido):

```ruby
require_relative "config/application"

begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end

Rails.application.load_tasks
```

## Uso

Executar o rake task `mermaid_erd` irá gerar `<app_root>/mermaid_erd/index.html`.

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

Basta abrir o arquivo gerado `<app_root>/mermaid_erd/index.html` no seu navegador.

Este arquivo não é necessário para o gerenciamento do Git, portanto você pode adicioná-lo ao `.gitignore` se quiser.

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` é um único arquivo HTML autocontido. Todas as dependências front-end (Tailwind, Mermaid, Vue) estão embutidas inline, portanto funciona offline e atrás de proxies corporativos restritivos — sem necessidade de acesso a CDN no momento da visualização. O arquivo tem aproximadamente 4 MB porque os bundles estão incluídos nele.

Se você compartilhar este arquivo, ele poderá ser usado por quem não tem um ambiente Ruby on Rails. Você também pode fazer o upload para um servidor web e compartilhá-lo com a mesma URL.

O arquivo gerado contém o esquema da sua aplicação, incluindo nomes de tabelas e colunas e comentários. Compartilhe-o ou hospede-o apenas com o mesmo alcance com que compartilharia o próprio esquema.

Seria muito eficiente gerá-lo automaticamente usando CI.

### Imprimir a fonte Mermaid na saída padrão

Execute o rake task `mermaid_erd:print` para imprimir a fonte `erDiagram` bruta na saída padrão em vez de escrever o visualizador HTML. Isso se integra perfeitamente a outras ferramentas via pipe:

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
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
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
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
| `viewer_defaults` | Visualização com que o visualizador abre quando a URL não traz um estado salvo, e para a qual **Redefinir** volta; um link com estado próprio sempre tem prioridade. `models`: array com os nomes dos modelos selecionados no início (um nome que não está no ERD é ignorado com um aviso ao gerar o arquivo). `columns`: `all`, `keys` (somente chaves primárias e estrangeiras) ou `none`, as mesmas opções de "Colunas" na barra lateral. Útil para abrir um aplicativo grande nos modelos por onde se costuma começar. | `models: []` (nada selecionado), `columns: all` |

## Marcas registradas

Este projeto não é afiliado a Rails, à The Rails Foundation, ao projeto Mermaid nem à Mermaid Chart Inc., e não é endossado nem patrocinado por eles. Rails e Ruby on Rails são marcas registradas de David Heinemeier Hansson. A Mermaid Chart Inc. registrou ou solicitou o registro das marcas MERMAID CHART e MERMAID nos Estados Unidos. As demais marcas pertencem aos seus respectivos proprietários.

## Licença

A gem está disponível como open source nos termos da [Licença MIT](https://opensource.org/licenses/MIT).
