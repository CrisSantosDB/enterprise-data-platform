
### 🛡️ Qualidade de Dados: Testes Customizados (Generic Tests)

Para garantir a integridade dos dados, prevenir anomalias temporais e validar consistências relacionais, implementamos testes genéricos personalizados no dbt:

---

#### 1. `not_far_future_date`
* **Arquivo:** `tests/generic/not_far_future_date.sql`
* **Objetivo:** Detectar registros com datas ou timestamps inconsistentes no futuro decorrentes de anomalias de digitação manual, servidores com fusos desconfigurados ou erros sistêmicos (ex.: anos corrompidos como 2099 ou transações registradas à frente do tempo real).
* **Lógica do Teste (Critério de Falha):** A consulta busca e retorna registros cujo valor na coluna seja estritamente superior ao timestamp atual somado à janela de dias configurada. Se o resultado retornar mais de 0 linhas, o teste falha.

##### 💡 Decisões Técnicas de Implementação (BigQuery / GoogleSQL):
1. **Tratamento de Nulos (`IS NOT NULL`):** Registros nulos são ignorados explicitamente no predicado `WHERE` para evitar sobreposição de escopo com o teste nativo `not_null`. Se o campo puder ser nulo por regra de negócio, o teste valida apenas as datas preenchidas.
2. **Uso de `timestamp_add()` com Tipo Estrito:** Aplicação da função nativa do BigQuery para manipulação temporal segura de colunas `TIMESTAMP`, prevenindo inconsistências de *cast* implícito.
3. **Sintaxe de Intervalo no Singular (`day`):** Adoção obrigatória do termo `day` (no singular), respeitando a especificação estrita do dialeto GoogleSQL.
4. **Tolerância a Fusos (`max_days_ahead = 1`):** Margem padrão de 1 dia para evitar falsos positivos provocados por discrepâncias de timezone entre os servidores de origem (horário local) e a nuvem de processamento (UTC).

##### Assinatura do Teste:
```jinja

{% test not_far_future_date(model, column_name, max_days_ahead=1) %}

select *
from {{ model }}
where 
    -- 1. Ignora registros nulos para não conflitar com testes do tipo 'not_null'
    {{ column_name }} is not null 
    
    -- 2. No dbt, testes buscam LINHAS QUE FALHAM. 
    --    Portanto, selecionamos registros cuja data seja MAIOR que o limite tolerado.
    --    Usamos 'timestamp_add' (função nativa do BigQuery) para somar intervalos com segurança.
    --    A unidade deve ser no singular ('day') conforme a sintaxe oficial do GoogleSQL.
    and {{ column_name }} > timestamp_add(current_timestamp(), interval {{ max_days_ahead }} day)

{% endtest %}
```
--- 
#### 2. `not_before_column`
* **Arquivo:** `tests/generic/not_before_column.sql`
* **Objetivo:** Garantir a consistência cronológica entre dois marcos temporais dentro do mesmo registro (um evento posterior nunca pode ter ocorrido antes do evento inicial de referência).
* **Lógica do Teste (Critério de Falha):** A consulta filtra e retorna linhas onde ambos os campos estão preenchidos, mas a coluna de evento posterior apresenta timestamp inferior ao da coluna de referência inicial (`column_name < compare_column`). Se o resultado contiver mais de 0 linhas, o teste falha.

##### 💡 Decisões Técnicas de Implementação:
1. **Tratamento de Nulos Bidirecional (`IS NOT NULL`):** Ambos os campos (`column_name` e `compare_column`) são filtrados para garantir que valores ausentes não gerem falsos positivos nem quebrem comparações relacionais com `UNKNOWN/NULL`. Se a ausência de valor for proibida, deve-se usar o teste complementar `not_null`.
2. **Separação de Papéis e Clareza:**
   - **`column_name` (Injetado pelo dbt):** Representa o evento que deve acontecer **depois** (a coluna onde o teste é declarado).
   - **`compare_column` (Informado via parâmetro):** Representa o evento base que deve ter ocorrido **primeiro**.
3. **Detecção Precisa de Anomalias de Negócio:** Captura falhas de integração onde registros de entrega constam antes da venda, ou atualizações cadastrais possuem timestamp anterior à data de criação.

