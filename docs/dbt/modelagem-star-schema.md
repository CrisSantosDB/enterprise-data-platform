# Documentação Técnica: Modelagem Dimensional Star Schema (Camada Gold)

## 1. Visão Geral da Arquitetura

A camada Gold adota uma modelagem dimensional no padrão **Star Schema**, projetada especificamente para consumo analítico, geração de relatórios de BI.

O objetivo central do modelo é consolidar as transações comerciais da organização, mantendo desacoplamento de chaves operacionais via Surrogate Keys (`sk_*`), rastreabilidade por colunas de auditoria e resiliência contra orfandade de dados por meio de registros padrão/fallback.

---

## 2. Diagrama Conceitual (Star Schema)

```text
       +-----------------------+             +--------------------------+
       |     dim_clientes      |             |     dim_vendedores       |
       +-----------------------+             +--------------------------+
       | PK  sk_clientes       |             | PK  sk_vendedores        |
       |     id_clientes       |             |     id_vendedores        |
       |     ...               |             |     ...                  |
       +-----------+-----------+             +-------------+------------+
                   |                                       |
                   | 1                                   1 |
                   |          +-----------------+          |
                   +--------> |   fato_vendas   | <--------+
                   |        N +-----------------+ N        |
                   |          | PK  id_vendas   |          |
                   | 1        | FK  sk_clientes |        1 |
       +-----------+--------> | FK  sk_vended.. | <--------+------------+
       |                      | FK  sk_conces.. |                       |
       |                      | FK  sk_veiculos |                       |
+------+----------------+     | FK  sk_data     |     +-----------------+--------+
| dim_concessionarias   |     |     data_venda  |     |      dim_veiculos        |
+-----------------------+     |     quantida..  |     +--------------------------+
| PK  sk_concessionarias|     |     valor_ta..  |     | PK  sk_veiculos          |
|     id_concessionarias|     |     valor_pago  |     |     id_veiculos          |
|     ...               |     |     valor_de..  |     |     ...                  |
+-----------------------+     |     percentu..  |     +--------------------------+
                              |     flag_des..  |
                              +--------+--------+
                                       | N
                                       |
                                       | 1
                              +--------+--------+
                              |    dim_data     |
                              +-----------------+
                              | PK  sk_data     |
                              |     dt_data     |
                              |     ano         |
                              |     mes         |
                              |     ...         |
                              +-----------------+
```

---

## 3. Tabela Fato: `fato_vendas`

- **Camada:** `03_dbt_gold`
- **Tipo:** Fato Transacional
- **Estratégia de Carga:** Incremental (`materialized='incremental'`, `incremental_strategy='merge'`, particionamento/filtro incremental baseado em `data_inclusao`)
- **Grão do Dado:** 1 linha por venda/transação realizada (`id_vendas`)

### Dicionário de Dados

| Coluna | Tipo | Classificação | Descrição | Regra de Transformação / Origem |
|---|---|---|---|---|
| `id_vendas` | STRING / INT64 | Primary Key | Identificador único da transação | Direto de `silver_vendas.id_vendas` |
| `sk_clientes` | STRING | Foreign Key | Chave substituta do cliente | `COALESCE(dim_clientes.sk_clientes, '-1')` |
| `sk_vendedores` | STRING | Foreign Key | Chave substituta do vendedor | `COALESCE(dim_vendedores.sk_vendedores, '-1')` |
| `sk_concessionarias` | STRING | Foreign Key | Chave substituta da concessionária | `COALESCE(dim_concessionarias.sk_concessionarias, '-1')` |
| `sk_veiculos` | STRING | Foreign Key | Chave substituta do veículo | `COALESCE(dim_veiculos.sk_veiculos, '-1')` |
| `sk_data` | INT64 | Foreign Key | Chave substituta da data de venda | `COALESCE(dim_data.sk_data, -1)` |
| `data_venda` | DATE | Atributo Temporal | Data em que a venda foi efetuada | `DATE(v.data_venda)` |
| `quantidade_vendas` | INT64 | Métrica Aditiva | Contagem base de transações | Fixo em `1` para cada registro |
| `valor_tabela` | NUMERIC | Métrica Semi-aditiva | Valor de referência do veículo | `COALESCE(silver_veiculos.valor_tabela, 0.0)` |
| `valor_pago` | NUMERIC | Métrica Aditiva | Valor final pago pelo cliente | `COALESCE(v.valor_pago, 0.0)` |
| `valor_desconto` | NUMERIC | Métrica Aditiva | Valor monetário concedido em desconto | `valor_tabela - valor_pago` |
| `percentual_desconto` | NUMERIC | Métrica Não-aditiva | Percentual de desconto sobre o valor de tabela | `ROUND(SAFE_DIVIDE(valor_tabela - valor_pago, valor_tabela), 3)` |
| `flag_desconto` | INT64 | Flag Analítico | Indicador binário se houve desconto aplicado | `CASE WHEN valor_desconto <= 0 THEN 0 ELSE 1 END` |
| `data_inclusao` | TIMESTAMP / DATE | Metadado Técnico | Data/hora de inserção do registro | Direto de `v.data_inclusao` (usado na carga incremental) |
| `dbt_scd_id` / colunas de auditoria | STRING / TIMESTAMP | Auditoria | Carimbos de governança e linhagem | Injetadas via macro `{{ audit_columns() }}` |

