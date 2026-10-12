## Configuração das variáveis de ambiente

As configurações de conexão com o banco de dados são definidas por variáveis de ambiente, evitando deixar credenciais diretamente no código-fonte.

### 1. Criar o arquivo `.env`

Na raiz do projeto, crie um arquivo chamado `.env` com as variáveis necessárias:

```dotenv
DB_HOST=localhost
DB_PORT=5432
DB_NAME=nome_do_banco
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
```

Substitua os valores de exemplo pelos dados da sua conexão com o PostgreSQL.

### 2. Configurar as dependências

O projeto utiliza `python-dotenv` para carregar as variáveis do arquivo `.env`.

Instale as dependências do projeto com:

```bash
uv sync
```

### 3. Validar a configuração

Com o arquivo `.env` preenchido, execute na raiz do projeto:

```bash
uv run python -c "from src.config import DB_HOST, DB_PORT; print('Configuração carregada:', DB_HOST, DB_PORT)"
```

Se as variáveis obrigatórias estiverem ausentes, o módulo de configuração apresentará uma mensagem de erro indicando qual variável precisa ser definida.

### 4. Segurança das credenciais

- O arquivo `.env` contém configurações locais e não deve ser versionado.
- O arquivo `.env.example` deve ser mantido no repositório, contendo apenas os nomes das variáveis e valores de exemplo, sem credenciais reais.
- Antes de enviar alterações ao GitHub, verifique se nenhum segredo foi incluído nos arquivos versionados.