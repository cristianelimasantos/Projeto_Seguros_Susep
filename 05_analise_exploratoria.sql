/*
-- Análise Exploratória
*/

USE SUSEP_CASCO 
GO


-- 1. Quantidade de linhas
SELECT
	COUNT(*) AS Total_Linhas
FROM fato_casco;


-- 2. Quantidade de modelos distintos de veículos
SELECT
	COUNT(DISTINCT cod_modelo) Modelos_Diferentes
FROM fato_casco;


-- 3. Quantidade de linhas com exposição igual a zero
SELECT
	COUNT(*) Exposicao_Zero
FROM fato_casco
WHERE exposicao1 = 0;


-- 4. Valores mínimo, máximo e médio do prêmio
SELECT
	ROUND(MIN(premio1),2) AS Premio_Minimo,
	ROUND(MAX(premio1),2) AS Premio_Maximo,
	ROUND(AVG(premio1),2) AS Premio_Medio
FROM fato_casco;


-- 5. Quantidade de linhas por categoria de veículos
SELECT
	C.cod_categoria AS Categoria,
	CT.categoria AS Descricao_Categoria,
	COUNT(*) AS Qtde_Linhas,
		ROUND(
			COUNT(*) * 100.0 / 
				(SELECT COUNT(*) FROM fato_casco), 2) AS Percentual
FROM fato_casco C LEFT JOIN dim_categoria CT
	ON C.cod_categoria = CT.codigo
GROUP BY C.cod_categoria, CT.categoria
ORDER BY Qtde_Linhas DESC;


-- 6. Quantidade de linhas por sexo do segurado
SELECT
	C.cod_sexo,
	S.descricao AS Descricao_Sexo,
	COUNT(*) Qtde_Linhas,
	ROUND(
		COUNT(*) * 100.0 / 
			(SELECT COUNT(*) FROM fato_casco), 2) AS Percentual
FROM fato_casco C LEFT JOIN dim_sexo S
	ON C.cod_sexo = S.codigo
GROUP BY C.cod_sexo,S.descricao
ORDER BY Qtde_Linhas DESC;


-- 7. Quantidade de linhas por faixa etária
SELECT
	C.cod_idade,
	I.descricao AS Descricao_FaixaEtaria,
	COUNT(*) Qtde_Linhas,
	ROUND(
		COUNT(*) * 100.0 / 
			(SELECT COUNT(*) FROM fato_casco), 2) AS Percentual
FROM fato_casco C LEFT JOIN dim_idade I
	ON C.cod_idade = I.codigo
GROUP BY C.cod_idade,I.descricao
ORDER BY Qtde_Linhas DESC;


-- 8. Quantidade de linhas por região
SELECT
	C.cod_regiao AS Cod_Regiao,
	R.descricao AS Descricao_Regiao,
	COUNT(*) Qtde_Linhas,
	ROUND(
		COUNT(*) * 100.0 / 
			(SELECT COUNT(*) FROM fato_casco), 2) AS Percentual
FROM fato_casco C LEFT JOIN dim_regiao R
	ON C.cod_regiao = R.codigo
GROUP BY C.cod_regiao, R.descricao
ORDER BY Qtde_Linhas DESC;