---

## 4. Tabelas Dimensão

### 4.1. `dim_clientes`

- **Descrição:** Entidade que armazena os dados cadastrais e demográficos dos compradores.
- **Chave Primária (PK):** `sk_clientes` (Surrogate Key).
- **Chave Natural (NK):** `id_clientes`.
- **Tratamento de Órfãos:** Registro dummy com `sk_clientes = '-1'`, `id_clientes = -1`, `nome_cliente = 'Nao Informado'`.

### 4.2. `dim_vendedores`

- **Descrição:** Contém o perfil e alocação do time comercial responsável pelo fechamento da venda.
- **Chave Primária (PK):** `sk_vendedores` (Surrogate Key).
- **Chave Natural (NK):** `id_vendedores`.
- **Tratamento de Órfãos:** Linha padrão com `sk_vendedores = '-1'` e atributos `'Nao Informado'`.

### 4.3. `dim_concessionarias`

- **Descrição:** Estrutura geográfica e operacional dos pontos de venda físicos da rede NovaDrive.
- **Chave Primária (PK):** `sk_concessionarias` (Surrogate Key).
- **Chave Natural (NK):** `id_concessionarias`.
- **Tratamento de Órfãos:** Linha padrão com `sk_concessionarias = '-1'` e dados regionais indefinidos.

### 4.4. `dim_veiculos`

- **Descrição:** Catálogo de veículos vendidos (marca, modelo, versão, ano e opcionais).
- **Chave Primária (PK):** `sk_veiculos` (Surrogate Key).
- **Chave Natural (NK):** `id_veiculos`.
- **Tratamento de Órfãos:** Linha padrão com `sk_veiculos = '-1'` e descrições `'Nao Informado'`.

### 4.5. `dim_data`

- **Descrição:** Dimensão de calendário baseada no padrão numérico `YYYYMMDD`. Permite filtros por hierarquias de ano, semestre, trimestre, mês, semana, finais de semana, feriados e dias úteis bancários.
- **Chave Primária (PK):** `sk_data` (INT64).
- **Tratamento de Órfãos:** Registro dummy com `sk_data = -1`, `dt_data = '1900-01-01'` e textos `'Nao Informado'`.

---

## 5. Princípios de Engenharia e Integridade

### Resiliência a Registros Órfãos (Estratégia Fallback)

A carga da tabela fato **não utiliza `INNER JOIN`**, prevenindo o descarte silencioso de transações reais caso uma chave natural ainda não exista nas dimensões.

- Realiza-se `LEFT JOIN` da tabela de vendas com todas as dimensões.
- Caso o cruzamento retorne `NULL`, aplica-se a função `COALESCE` apontando para a chave `-1` (ou `'-1'` textual para chaves em string).

### Divisão Segura e Cálculos Aritméticos

O cálculo do `percentual_desconto` utiliza tratamento contra divisão por zero via macro `{{ safe_divide(...) }}`, compilando para a função nativa `SAFE_DIVIDE()` do BigQuery, evitando travamentos em linhas com `valor_tabela = 0`.

### Estratégia Incremental

Configurada para append/merge com identificação de novidade orientada a `data_inclusao`:

```sql
WHERE v.data_inclusao >=(
    SELECT MAX(destino.data_inclusao)
    FROM {{ this }} AS destino
)
```

Garante idempotência e redução de volume de dados escaneados por consulta no BigQuery.

---

## 6. Governança e Testes de Qualidade (dbt)

A qualidade da camada Gold é fiscalizada automaticamente no pipeline CI/CD pelas seguintes regras:

### Unicidade e Não-Nulos

- `id_vendas`: testes `unique` e `not_null`.
- Todas as chaves `sk_*`: testes `not_null`.

### Integridade Referencial

- Testes `relationships` garantindo que toda chave `sk_*` presente na `fato_vendas` exista na tabela de dimensão correspondente (incluindo o registro dummy `-1`).

### Domínio e Intervalo

- `flag_desconto`: teste `accepted_values` com valores `[0, 1]`, configurado com `quote: false` para validação em tipo numérico `INT64`.
- `percentual_desconto`: teste `accepted_range` parametrizado por variáveis de projeto (`percentual_desconto_min` e `percentual_desconto_max`).