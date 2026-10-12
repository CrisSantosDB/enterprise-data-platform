import os 
from dotenv import load_dotenv 

load_dotenv()

def _require(var: str) -> str:
    value = os.getenv(var)

    if not value:
        raise EnvironmentError(
            f"Variável de ambiente obrigatoria não definida: '{var}"
        )
    return value

DB_HOST: str = _require("DB_HOST")
DB_NAME: str = _require("DB_NAME")
DB_USER: str = _require("DB_USER")
DB_PASSWORD: str = _require("DB_PASSWORD")

DB_PORT: int = int(os.getenv("DB_PORT", "5432"))