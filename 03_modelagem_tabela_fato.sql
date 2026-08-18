/*

03_modelagem_tabela_fato.sql

*/

USE SUSEP_CASCO;
GO

------------------------------------------------------------------------------
-- 3.1 Criação da segunda tabela fato
------------------------------------------------------------------------------
CREATE TABLE fato_casco (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    cod_categoria   TINYINT,
    cod_regiao      TINYINT,
    cod_modelo      VARCHAR(15),
    ano_modelo      SMALLINT,
    cod_sexo        CHAR(1),
    cod_idade       TINYINT,
    exposicao1      DECIMAL(18,6),
    premio1         DECIMAL(18,2),
    is_media        DECIMAL(18,2),
    freq_sin1       INT,
    indeniz1        DECIMAL(18,2),
    freq_sin2       INT,
    indeniz2        DECIMAL(18,2),
    freq_sin3       INT,
    indeniz3        DECIMAL(18,2),
    freq_sin4       INT,
    indeniz4        DECIMAL(18,2),
    freq_sin9       INT,
    indeniz9        DECIMAL(18,2)
);
GO

------------------------------------------------------------------------------
-- 3.2 Copiar os dados de casco_bruto para fato_casco, convertendo o tipo
------------------------------------------------------------------------------
INSERT INTO fato_casco (
    cod_categoria, cod_regiao, cod_modelo, ano_modelo, cod_sexo, cod_idade,
    exposicao1, premio1, is_media,
    freq_sin1, indeniz1, freq_sin2, indeniz2,
    freq_sin3, indeniz3, freq_sin4, indeniz4,
    freq_sin9, indeniz9
)
SELECT
    CAST(COD_TARIF AS TINYINT),
    CAST(REGIAO AS TINYINT),
    COD_MODELO,
    CAST(ANO_MODELO AS SMALLINT),
    SEXO,
    CAST(IDADE AS TINYINT),
    CAST(REPLACE(EXPOSICAO1, ',', '.') AS DECIMAL(18,6)),
    CAST(REPLACE(PREMIO1,    ',', '.') AS DECIMAL(18,2)),
    CAST(REPLACE(IS_MEDIA,   ',', '.') AS DECIMAL(18,2)),
    CAST(FREQ_SIN1 AS INT),
    CAST(REPLACE(INDENIZ1, ',', '.') AS DECIMAL(18,2)),
    CAST(FREQ_SIN2 AS INT),
    CAST(REPLACE(INDENIZ2, ',', '.') AS DECIMAL(18,2)),
    CAST(FREQ_SIN3 AS INT),
    CAST(REPLACE(INDENIZ3, ',', '.') AS DECIMAL(18,2)),
    CAST(FREQ_SIN4 AS INT),
    CAST(REPLACE(INDENIZ4, ',', '.') AS DECIMAL(18,2)),
    CAST(FREQ_SIN9 AS INT),
    CAST(REPLACE(INDENIZ9, ',', '.') AS DECIMAL(18,2))
FROM casco_bruto
WHERE COD_TARIF <> 'COD_TARIF';   -- garante que nenhuma linha de cabeçalho entrou junto
GO

------------------------------------------------------------------------------
-- 3.3 Criar as chaves estrangeiras (conecta fato_casco às dimensões)
------------------------------------------------------------------------------
ALTER TABLE fato_casco
ADD CONSTRAINT FK_categoria FOREIGN KEY (cod_categoria) REFERENCES dim_categoria(codigo);

ALTER TABLE fato_casco
ADD CONSTRAINT FK_regiao FOREIGN KEY (cod_regiao) REFERENCES dim_regiao(codigo);

ALTER TABLE fato_casco
ADD CONSTRAINT FK_sexo FOREIGN KEY (cod_sexo) REFERENCES dim_sexo(codigo);

ALTER TABLE fato_casco
ADD CONSTRAINT FK_idade FOREIGN KEY (cod_idade) REFERENCES dim_idade(codigo);
GO