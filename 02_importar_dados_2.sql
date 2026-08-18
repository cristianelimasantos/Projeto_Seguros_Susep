/*

 02_importar_dados.sql
 
*/

USE SUSEP_CASCO;
GO

-- 2.1 Tabela fato
BULK INSERT casco_bruto
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\arq_casco_comp.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '1252'
);
GO

-- 2.2 Tabelas dimensão
BULK INSERT dim_categoria
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\auto_cat.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0a', CODEPAGE = '1252');
GO

BULK INSERT dim_regiao
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\auto_reg.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0a', CODEPAGE = '1252');
GO

BULK INSERT dim_idade
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\auto_idade.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0a', CODEPAGE = '1252');
GO

BULK INSERT dim_sexo
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\auto_sexo.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0a', CODEPAGE = '1252');
GO

BULK INSERT dim_veiculo
FROM 'C:\_Cursos\POS TECH DATA ANALYTICS\FASE 1\2-Fundamentos de analise de dados para negocios\Susep_Bases\Susep_SQL\Planilhas Susep\auto_vei.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0a', CODEPAGE = '1252');
GO

------------------------------------------------------------------------------
-- 2.3 Conferência da quantidade de linhas
------------------------------------------------------------------------------
SELECT COUNT(*) AS total_casco_bruto FROM casco_bruto;
SELECT COUNT(*) AS total_categoria   FROM dim_categoria;
SELECT COUNT(*) AS total_regiao      FROM dim_regiao;
SELECT COUNT(*) AS total_idade       FROM dim_idade;
SELECT COUNT(*) AS total_sexo        FROM dim_sexo;
SELECT COUNT(*) AS total_veiculo     FROM dim_veiculo;
