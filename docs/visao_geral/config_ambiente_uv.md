## Configuração do ambiente Python com uv

O projeto utiliza **Python 3.12.13** e **uv** para gerenciar o ambiente virtual e as dependências.

### Pré-requisitos

- Python 3.12
- [uv](https://docs.astral.sh/uv/)

### Instalação

Após clonar o repositório, acesse a pasta do projeto e execute:

```bash
uv sync
```

Esse comando cria ou atualiza o ambiente virtual e instala as dependências definidas no projeto, utilizando o arquivo `uv.lock` quando disponível.

Para ativar o ambiente virtual no Linux:

```bash
source .venv/bin/activate
```

Para verificar a versão do Python:

```bash
uv run python --version