# 🛡️ Governança de Código SQL: Por que usamos o `.sqlfluff`?

O ficheiro `.sqlfluff` localizado na raiz do repositório é o ficheiro central de configuração do **SQLFluff**, o linter e formatador estático adotado para padronizar e validar todo o código SQL dos modelos dbt.

---

## 1. Motivação e Objetivos

Em ambientes analíticos com múltiplos modelos e camadas (Bronze, Silver e Gold), a escrita de SQL sem validação automatizada gera divergências de estilo, inconsistências de legibilidade e falhas de compilação em produção. O SQLFluff atua como o equivalente ao `black`, `flake8` e `isort` do ecossistema Python, assegurando:

* **Padronização Estrita de Estilo:** Força o uso de palavras-chave reservadas em maiúsculas (`SELECT`, `FROM`, `WHERE`), identificadores de colunas em minúsculas e regras estritas de indentação (4 espaços).
* **Prevenção de Regressões no CI/CD:** As esteiras automatizadas de integração contínua (GitHub Actions) validam se o código cumpre os padrões estéticos antes de permitir a fusão (*merge*) de Pull Requests.
* **Leitura Limpa e Rápida:** Reduz o atrito cognitivo em revisões de código (*code reviews*), garantindo que todo o repositório pareça ter sido escrito pelo mesmo profissional.

---

## 2. Decisões Arquiteturais no `.sqlfluff`

### A. Especificação do Dialeto BigQuery

```ini
dialect = bigquery
```

Informa ao motor de análise que o código utiliza particularidades de sintaxe nativas do Google BigQuery (como tipos `NUMERIC`, funções analíticas `ROW_NUMBER() OVER (...)`, comandos de desaninhamento `UNNEST` e tratamentos temporais). Sem esta definição, o linter assumiria SQL genérico (ANSI) e acusaria falsos positivos.

### B. Integração com o Motor de Templates Jinja

```ini
templater = jinja
```

O dbt não compila SQL puro diretamente; os modelos misturam SQL com expressões dinâmicas Jinja (`{{ ... }}` e `{% ... %}`). O templater do Jinja instrui o SQLFluff a resolver as expressões de modelo antes de validar a árvore sintática do BigQuery.

### C. Mocks de Macros dbt (`[sqlfluff:templater:jinja:macros]`)

Ao rodar fora da infraestrutura de compilação do dbt, o SQLFluff não tem visibilidade em tempo de execução das macros locais ou de pacotes como o `dbt-utils`. Se um modelo invocar `{{ ref(...) }}`, `{{ audit_columns() }}` ou `{{ safe_divide(...) }}`, o compilador Jinja geraria uma falha fatal de variável indefinida (`TMP: Undefined jinja template variable`).

Para contornar este comportamento sem acoplar a execução do linter ao banco de dados:

* Criam-se implementações simuladas (*mocks*) leves dentro do `.sqlfluff`.
* Cada macro recebe retornos válidos de SQL (por exemplo, `ref` retorna uma tabela fictícia `dummy_table`, enquanto `audit_columns` retorna a projeção de um *timestamp*).
* Desta forma, o SQLFluff compila uma consulta SQL BigQuery sintaticamente válida e realiza o *lint* sem exigir conexões remotas à nuvem.

---

## 3. Resumo dos Comandos Operacionais

* **Validar conformidade do código:**

  ```bash
  uv run sqlfluff lint pasta_ou_modelo.sql
  ```

* **Aplicar formatação automática:**

  ```bash
  uv run sqlfluff format pasta_ou_modelo.sql
  ```

* **Corrigir violações e regras de capitalização:**

  ```bash
  uv run sqlfluff fix pasta_ou_modelo.sql
  ```