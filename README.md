
# Enterprise Data Platform

Plataforma de Engenharia de Dados para pequenas e médias empresas, com foco em baixo custo operacional, automação, qualidade dos dados e apoio à tomada de decisões.

## Objetivo do projeto

Desenvolver uma plataforma moderna de Engenharia de Dados que permita transformar dados operacionais em informações confiáveis para o negócio, priorizando ferramentas open source e serviços em nuvem com opções gratuitas.

O projeto busca demonstrar como pequenas e médias empresas podem estruturar seus dados sem precisar investir inicialmente em uma infraestrutura complexa ou cara, permitindo a evolução da solução conforme suas necessidades cresçam.

## Problema de negócio

A Diretoria Comercial precisa acompanhar o desempenho dos vendedores e das concessionárias, analisar descontos e faturamento e avaliar a evolução mensal dos resultados.

Para atender a essas necessidades, a plataforma organizará os dados em modelos analíticos que permitam comparar resultados, identificar oportunidades de melhoria e apoiar decisões comerciais.

## Arquitetura de dados

A plataforma seguirá a arquitetura Medallion, organizada em três camadas:

### Bronze — Dados recebidos

Responsável por armazenar os dados provenientes das fontes de origem, preservando as informações recebidas e facilitando a rastreabilidade.

### Silver — Dados tratados

Responsável pela limpeza, padronização e aplicação de regras de qualidade, preparando os dados para utilização analítica.

### Gold — Dados analíticos

Responsável pela modelagem dimensional, com tabelas fato e dimensões que servirão de base para os Data Marts da Diretoria Comercial.

## Qualidade dos dados

Todas as três camadas terão testes automatizados com dbt.

Os testes serão definidos de acordo com as necessidades de cada camada, incluindo:

- Verificação de valores nulos.
- Verificação de unicidade.
- Validação de relacionamentos entre dados.
- Verificação de regras de negócio.
- Validação da consistência dos dados utilizados nas análises.

Os testes serão executados no fluxo de transformação para identificar problemas de qualidade antes que afetem os resultados analíticos.

## Data Marts da Diretoria Comercial

A Camada Gold será organizada em três Data Marts, cada um voltado a uma necessidade analítica.

### 1. Performance dos vendedores

**Modelo:** `mart_performance_vendedores`

Objetivo: acompanhar o desempenho individual dos vendedores e apoiar a avaliação dos resultados comerciais.

Principais indicadores:

- Quantidade de negócios fechados por vendedor.
- Faturamento bruto e receita líquida.
- Ticket médio por profissional.
- Ranking de desempenho por período e unidade.
- Indicadores para acompanhamento de metas e comissões.

### 2. Benchmarking das concessionárias

**Modelo:** `mart_benchmarking_concessionarias`

Objetivo: comparar o desempenho das unidades e identificar diferenças regionais e oportunidades de melhoria.

Principais indicadores:

- Faturamento por concessionária, estado e macrorregião.
- Desconto médio concedido por unidade.
- Distribuição das vendas por categoria de veículo.
- Comparação do desempenho comercial entre concessionárias.

### 3. Visão geral mensal

**Modelo:** `mart_visao_geral_mes`

Objetivo: disponibilizar uma visão executiva dos resultados mensais da rede.

Principais indicadores:

- Receita líquida mensal.
- Quantidade de veículos negociados por mês.
- Crescimento da receita em relação ao mês anterior (MoM).
- Percentual médio de desconto da rede.

## Tecnologias

- **Python:** desenvolvimento dos processos de ingestão.
- **Apache Spark:** processamento de dados.
- **PostgreSQL:** fonte de dados transacionais.
- **Google Cloud Platform (GCP):** infraestrutura em nuvem.
- **BigQuery:** armazenamento e consulta de dados analíticos.
- **dbt:** transformação, modelagem e testes automatizados de dados.
- **GitHub Actions:** automação de tarefas, testes e pipelines de CI/CD.

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
```

### Gerenciamento de dependências

As dependências principais incluem PySpark, Delta Lake, BigQuery e IPython Kernel. As ferramentas de desenvolvimento e testes incluem Black, Flake8, isort, pytest, pytest-cov e SQLFluff.

As dependências são declaradas no `pyproject.toml` e suas versões resolvidas são registradas no `uv.lock`.

### Arquivos de configuração

- `pyproject.toml`: contém as informações do projeto e as dependências.
- `uv.lock`: registra as versões resolvidas das dependências para ajudar a reproduzir o ambiente.
- `.python-version`: indica a versão do Python utilizada pelo projeto.


## Ambientes

A plataforma será organizada em dois ambientes:

- **DEV:** desenvolvimento, experimentação e validação das alterações.
- **PROD:** execução dos processos e disponibilização dos dados de produção.

A separação dos ambientes busca reduzir riscos de alterações indevidas e facilitar a validação antes da publicação das mudanças.

## Automação e CI/CD

O projeto utilizará GitHub Actions para automatizar etapas do ciclo de desenvolvimento, incluindo testes e execução de pipelines.

A integração com o dbt Cloud para disparo do job de produção será configurada conforme a arquitetura e os recursos disponíveis no projeto.

## Estratégia de custos

O projeto prioriza a construção de uma plataforma economicamente viável para pequenas e médias empresas.

Princípios adotados:

- Priorizar ferramentas open source e alternativas gratuitas quando adequadas.
- Utilizar recursos em nuvem de forma consciente.
- Evitar serviços ativos e recursos computacionais desnecessários.
- Avaliar limites gratuitos, cotas e possíveis cobranças antes de habilitar serviços.
- Considerar os custos de armazenamento, processamento e consultas.
- Permitir a evolução da arquitetura conforme o volume de dados e as necessidades do negócio aumentem.

Os serviços em nuvem podem possuir limites, condições e cobranças específicas. Por isso, o uso de recursos gratuitos será avaliado conforme as condições vigentes de cada serviço, sem pressupor que toda a infraestrutura será gratuita em qualquer escala.

## Desenvolvimento

O projeto será desenvolvido de forma incremental, com código versionado no GitHub e alterações integradas por meio de Pull Requests.

As implementações serão acompanhadas de testes e documentação conforme a evolução da plataforma.

## Status do projeto

Em desenvolvimento.
