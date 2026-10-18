import os

from dotenv import load_dotenv

load_dotenv()


def _require(var: str) -> str:
    value = os.getenv(var)

    if not value:
        raise EnvironmentError(f"Variável de ambiente obrigatoria não definida: '{var}")
    return value


DB_HOST: str = _require("DB_HOST")
DB_NAME: str = _require("DB_NAME")
DB_USER: str = _require("DB_USER")
DB_PASSWORD: str = _require("DB_PASSWORD")

DB_PORT: int = int(os.getenv("DB_PORT", "5432"))

AMBIENTES = {
    "dev": {
        "GCP_PROJECT": "novadrive-analytics-dev",
        "BQ_DATASET": "RAW",
    },
    "prod": {
        "GCP_PROJECT": "novadrive-analytics-prod",
        "BQ_DATASET": "RAW",
    },
}


def obter_config_ambiente(ambiente: str) -> dict[str, str]:
    if ambiente not in AMBIENTES:
        raise ValueError(f"Ambiente inválido: '{ambiente}'. Use 'dev' ou 'prod'.")

    return AMBIENTES[ambiente]
