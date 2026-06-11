# Trabalho de Banco de Dados II - Relatório de Monitoramento em PL/SQL

Este repositório contém a solução do trabalho prático da disciplina de Banco de Dados II, ministrada pelo Prof. Gilberto Assis.

## 📌 Descrição do Projeto

O objetivo deste projeto foi desenvolver uma *Stored Procedure* em PL/SQL (`PR_RELATORIO`) capaz de gerar um relatório formatado no console (via `DBMS_OUTPUT`), contendo os dados de monitoramento referentes apenas à **última coleta realizada de cada servidor**. 

A unicidade de cada servidor é garantida pela combinação de três informações: **Cliente**, **Servidor** e **IP**.

## ⚙️ Estrutura de Dados

O relatório processa os dados armazenados em uma tabela pré-existente chamada `MONITORAMENTO`, que possui a seguinte estrutura:

```sql
CREATE TABLE MONITORAMENTO (
    DATA_HORA DATE,           -- data e hora da coleta dos dados
    CLIENTE VARCHAR2(300),    -- nome do cliente cujo os dados foram coletados
    SERVIDOR VARCHAR2(300),   -- nome do servidor cujo os dados foram coletados
    IP VARCHAR2(300),         -- ip do servidor cujo os dados foram coletados
    GRUPO VARCHAR2(300),      -- agrupamento do item monitorado (ex: INSTANCIA, TABLESPACE)
    PARAMETRO VARCHAR2(300),  -- parametro coletado
    VALOR VARCHAR2(300)       -- valor coletado
);
```

## 📋 Requisitos e Lógica Implementada

- **Filtro de Última Coleta**: O programa percorre a tabela filtrando a data e hora máxima (`MAX(DATA_HORA)`) para cada conjunto de Cliente, Servidor e IP.
- **Agrupamentos Dinâmicos**: O relatório separa as informações de acordo com a classe de monitoramento (`GRUPO`), exibindo seus respectivos parâmetros e valores.
- **Formatação de Colunas**: Utilização intensiva da função `RPAD()` para manter o alinhamento em formato tabular semelhante a relatórios textuais clássicos.
- **Uso de Cursores**: Implementação utilizando múltiplos cursores para iterar sobre servidores, grupos e parâmetros.
- **Tratamento de Dados**: Capacidade de lidar com quantidades variadas de parâmetros dentro de um mesmo grupo e exibição de linhas em formato de grade.

## 🚀 Como Executar

Para testar a procedure no seu ambiente Oracle:

1. Execute o script `RelatorioPLSQL.sql` na sua ferramenta de preferência (ex: SQL Developer, DBeaver, SQL*Plus). O script criará (ou substituirá) a procedure `PR_RELATORIO`.
2. Para visualizar o resultado da execução, certifique-se de ativar a saída do servidor e chame a procedure:

```sql
SET SERVEROUTPUT ON;
CALL PR_RELATORIO();
```
