# Processo de Ingestão: PostgreSQL para BigQuery RAW

## 1. Visão Geral
Este módulo é responsável por extrair dados transacionais do banco relacional **PostgreSQL** e carregá-los no dataset da camada **RAW** do **Google BigQuery**, utilizando **PySpark** e o conector **JDBC**.

O objetivo é fornecer um ponto de entrada leve, rápido e com baixo consumo de recursos, servindo como base para as transformações posteriores na camada Bronze via dbt cloud.

---

## 2. Arquitetura e Estratégia de Carga

### 2.1 Carga Inicial (Full Load)
* **Critério:** Executada automaticamente quando a tabela de destino ainda não existe no dataset RAW do BigQuery.
* **Comportamento:** Extrai a totalidade dos registros da tabela de origem (`SELECT * FROM public.<tabela>`) e cria a tabela na RAW com modo `overwrite`.

### 2.2 Carga Incremental (Watermarking via RAW)
* **Critério:** Executada para todas as tabelas já existentes no BigQuery RAW.
* **Mecanismo:** 
  1. O script executa `SELECT MAX(data_inclusao)` diretamente na tabela da RAW.
  2. Como a RAW mantém apenas o último lote ingerido (gravação via `overwrite`), essa leitura consome o mínimo de varredura e custo do BigQuery.
  3. No PostgreSQL, a consulta extrai apenas registros onde `data_inclusao >= '<data_max>'`.
  4. O operador `>=` garante que registros que chegaram no mesmo segundo do corte anterior não sejam perdidos. Eventuais duplicidades geradas na borda são tratadas na camada Bronze.
  5. Se novos registros forem encontrados, a RAW é atualizada com o novo lote. Se não houver registros novos, a execução é ignorada para evitar tabelas vazias.

---

## 3. Ambientes Suportados

O script aceita o parâmetro CLI `--ambiente` para chavear as configurações:

| Ambiente | Descrição | Dataset BigQuery |
|---|---|---|
| `dev` | Ambiente de desenvolvimento local e testes | `novadrive_raw_dev` |
| `prod` | Ambiente produtivo | `novadrive_raw_prod` |

As credenciais do banco de origem são injetadas via variáveis de ambiente (`.env`):
* `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`

---

## 4. Como Executar

### 4.1 Execução da Ingestão

```bash
# Executar em ambiente de desenvolvimento
uv run python -m src.ingestao --ambiente dev

# Executar em ambiente de produção
uv run python -m src.ingestao --ambiente prod