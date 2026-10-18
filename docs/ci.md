# Integração Contínua (CI)

## Objetivo

A integração contínua (CI) foi configurada para automatizar as verificações de qualidade do código Python e a execução dos testes automatizados, ajudando a identificar problemas antes de integrar alterações à branch `main`.

## GitHub Actions

O workflow está definido em `.github/workflows/ci.yml` e utiliza o GitHub Actions para executar as verificações automaticamente em um ambiente Ubuntu com Python 3.12.

A execução é configurada para os seguintes eventos:

- `push` nas branches `main` e `feature/*`;
- `pull_request` direcionado à branch `main`;
- `workflow_dispatch`, que permite iniciar a execução manualmente.

## Verificações de qualidade

O workflow possui um job de qualidade do código que executa as seguintes ferramentas:

- **Black:** verifica se o código segue o padrão de formatação configurado.
- **isort:** verifica se os imports estão organizados corretamente.
- **Flake8:** identifica erros críticos de sintaxe e outros problemas selecionados por meio das regras configuradas.

As ferramentas são executadas com as dependências declaradas no projeto, evitando a necessidade de instalá-las manualmente a cada execução.

## Testes automatizados

Após a conclusão do job de qualidade, o job de testes executa os testes automatizados com `pytest`.

Os testes do módulo `src/config.py` verificam:

- O carregamento das variáveis de ambiente obrigatórias.
- O comportamento esperado quando uma variável obrigatória não está definida.

Os testes utilizam valores fictícios para validar o comportamento da configuração, sem expor credenciais reais ou depender de uma conexão com o banco de dados.

## Fluxo de execução

1. Uma alteração é enviada para uma branch monitorada ou é aberto um Pull Request para a `main`.
2. O GitHub Actions inicia o workflow.
3. O job de qualidade executa Black, isort e Flake8.
4. Se o job de qualidade for concluído com sucesso, o job de testes executa o pytest.
5. Os resultados ficam disponíveis na aba **Actions** do GitHub e na verificação associada ao Pull Request.

## Benefícios

A CI reduz a necessidade de verificações manuais, ajuda a identificar problemas antecipadamente e contribui para manter a qualidade do código antes da integração das alterações à branch `main`.

## Como executar localmente

Para reproduzir as verificações no ambiente de desenvolvimento, execute:

```bash
uv run black --check --diff .
uv run isort --profile black --check-only --diff src/ tests/
uv run flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
uv run pytest tests/ --verbose --tb=short
```

Os comandos utilizam as ferramentas e as dependências declaradas no projeto.
