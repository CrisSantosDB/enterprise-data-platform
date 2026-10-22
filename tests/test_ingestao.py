import os
from datetime import datetime
from unittest.mock import MagicMock

# Define valores fictícios antes que src/config.py seja chamado
os.environ["DB_HOST"] = "localhost"
os.environ["DB_PORT"] = "5432"
os.environ["DB_NAME"] = "dummy_db"
os.environ["DB_USER"] = "dummy_user"
os.environ["DB_PASSWORD"] = "dummy_password"

from src.ingestao import buscar_registros_novos


def test_buscar_tabelas_e_data_mesmo_timestamp():
    tabelas = [
        "cidades",
        "clientes",
        "concessionarias",
        "estados",
        "veiculos",
        "vendas",
        "vendedores",
    ]

    data_teste = datetime(2026, 10, 20, 10, 0, 0)

    for tabela in tabelas:

        spark = MagicMock()

        spark.read.format.return_value.option.return_value = (
            spark.read.format.return_value
        )

        buscar_registros_novos(spark, tabela, data_teste)

        chamadas = spark.read.format.return_value.option.call_args_list

        sql_gerado = ""

        for chamada in chamadas:
            if chamada.args[0] == "dbtable":
                sql_gerado = chamada.args[1]

        assert f"public.{tabela}" in sql_gerado
        assert "data_inclusao >=" in sql_gerado


def test_bucar_registro_novos_sem_watermark():
    """Valida cenário de carga full quando não há data_max."""
    spark = MagicMock()

    spark.read.format.return_value.option.return_value = spark.read.format.return_value

    buscar_registros_novos(spark, "vendas", None)
    camada_options = spark.read.format.return_value.option.call_args_list

    sql_gerado = ""

    for chamada in camada_options:
        if chamada.args[0] == "dbtable":
            sql_gerado = chamada.args[1]

    assert "public.vendas" in sql_gerado
    assert "data_inclusao >=" not in sql_gerado
