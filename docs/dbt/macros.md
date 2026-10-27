# 🧩 Macros Customizadas e Funções Auxiliares

Este diretório centraliza as macros Jinja utilitárias e regras reutilizáveis do projeto dbt, padronizando a geração de metadados, lógica incremental e integridade referencial.

---

## 1. Geração de Chaves Substitutas (Surrogate Keys)

### `generate_surrogate_key` (Wrapper do `dbt-utils`)
* **Arquivo:** `macros/surrogate_key.sql`
* **Dependência Externa:** Pacote [`dbt-labs/dbt_utils`](https://github.com/dbt-labs/dbt-utils) (`packages.yml`).
* **Objetivo:** Gerar uma chave substituta determinística e única (hash MD5) a partir de uma ou mais colunas de negócio, tratando valores nulos e delimitadores para prevenir colisões.

#### 💡 Decisão de Arquitetura: Por que criar um *Wrapper*?
Em vez de chamar `{{ dbt_utils.generate_surrogate_key(...) }}` diretamente em dezenas de modelos SQL, criamos uma macro intermediária local (`generate_surrogate_key`):
1. **Desacoplamento de Pacote:** Se no futuro a equipe optar por substituir a implementação do hash (ex.: migrar para funções nativas do BigQuery como `FARM_FINGERPRINT` ou `SHA256` para redução de custos/performance), basta alterar a implementação **em um único arquivo** (`macros/surrogate_key.sql`), sem necessidade de refatorar todos os modelos SQL das camadas Silver e Gold.
2. **Sintaxe Limpa e Padronizada:** Simplifica a chamada no código SQL, eliminando o prefixo do pacote externo.

#### Assinatura da Macro:
```jinja
{% macro generate_surrogate_key(field_list) %}
    {{ dbt_utils.generate_surrogate_key(field_list) }}
{% endmacro %}

```
---
## 2. Auditoria e Rastreabilidade Técnica

### `audit_columns`
* **Arquivo:** `macros/audit_columns.sql`
* **Dependência Externa:** Nenhuma (utiliza funções nativas do BigQuery e variáveis de contexto do Jinja/dbt).
* **Objetivo:** Injetar automaticamente colunas técnicas padronizadas de governança em tabelas e visões para monitorar o momento da carga e correlacionar registros diretamente com as execuções do orquestrador.

#### 💡 Decisão de Arquitetura: Por que padronizar colunas de auditoria?
A rastreabilidade é um pilar indispensável para resolução de incidentes e conformidade em ambientes de dados corporativos:
1. **Rastreabilidade de Incidentes (`_dbt_invocation_id`):** O identificador único da execução (`invocation_id`) emitido pelo dbt vincula cada linha da tabela ao log exato, run agendada ou job do dbt Cloud. Caso ocorra uma inconsistência ou falha silenciosa, a engenharia consegue cruzar o ID gravado no BigQuery diretamente com os artefatos da esteira.
2. **Controle de Freshness e SLAs (`_dbt_processed_at`):** Registra o timestamp pontual em que a query foi executada pelo BigQuery. Isso permite monitorar atrasos de processamento, validar janelas incrementais e calcular a latência real dos dados entregues para as ferramentas de consumo.
3. **Reutilização e DRY (*Don't Repeat Yourself*):** Evita que cada desenvolvedor crie nomes arbitrários (como `dt_insercao`, `created_at`, `timestamp_carga`), assegurando que todas as camadas analíticas compartilhem rigorosamente a mesma convenção de nomes e formatos de auditoria técnica.

#### Assinatura da Macro:
```jinja
{% macro audit_columns() -%}
    current_timestamp() as _dbt_processed_at,
    '{{ invocation_id }}' as _dbt_invocation_id
{%- endmacro %}
```
---

## 3. Tratamento Seguro de Divisões em Métricas e Fatos

### `safe_divide` (Wrapper com Dispatcher do `dbt-utils`)
* **Arquivo:** `macros/safe_divide.sql`
* **Dependência Externa:** Pacote [`dbt-labs/dbt_utils`](https://github.com/dbt-labs/dbt-utils) (`packages.yml`).
* **Objetivo:** Prevenir interrupções críticas no pipeline de dados decorrentes de erros de divisão por zero (*division by zero*) ou valores nulos, convertendo denominadores zerados em `NULL` de forma segura.

#### 💡 Decisão de Arquitetura: Por que implementar o padrão de Dispatch?
A utilização do adaptador dinâmico (`adapter.dispatch`) para encapsular o cálculo matemático oferece garantias essenciais de portabilidade e robustez analítica:
1. **Resiliência de Pipeline:** Em cálculos de métricas agregadas na camada Gold/Fato (ex.: ticket médio, margens percentuais, taxa de conversão), a ocorrência de denominadores iguais a zero ou nulos causa o aborto imediato da query no BigQuery. A macro assegura a substituição graciosa por `NULL` via `nullif()`, permitindo que o processamento continue sem falhas.
2. **Portabilidade Multi-Engine (`adapter.dispatch`):** Ao estruturar a macro com despacho por adaptador, o código respeita automaticamente a implementação ideal do motor subjacente (ex.: utilizando a função nativa `SAFE_DIVIDE()` no BigQuery ou a expressão de fallback `numerator / nullif(denominator, 0)` em outros targets como Postgres/Snowflake), sem a necessidade de reescrever os modelos de negócio.
3. **Isolamento de Sintaxe Complexa:** Evita a repetição manual de cláusulas extensas de `CASE WHEN` ou múltiplos `NULLIF` dentro dos modelos SQL, mantendo as expressões de KPIs limpas, legíveis e fáceis de auditar.

#### Assinatura da Macro:
```jinja
{% macro safe_divide(numerator, denominator) -%}
  {{ return(adapter.dispatch('safe_divide', 'dbt_utils')(numerator, denominator)) }}
{%- endmacro %}

{% macro default__safe_divide(numerator, denominator) %}
    ( {{ numerator }} ) / nullif( ( {{ denominator }} ), 0)
{% endmacro %}
```
---
## 4. Categorização Padronizada de Descontos e Acréscimos

### `classify_discount`
* **Arquivo:** `macros/classify_discount.sql`
* **Dependência Externa:** Nenhuma (SQL padrão encapsulado via Jinja).
* **Objetivo:** Classificar operações financeiras e de vendas comparando o valor de tabela com o valor efetivamente pago, categorizando o resultado em `com_acrescimo`, `com_desconto`, `sem_desconto` ou `NULL` para entradas ausentes.

#### 💡 Decisão de Arquitetura: Por que centralizar a regra de negócio em uma macro?
A categorização de preços e descontos é uma regra de negócio analítica transversal que impacta relatórios comerciais, análise de margem e auditorias financeiras:
1. **Consistência em Toda a Camada Analítica:** Em vez de replicar instruções `CASE WHEN` com nomenclaturas manuais (onde um analista poderia escrever `'com desconto'` com espaço, outro `'desconto'`, e outro `'discount'`), a macro padroniza rótulos determinísticos em snake_case (`com_desconto`, `com_acrescimo`, `sem_desconto`).
2. **Tratamento Seguro de Nulos (*Null-Handling*):** A macro avalia explicitamente se `valor_tabela` ou `valor_pago` são nulos antes de efetuar comparações lógicas, evitando comportamentos imprevistos ou classificações incorretas provocadas por valores ausentes.
3. **Facilidade de Manutenção e Evolução:** Se no futuro a regra de negócio passar a tolerar uma margem de arredondamento (por exemplo, diferenças inferiores a R$ 0,05 serem tratadas como `sem_desconto`) ou adicionar novas faixas (como `'desconto_excessivo'`), a alteração é feita em um único ponto centralizado sem necessidade de refatorar múltiplos modelos SQL.

#### Assinatura da Macro:
```jinja
{% macro classify_discount(valor_tabela, valor_pago) -%}
      case 
        when {{ valor_tabela }} is null then null
        when {{ valor_pago  }} is null then null
        when {{ valor_pago }} > {{ valor_tabela }} then 'com_acrescimo'
        when {{ valor_tabela }} > {{ valor_pago }} then 'com_desconto'
        else 'sem_desconto'
      end 
{%- endmacro %}
```
---

## 5. Geração de Série Temporal Contínua (Date Spine)

### `date_spine` (Wrapper do `dbt-utils`)
* **Arquivo:** `macros/date_spine.sql`
* **Dependência Externa:** Pacote [`dbt-labs/dbt_utils`](https://github.com/dbt-labs/dbt-utils) (`packages.yml`).
* **Objetivo:** Gerar programaticamente uma sequência ininterrupta de datas ou intervalos de tempo entre dois limites estabelecidos, servindo como base canônica para modelagem dimensional de calendário e preenchimento de lacunas temporais (*zero-filling*).

#### 💡 Decisão de Arquitetura: Por que utilizar o Date Spine?
Em modelos dimensionais analíticos (especialmente na dimensão tempo `dim_calendario` e em métricas de séries temporais), a ausência de registros em determinados dias pode distorcer métricas contínuas:
1. **Eliminação de Dias Vazios (*Gaps* Temporais):** Em dados transacionais brutos, dias sem vendas, transações ou atendimentos simplesmente não existem no banco de dados. Ao cruzar fatos com uma espinha temporal (`LEFT JOIN` a partir do `date_spine`), assegura-se que dias sem atividade apareçam nos relatórios com valor zerado em vez de desaparecerem do gráfico.
2. **Construção Ágil da `dim_calendario`:** Evita a manutenção manual de planilhas CSV com calendários estáticos ou queries recursivas complexas no BigQuery (`GENERATE_DATE_ARRAY`), automatizando a geração de calendários dinâmicos que se expandem conforme o intervalo parametrizado.
3. **Desacoplamento do Pacote Externo:** Assim como na macro `generate_surrogate_key`, o encapsulamento do `dbt_utils.date_spine` em um wrapper local padroniza a interface no projeto e isola dependências diretas de bibliotecas externas dentro da pasta de macros.

#### Assinatura da Macro:
```jinja
{% macro date_spine(datepart, start_date, end_date) %}
    {{ dbt_utils.date_spine(datepart = datepart, start_date = start_date, end_date = end_date) }}
{%- endmacro %}
```
---
## 6. Padronização Estrita de Nomes de Esquemas (Datasets)

### `generate_schema_name`
* **Arquivo:** `macros/generate_schema_name.sql`
* **Dependência Externa:** Nenhuma (sobrescreve a macro interna do dbt Core).
* **Objetivo:** Forçar o dbt a utilizar rigorosamente o nome de schema atribuído nos modelos (`+schema:`), eliminando o comportamento nativo de concatenação (`<target_schema>_<custom_schema>`).

#### 💡 Decisão de Arquitetura: Por que sobrescrever o comportamento padrão?
1. **Nomenclatura Limpa e Previsível:** O comportamento padrão do dbt junta o schema do perfil com o da pasta (ex.: `03_dbt_gold_02_dbt_silver`). Sobrescrever a macro garante datasets limpos e autoexplicativos no BigQuery (`01_dbt_bronze`, `02_dbt_silver`, `03_dbt_gold`).
2. **Compatibilidade com Arquitetura Multi-Projeto:** Em ambientes com separação física por projetos GCP (`meu-projeto-dev` e `meu-projeto-prod`), essa macro assegura que ambos os ambientes espelhem exatamente a mesma estrutura de datasets, mantendo o isolamento garantido no nível de projeto de nuvem.

#### Assinatura da Macro:
```jinja
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```
---

## 7. Estratégia de Carga Incremental e Marca D'Água (Watermark)

### 7.1 `modification_timestamp_expr`
* **Arquivo:** `macros/incremental_filter.sql`
* **Dependência Externa:** Nenhuma (funções nativas SQL: `GREATEST`, `COALESCE` e `TIMESTAMP`).
* **Objetivo:** Computar de forma segura o timestamp do evento mais recente de cada registro, resolvendo a precedência temporal entre a data de criação/inserção e a data da última alteração.

#### 💡 Decisão de Arquitetura: Por que usar `GREATEST` com valor sentinela?
Em bancos transacionais, uma linha recém-criada frequentemente possui a coluna de atualização preenchida como `NULL`. No SQL padrão:
1. **Proteção contra Nulos:** A função `GREATEST(a, b)` retorna `NULL` se qualquer um dos argumentos for nulo. Ao aplicar `coalesce(col, timestamp('1900-01-01 00:00:00'))`, utiliza-se uma data sentinela neutra para garantir que a coluna com valor válido prevaleça.
2. **Determinismo Temporal:** Garante uma coluna única e confiável (frequentemente nomeada como `ultima_modificacao_at`) para orientar tanto a ordenação de deduplicação quanto o corte de janelas incrementais.

#### Assinatura da Macro:
```jinja
{% macro modification_timestamp_expr(inclusion_col='data_inclusao', update_col='data_atualizacao') -%}
    greatest(
        coalesce({{ inclusion_col }}, timestamp('1900-01-01 00:00:00')),
        coalesce({{ update_col }}, timestamp('1900-01-01 00:00:00'))
    )
{%- endmacro %}
```
--- 

## 8. Padronização e Limpeza de Strings (Sanitização Textual)

* **Arquivo:** `macros/normalize_text.sql`
* **Dependência Externa:** Nenhuma (utiliza funções nativas de manipulação de texto do BigQuery: `TRIM`, `CAST`, `NULLIF`, `REGEXP_REPLACE`, `UPPER` e `NORMALIZE`).
* **Objetivo Geral:** Centralizar a higienização de colunas textuais na camada de staging e preparação, tratando inconsistências comuns de entrada como múltiplos espaços em branco, strings vazias, diferenças de maiúsculas/minúsculas e acentuação gráfica.

---

### Código Integral do Módulo (`macros/normalize_text.sql`):
```jinja
{# trim espaços e converte string vazia pra null #}
{% macro normalize_text(column_name)-%}
    nullif(
        trim(
            regexp_replace(cast({{ column_name }} as string), r'\s+', ' ')
        ),
        ''
    )  
{%- endmacro %}

{# trim simples #}
{% macro safe_trim(column_name) -%}
    nullif(trim(cast({{ column_name }} as string)), '')
{%- endmacro %}

{# converte pra maiusculas #}
{% macro normalize_upper(column_name) -%}
    upper({{ normalize_text(column_name) }})
{%- endmacro %}

{# Tira acentos #}
{% macro tira_acentos(column_name) -%}
    regexp_replace(normalize({{ column_name }}, NFD), r'\pM', '')
{%- endmacro %}
```
---
## 9. Cálculo de Variação Percentual (Growth / Percentage Change)

### `percentage_change`
- **Arquivo:** `macros/percentage_change.sql`
- **Dependência Externa:** Depende da macro interna `safe_divide`.
- **Objetivo:** Calcular a taxa relativa de crescimento ou queda percentual entre dois valores ou períodos analíticos ($\frac{V_{\text{atual}} - V_{\text{anterior}}}{V_{\text{anterior}}}$), protegendo o pipeline contra erros de divisão por zero ou denominadores nulos.

#### 💡 Decisão de Arquitetura: Por que compor com `safe_divide` e parênteses explícitos?
O cálculo de taxas de variação temporal (como MoM - *Month over Month* ou YoY - *Year over Year*) é suscetível a exceções matemáticas e regras de precedência de operadores:
1. **Proteção Resiliente Contra Falhas:** Em cenários onde uma métrica no período anterior foi zero (ex.: uma nova loja que faturou R$ 0 no mês anterior ou cliente estreante), uma divisão convencional gera erro fatal de execução (*division by zero*). Ao reaproveitar a macro `safe_divide`, a operação retorna `NULL` graciosamente.
2. **Precedência Matemática com Parênteses Explícitos:** A concatenação via Jinja envolve a subtração obrigatoriamente entre parênteses: `"(" ~ current_value ~ " - " ~ previous_value ~ ")"`. Isso garante que a diferença seja calculada antes da divisão no BigQuery, prevenindo ambiguidade na ordem dos operadores ao compilar o SQL.
3. **Padronização da Escala Decimal:** A macro devolve o resultado na base decimal canônica (ex.: `0.15` para 15% ou `-0.05` para -5%), delegando a formatação visual (`15%`) exclusivamente para a camada de apresentação/BI.

#### Assinatura da Macro:
```jinja
{% macro percentage_change(current_value, previous_value) -%}
    {{ safe_divide("(" ~ current_value ~ " - " ~ previous_value ~ ")", previous_value) }}
{%- endmacro %}

---