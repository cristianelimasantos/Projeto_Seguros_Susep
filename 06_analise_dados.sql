/*

Análise de Dados

*/

USE SUSEP_CASCO 
GO

-- 1. Criação de view - Região Macro

CREATE OR ALTER VIEW dbo.vw_regiao_macro AS

SELECT
	codigo,
	descricao,
	CASE
		WHEN descricao = 'Não informado' THEN 'Não informado'
		ELSE LEFT(descricao,2) END AS UF,
	CASE LEFT(descricao, 2)
        WHEN 'SP' THEN 'Sudeste' 
        WHEN 'RJ' THEN 'Sudeste'
        WHEN 'MG' THEN 'Sudeste' 
        WHEN 'ES' THEN 'Sudeste'
        WHEN 'PR' THEN 'Sul'     
        WHEN 'SC' THEN 'Sul'
        WHEN 'RS' THEN 'Sul'
        WHEN 'BA' THEN 'Nordeste' 
        WHEN 'PE' THEN 'Nordeste'
        WHEN 'CE' THEN 'Nordeste' 
        WHEN 'MA' THEN 'Nordeste'
        WHEN 'PB' THEN 'Nordeste' 
        WHEN 'RN' THEN 'Nordeste'
        WHEN 'AL' THEN 'Nordeste' 
        WHEN 'SE' THEN 'Nordeste'
        WHEN 'PI' THEN 'Nordeste'
        WHEN 'GO' THEN 'Centro-Oeste'
        WHEN 'MT' THEN 'Centro-Oeste'
        WHEN 'MS' THEN 'Centro-Oeste'
        WHEN 'DF' THEN 'Centro-Oeste'
        WHEN 'TO' THEN 'Centro-Oeste'
        WHEN 'AM' THEN 'Norte'
        WHEN 'PA' THEN 'Norte'
        WHEN 'RO' THEN 'Norte'
        WHEN 'AC' THEN 'Norte'
        WHEN 'RR' THEN 'Norte'
        WHEN 'AP' THEN 'Norte'
        ELSE 'Nao informado'
    END AS Regiao_Macro
FROM dim_regiao;


-- 2. Total Exposição, Prêmio, Indenização e Sinistros

SELECT
	ROUND(SUM(exposicao1),0) AS Exposicao_Total,
	FORMAT(SUM(premio1),'C', 'pt-BR') AS Premio_Total,
	FORMAT(SUM(indeniz1 + indeniz2 + indeniz3 + indeniz4 + indeniz9), 'C', 'pt-BR') AS Indenizacao_Total,
	ROUND(SUM(freq_sin1 + freq_sin2 + freq_sin3 + freq_sin4 + freq_sin9),0) AS Qtde_Sinistros
FROM fato_casco;


-- 3. Taxa de Sinistralidade

SELECT
	SUM(indeniz1 + indeniz2 + indeniz3 + indeniz4 + indeniz9) /
	SUM(premio1) * 100 AS Taxa_Sinistralidade
FROM fato_casco


-- 4. Ticket Médio por Prêmio

SELECT
	FORMAT(SUM(premio1) / SUM(exposicao1),'C', 'pt-BR') AS Ticket_Medio_Premio
FROM fato_casco;


-- 5. Prêmio, Indenizações e Sinistralidade por Região

SELECT
	R.Regiao_Macro AS Regiao,
	ROUND(SUM(C.premio1),2) AS Premio,
	ROUND(SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9),2) AS Indenizaçao,
	ROUND(
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
		SUM(C.premio1),2) * 100.0 AS Taxa_Sinistralidade
FROM fato_casco C LEFT JOIN  vw_regiao_macro R
	ON C.cod_regiao = R.codigo
GROUP BY R.Regiao_Macro;


-- 6. Faixa de Sinistralidade

WITH Tx_Sinistro AS (
	SELECT
		R.descricao AS Descricao,
			SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
			SUM(C.premio1) * 100.0 AS Taxa_Sinistralidade
	FROM fato_casco C LEFT JOIN vw_regiao_macro R
		ON C.cod_regiao = R.codigo
	GROUP BY R.descricao)

SELECT
	Descricao,
	Taxa_Sinistralidade,
	RANK() OVER(ORDER BY Taxa_Sinistralidade DESC) AS Ranking_Sinistralidade,
	CASE
		WHEN Taxa_Sinistralidade <= 0.65 THEN 'Bom'
		WHEN Taxa_Sinistralidade <= 0.75 THEN 'Atenção'
		ELSE 'Crítico' END AS Faixa_Sinistralidade