##### Assinatura do Teste:
```jinja
{% test not_before_column(model, column_name, compare_column) %}
    select *
    from {{ model }}
    where {{ column_name }} is not null 
      and {{ compare_column }} is not null  
      and {{ column_name }} < {{ compare_column }}
{% endtest %}


```
---
#### 3. `accepted_range`
* **Arquivo:** `tests/generic/accepted_range.sql`
* **Objetivo:** Validar se os valores de uma coluna numérica ou de data estão contidos dentro de um intervalo delimitado (mínimo, máximo ou ambos), permitindo alternar entre intervalos abertos e fechados.
* **Lógica do Teste (Critério de Falha):** A consulta filtra e retorna todos os registros cujos valores estejam estritamente fora do intervalo estipulado. Se retornar mais de 0 linhas, o teste falha acusando violação de limites.

##### 💡 Decisões Técnicas de Implementação:
1. **CTE de Isolamento (`validation`):** Isola a coluna avaliada e aplica o filtro `where {{ column_name }} is not null`. Isso assegura que valores nulos não acionem falsos positivos (a obrigatoriedade de preenchimento deve ser delegada ao teste nativo `not_null`).
2. **Suporte a Limites Unilaterais:** Tanto `min_value` quanto `max_value` são opcionais (`default=none`). Se apenas o limite inferior for definido, o teste valida apenas valores menores que o mínimo; se apenas o máximo for informado, valida o teto.
3. **Sentinela Neutro (`1 = 0`):** Quando um dos limites não é informado (`none`), o Jinja injeta a condição falsa `1 = 0`, anulando aquele lado da cláusula lógica `OR` sem causar erro de sintaxe SQL.
4. **Controle de Inclusão (`inclusive=true/false`):** Permite configurar se os limites informados fazem parte do intervalo válido (`<=` / `>=`) ou se os limites devem ser tratados como estritamente menores/maiores (`<` / `>`).

##### Assinatura do Teste:
```jinja
{% test accepted_range(model, column_name, min_value=none, max_value=none, inclusive=true) %}

    with validation as (
        select {{ column_name }} as value_field
        from {{ model }}
        where {{ column_name }} is not null
    )

    select *
    from validation
    where
        {% if min_value is not none %}
            {% if inclusive %} value_field < {{ min_value }}
            {% else %} value_field <= {{ min_value }}
            {% endif %}
        {% else %} 1 = 0
        {% endif %}
        or
        {% if max_value is not none %}
            {% if inclusive %} value_field > {{ max_value }}
            {% else %} value_field >= {{ max_value }}
            {% endif %}
        {% else %} 1 = 0
        {% endif %}

{% endtest %}
```
--- 

#### 4. `must_be_empty`
* **Arquivo:** `tests/generic/must_be_empty.sql`
* **Objetivo:** Validar se um modelo, visão de auditoria ou tabela de exceções está rigorosamente vazio (0 registros).
* **Lógica do Teste (Critério de Falha):** A consulta executa um `select *` diretamente no modelo referenciado. Como o dbt interpreta qualquer linha retornada por um teste como falha, a presença de uma única linha fará o teste falhar imediatamente.

##### 💡 Decisões Técnicas de Implementação:
1. **Teste a Nível de Modelo (*Model-level test*):** Diferente dos testes de coluna, a assinatura recebe apenas `(model)`. Ele não é amarrado a um campo específico, mas sim à entidade como um todo.
2. **Ideal para Tabelas de Exceção e Quarentena:** Padrão arquitetural amplamente utilizado para auditar tabelas de erros ou *quarantine views* (ex.: registros duplicados, linhas órfãs de integridade referencial ou falhas graves de validação que são direcionadas para uma view analítica de auditoria).
3. **Simplicidade e Performance:** Não realiza agregações nem computações pesadas; a query apenas verifica a existência de dados. No BigQuery, o dbt encapsula a execução com `count(*)` por baixo dos panos para avaliar a falha com rapidez.

##### Assinatura do Teste:
```jinja
{% test must_be_empty(model) -%}
    select *
    from {{ model }}
{%- endtest %}
```
--- 

#### 5. `positive_value`
* **Arquivo:** `tests/generic/positive_value.sql`
* **Objetivo:** Assegurar que os valores de uma coluna numérica sejam estritamente positivos (maiores que zero), identificando números negativos ou valores zerados indesejados.
* **Lógica do Teste (Critério de Falha):** A consulta filtra e retorna linhas onde a coluna está preenchida (`IS NOT NULL`), mas apresenta valor menor ou igual a zero (`column_name <= 0`). Se o retorno contiver mais de 0 linhas, o teste falha acusando violação de positividade estrita.

