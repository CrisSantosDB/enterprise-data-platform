import importlib


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
    assert config.DB_PORT == 5432


import pytest

from src.config import _require


def test_erro_quando_variavel_obrigatoria_nao_definida(monkeypatch):
    monkeypatch.delenv("DB_HOST", raising=False)

    with pytest.raises(EnvironmentError, match="DB_HOST"):
        _require("DB_HOST")