FROM Tx_Sinistro;


-- 7. Análise Top 5 - Taxa de Sinistralidade

SELECT
	R.UF,
	R.descricao AS Descricao,
	ROUND(SUM(C.premio1),2) AS Premio,
	ROUND(SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9),2) AS Indenizaçao,
	SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
		SUM(C.premio1) * 100.0 AS Taxa_Sinistralidade
FROM fato_casco C LEFT JOIN  vw_regiao_macro R
	ON C.cod_regiao = R.codigo
WHERE UF IN('TO', 'BA', 'PI', 'MT')
GROUP BY R.UF, R.descricao
ORDER BY Taxa_Sinistralidade DESC;


-- 8. Distribuição das Indenizações por Tipo de Sinistro

WITH Tx_indenizacao AS (
	SELECT
		V.Tipo_Indenizacao,
		SUM(V.Valor) AS Valor_Total
	FROM fato_casco C
	CROSS APPLY (VALUES
		('Roubo_Furto',	C.indeniz1),
		('Colisao',		C. indeniz2),
		('Perda_Total',	C.indeniz3),
		('Incendio',	C.indeniz4),
		('Outros',		C.indeniz9)
	) V (Tipo_Indenizacao, Valor)
	GROUP BY V.Tipo_Indenizacao
)

SELECT
	Tipo_Indenizacao,
	Valor_Total,
	SUM(Valor_Total) OVER() AS Total_Geral,
	ROUND(
		Valor_Total * 100.0 / SUM(Valor_Total) OVER (), 2
	) AS Percent_Repres
FROM Tx_indenizacao
ORDER BY Valor_Total DESC;


-- 9. Quantidade de Sinistro por Estado

WITH Qtde_Sinistros_UF AS (
	SELECT
		R.UF AS UF,
		SUM(C.freq_sin1 + C.freq_sin2 + C.freq_sin3 + C.freq_sin4 + C.freq_sin9) AS Qtde_Sinistros
	FROM fato_casco C LEFT JOIN vw_regiao_macro R
		ON C.cod_regiao = R.codigo
	GROUP BY R.UF
)

SELECT
	UF,
	Qtde_Sinistros,
	SUM(Qtde_Sinistros) OVER() AS Total_Geral,
	ROUND(
		Qtde_Sinistros * 100.0 / SUM(Qtde_Sinistros) OVER(),2) AS Percent_Repres
FROM Qtde_Sinistros_UF
ORDER BY Qtde_Sinistros DESC;


-- 10. Taxa de Sinistralidade por Categoria de Veículo

SELECT
	CT.categoria AS Categoria,
	ROUND(
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
			SUM(C.premio1) * 100.0, 1) AS Taxa_Sinistralidade
FROM fato_casco C LEFT JOIN dim_categoria CT
	ON C.cod_categoria = CT.codigo
GROUP BY CT.categoria
ORDER BY Taxa_Sinistralidade DESC;


-- 11. Distribuição da Exposição por Gênero e Faixa Etária

SELECT
	S.descricao AS Genero,
	I.descricao AS Faixa_Etaria,
	SUM(C.exposicao1) AS Exposicao,
	ROUND(
		SUM(C.exposicao1) * 100.0 / SUM(SUM(C.exposicao1)) OVER(PARTITION BY S.descricao), 2) AS Percent_Genero
FROM fato_casco C
	LEFT JOIN dim_sexo S ON C.cod_sexo = S.codigo
	LEFT JOIN dim_idade I ON C.cod_idade = I.codigo
GROUP BY S.descricao, I.descricao
ORDER BY S.descricao, I.descricao;



-- 12. Top 10 Modelo de Veículos - Ticket Médio para prêmios acima de 1.000

WITH Ticket_Medio_Premio_Acima_1000 AS (
	SELECT 
		V.descricao AS Descricao_Veiculo,
		ROUND(SUM(C.premio1),2) AS Premio,
		ROUND(SUM(C.exposicao1),2) AS Exposicao,
		ROUND(SUM(C.premio1) / SUM(C.exposicao1),2) AS Ticket_Medio
	FROM fato_casco C LEFT JOIN dim_veiculo V 
		ON C.cod_modelo = V.codigo
	GROUP BY V.descricao
	HAVING SUM(C.exposicao1) > 1000
)

SELECT TOP 10
	Descricao_Veiculo,
	Ticket_Medio
FROM Ticket_Medio_Premio_Acima_1000
ORDER BY Ticket_Medio DESC;