##### 💡 Decisões Técnicas de Implementação:
1. **Tratamento Explícito de Nulos (`IS NOT NULL`):** Evita que campos vazios gerem falsos positivos ou comportamentos ambíguos na comparação SQL. Caso a coluna seja de preenchimento mandatório, deve-se combiná-la com o teste nativo `not_null`.
2. **Positividade Estrita (`<= 0`):** Diferente de validações não negativas (`< 0`), este teste considera o valor `0` como falha. É especialmente indicado para métricas transacionais e monetárias que exigem magnitude real (ex.: preços unitários de venda, quantidade de itens faturados, salários base).
3. **Alternativa Leve ao `accepted_range`:** Enquanto o `accepted_range` oferece flexibilidade de intervalos parametrizáveis via Jinja, o `positive_value` atua como um atalho semântico direto e de leitura imediata para regras elementares de negócio.

##### Assinatura do Teste:
```jinja
{% test positive_value(model, column_name) %}

    select *
    from {{ model }}
    where {{ column_name }} is not null
      and {{ column_name }} <= 0

{% endtest %}

```
--- 

### 🛡️ Qualidade de Dados: Teste Singular de Reconciliação Financeira (Singular Test)

Diferente dos testes genéricos reutilizáveis declarados no YAML, os **Testes Singulares** são consultas SQL puras desenvolvidas para validar regras de negócio complexas, cruzamentos entre modelos ou reconciliações de integridade entre camadas (Fato vs. Marts):

---

#### 1. `assert_mart_resumo_reconcilia_receitas`
* **Arquivo:** `tests/singular/assert_mart_resumo_reconcilia_receitas.sql`
* **Dependência Externa:** Referência cruzada aos modelos `fato_vendas`, `dim_data` e `mart_visao_geral_mes` via `{{ ref(...) }}`.
* **Objetivo:** Auditar e garantir a paridade financeira mensal entre a camada analítica dimensional detalhada (`fato_vendas` + `dim_data`) e a camada de consumo agregado (`mart_visao_geral_mes`).
* **Lógica do Teste (Critério de Falha):** A consulta consolida o somatório da receita na fato por mês, cruza com o valor reportado no mart mensal e calcula a diferença absoluta. Caso a divergência absoluta entre a fato e o mart ultrapasse R$ 0,01 (`> 0.01`), a query retorna os meses divergentes e o dbt interrompe a pipeline acusando quebra de reconciliação contábil.

##### 💡 Decisões Técnicas de Implementação:
1. **Auditoria de Camada Agregada vs. Transacional:** Em arquiteturas de Data Warehouse e Lakehouse, mart aggregations frequentemente aplicam agrupamentos, filtros de cancelamento ou regras de negócio adicionais. O teste de reconciliação assegura matematicamente que nenhuma linha transacional foi descartada, duplicada por *fan-out* de joins ou distorcida durante o pipeline.
2. **Tratamento de Arredondamento com Ponto Flutuante (`abs(...) > 0.01`):** Em ambientes analíticos (como BigQuery), operações sucessivas com tipos como `NUMERIC` ou `FLOAT64` podem acumular microdiferenças de dízimas ou arredondamentos de frações de centavos. A verificação da diferença absoluta com tolerância até 1 centavo (`0.01`) evita falsos positivos puramente computacionais e foca em desvios financeiros reais.
3. **Execução Automática na Esteira:** Por estar localizado no diretório padrão `tests/singular/` (ou `tests/`), ele é executado nativamente pelo comando `dbt test` sem necessidade de parametrização no `schema.yml`.

##### Código do Teste:
```sql
with fato as (

    select
        d.ano_mes,
        sum(f.valor_pago) as receita_fato
    from {{ ref('fato_vendas') }} f
    left join {{ ref('dim_data') }} d 
        on f.sk_data = d.sk_data
    group by d.ano_mes

),

mart as (

    select
        ano_mes,
        receita_liquida as receita_mart
    from {{ ref('mart_visao_geral_mes') }}

)

select
    f.ano_mes,
    f.receita_fato,
    m.receita_mart
from fato as f
inner join mart as m
    on f.ano_mes = m.ano_mes
where abs(f.receita_fato - m.receita_mart) > 0.01
```
--- 




 
