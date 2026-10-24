# Arquitetura e Configuração no dbt Cloud

Este documento descreve a infraestrutura base, convenções de camadas (Medallion Architecture) e variáveis globais configuradas no dbt Cloud para o projeto Enterprise Data Platform.

---

## 1. Estrutura de Camadas (Medallion Architecture)

As transformações estão particionadas em schemas específicos no BigQuery com as seguintes estratégias de materialização:

* **1_bronze (`01_dbt_bronze`)**
  * **Materialização:** `incremental`
  * **Estratégia:** `merge`
  * **Objetivo:** Ingestão de fontes brutas com deduplicação via chave única, garantindo a preservação do histórico contra sobreescritas (`overwrite`).

* **2_silver (`02_dbt_silver`)**
  * **Materialização:** `incremental`
  * **Estratégia:** `merge`
  * **Objetivo:** Limpeza, padronização de tipos e aplicação das primeiras regras de negócio sobre registros novos/alterados.

* **3_gold (`03_dbt_gold`)**
  * `dimensions/`: Materializadas como `table` para consultas dimensionais analíticas.
  * `facts/`: Materializadas como `incremental` (`merge`) para tabelas fato volumosas.
  * `marts/`: Materializadas como `table` para consolidação final e consumo no Power BI/dashboards.
  * `audits/`: Materializadas como `view` para monitoramento contínuo de qualidade e integridade dos dados.

---

## 2. Dependências Externas (`packages.yml`)

* **`dbt-labs/dbt_utils` (v1.3.0):**
  * Utilizado para geração padronizada de chaves substitutas (*surrogate keys*).
  * Fornece macros auxiliares para testes avançados de integridade referencial e unicidade.
  * Instalação executada via console do dbt Cloud: `dbt deps`.

---

## 3. Variáveis Globais (`vars`)

Definidas centralizadamente no `dbt_project.yml` para controle operacional e validações de regras de negócio:

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `incremental_safety_window_minutes` | `5` | Janela de tolerância temporal (watermark) para captura de registros atrasados. |
| `percentual_desconto_min` | `0.0` | Limite inferior para testes de desconto concedido. |
| `percentual_desconto_max` | `0.10` | Teto percentual permitido para validações de desconto comercial. |
| `reconciliacao_tolerancia` | `0.01` | Margem de precisão para conciliação contábil/financeira entre camadas. |