import importlib

import pytest


def test_erro_quando_variavel_obrigatoria_nao_definida(monkeypatch):
    monkeypatch.delenv("TESTE_VAR_INEXISTENTE", raising=False)

    # Importa o módulo garantindo que variáveis dummy básicas existam caso seja o primeiro import
    monkeypatch.setenv("DB_HOST", "dummy")
    monkeypatch.setenv("DB_NAME", "dummy")
    monkeypatch.setenv("DB_USER", "dummy")
    monkeypatch.setenv("DB_PASSWORD", "dummy")
    monkeypatch.setenv("DB_PORT", "5432")

    from src.config import _require

    # Testa a função com uma variável que garantidamente não existe
    with pytest.raises(EnvironmentError, match="TESTE_VAR_INEXISTENTE"):
        _require("TESTE_VAR_INEXISTENTE")


def test_carrega_variaveis_de_ambiente(monkeypatch):
    monkeypatch.setenv("DB_HOST", "localhost")
    monkeypatch.setenv("DB_NAME", "banco_teste")
    monkeypatch.setenv("DB_USER", "usuario_teste")
    monkeypatch.setenv("DB_PASSWORD", "senha_teste")
    monkeypatch.setenv("DB_PORT", "5432")

    import src.config as config

    importlib.reload(config)

    assert config.DB_HOST == "localhost"
    assert config.DB_NAME == "banco_teste"
    assert config.DB_USER == "usuario_teste"
    assert config.DB_PASSWORD == "senha_teste"
    assert str(config.DB_PORT) == "5432"


def test_config_ambiente_dev():
    from src.config import obter_config_ambiente

    config = obter_config_ambiente("dev")

    assert config["GCP_PROJECT"] == "novadrive-analytics-dev"
    assert config["BQ_DATASET"] == "RAW"


def test_config_ambiente_prod():
    from src.config import obter_config_ambiente

    config = obter_config_ambiente("prod")

    assert config["GCP_PROJECT"] == "novadrive-analytics-prod"
    assert config["BQ_DATASET"] == "RAW"


def test_erro_para_ambiente_invalido():
    from src.config import obter_config_ambiente

    with pytest.raises(ValueError, match="Ambiente inválido"):
        obter_config_ambiente("teste")
