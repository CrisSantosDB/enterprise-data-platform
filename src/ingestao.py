
import argparse
import logging
import os
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery
from pyspark.sql import DataFrame, SparkSession

from src.config import obter_config_ambiente

LOG_PATH = Path("logs")
LOG_PATH.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    filename=LOG_PATH / "novadrive-ingestion.log",
    level=logging.INFO,
    format="%(asctime)s-%(name)s-%(levelname)s-%(message)s",
)

logger = logging.getLogger("ingestion")


# 1. Carregamento das variáveis
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# 2. SparkSession (somente com o driver JDBC do Postgres)


def inicializar_recursos(project_id: str):
    """Inicializa o Spark e o cliente do BigQuery."""
    builder = (
        SparkSession.builder.appName("Nova_Drive_Ingestao")
        .master("local[*]")
        .config(
            "spark.jars.packages",
            "org.postgresql:postgresql:42.7.3,"
            "com.google.cloud.spark:spark-4.1-bigquery:0.45.0",
        )
    )

    spark = builder.getOrCreate()
    logger.info("SparkSession inicializado com sucesso!")

    bq_client = bigquery.Client(project=project_id)

    return spark, bq_client


# Conexao com o banco de dados
jdbc_url = f"jdbc:postgresql://{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Tabelas do projeto que tem no banco de dados
DB_TABLES = [
    "cidades",
    "clientes",
    "concessionarias",
    "estados",
    "veiculos",
    "vendas",
    "vendedores",
]


# Funções necessárias

def obter_data_max_bigquery(
    bq_client: bigquery.Client, table: str
) -> datetime:
    query = f"""
                SELECT MAX(data_inclusao) AS data_max
                FROM `{dataset_id}.{table}`
            """

    resultado = bq_client.query(query).result()

    for row in resultado:
        data_max_bq = row.data_max

    return data_max_bq


def buscar_registros_novos(
    spark: SparkSession, table: str, data_max_bq: datetime
) -> DataFrame:
    if data_max_bq is not None:
        query_watermark = f"""
                    (
                        SELECT *
                        FROM public.{table}
                        WHERE data_inclusao >='{data_max_bq}'
                    ) AS data_watermark
                """
    else:
        query_watermark = f""" 
                           (
                           select * from public.{table}
                           ) AS data_watermark 
                        """

    dados_novos = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", query_watermark)
        .option("user", DB_USER)
        .option("password", DB_PASSWORD)
        .option("driver", "org.postgresql.Driver")
        .load()
    )

    return dados_novos


def gravar_dados(table: str, project_id: str,dados_novos: DataFrame):
    (
        dados_novos.write.format("bigquery")
        .mode("overwrite")
        .option("writeMethod", "direct")
        .option("table", f"{dataset_id}.{table}")
        .option("parentProject", project_id)
        .save()
    )


def processar_tabela(
    spark: SparkSession,
    bq_client: bigquery.Client,
    table: str,
    project_id: str
):
    data_max_bq = obter_data_max_bigquery(bq_client, table)

    dados_novos = buscar_registros_novos(
        spark, table, data_max_bq
    )

    if dados_novos.limit(1).count() > 0:
        gravar_dados(table, project_id, dados_novos)
        logger.info(
            "Dados carregados na RAW para a tabela %s", table
        )
    else:
        logger.info(
            "Nenhum registro encontrado para a tabela %s", table
        )


# EXECUÇÃO PRINCIPAL
def main():
    parser = argparse.ArgumentParser(
        description="Ingestão PostgreSQL para BigQuery RAW"
    )

    parser.add_argument(
        "--ambiente",
        choices=["dev", "prod"],
        required=True,
        help="Ambiente de execução: dev ou prod",
    )

    args = parser.parse_args()

    config = obter_config_ambiente(args.ambiente)

    global dataset_id
    dataset_id = (
        f"{config['GCP_PROJECT']}.{config['BQ_DATASET']}"
    )

    logger.info("=== Iniciando pipeline de ingestão no ambiente: [%s] ===", args.ambiente.upper())
    
    spark, bq_client = inicializar_recursos(
        config["GCP_PROJECT"]
    )

    try:
        # Lista as tabelas que já existem no RAW
        list_tables_dataset = [
            i.table_id
            for i in bq_client.list_tables(dataset_id)
        ]

        for table in DB_TABLES:
            if table not in list_tables_dataset:
                dados = (
                    spark.read.format("jdbc")
                    .option("url", jdbc_url)
                    .option("dbtable", f"public.{table}")
                    .option("user", DB_USER)
                    .option("password", DB_PASSWORD)
                    .option("driver", "org.postgresql.Driver")
                    .load()
                )

                (
                    dados.write.format("bigquery")
                    .mode("overwrite")
                    .option("writeMethod", "direct")
                    .option("parentProject", config["GCP_PROJECT"])
                    .option("table", f"{dataset_id}.{table}")
                    .save()
                )

                logger.info(
                    "Tabela %s carregada com sucesso", table
                )

            else:
                processar_tabela(
                    spark, bq_client, table, config["GCP_PROJECT"]
               )

        logger.info("=== Pipiline concluído com sucesso no ambiente: [%s] ===", args.ambiente.upper())

    finally:
        spark.stop()


if __name__ == "__main__":
    main()
