/*

 Projeto: Análise de Carteira de Seguros de Veículos

*/

-- 01. Criação do banco de dados do projeto
CREATE DATABASE SUSEP_CASCO;
GO

USE SUSEP_CASCO;
GO

------------------------------------------------------------------------------

CREATE TABLE casco_bruto (
    COD_TARIF   VARCHAR(5),
    REGIAO      VARCHAR(5),
    COD_MODELO  VARCHAR(15),
    ANO_MODELO  VARCHAR(10),
    SEXO        VARCHAR(5),
    IDADE       VARCHAR(5),
    EXPOSICAO1  VARCHAR(30),
    PREMIO1     VARCHAR(30),
    EXPOSICAO2  VARCHAR(30),
    PREMIO2     VARCHAR(30),
    IS_MEDIA    VARCHAR(30),
    FREQ_SIN1   VARCHAR(15),
    INDENIZ1    VARCHAR(30),
    FREQ_SIN2   VARCHAR(15),
    INDENIZ2    VARCHAR(30),
    FREQ_SIN3   VARCHAR(15),
    INDENIZ3    VARCHAR(30),
    FREQ_SIN4   VARCHAR(15),
    INDENIZ4    VARCHAR(30),
    FREQ_SIN9   VARCHAR(15),
    INDENIZ9    VARCHAR(30),
    ENVIO       VARCHAR(10)
);
GO


-- Categoria do veículo (ex: Passeio nacional, Motocicleta...)
CREATE TABLE dim_categoria (
    codigo      TINYINT PRIMARY KEY,
    categoria   VARCHAR(60)
);
GO

-- Região SUSEP (relacionada a estado/UF)
CREATE TABLE dim_regiao (
    codigo      TINYINT PRIMARY KEY,
    descricao   VARCHAR(100)
);
GO

-- Faixa etária do segurado
CREATE TABLE dim_idade (
    codigo      TINYINT PRIMARY KEY,
    descricao   VARCHAR(60)
);
GO

-- Sexo do segurado
CREATE TABLE dim_sexo (
    codigo      CHAR(1) PRIMARY KEY,
    descricao   VARCHAR(30)
);
GO

-- Modelo do veículo
CREATE TABLE dim_veiculo (
    codigo      VARCHAR(15) PRIMARY KEY,
    descricao   VARCHAR(150),
    grupo       VARCHAR(120),
    cod_grupo   SMALLINT
);
GO