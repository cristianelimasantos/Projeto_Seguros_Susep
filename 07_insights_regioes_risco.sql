
-- Análise de Dados - Top 5 Taxa de Sinistralidade


-- 1. Exposição, Prêmio e Indenizações e Quantidade de Sinistros por Região

WITH Analise_Geral AS (
SELECT
	R.Regiao_Macro AS Regiao,
	R.descricao AS Descricao_Regiao,

	SUM(C.exposicao1) AS Exposicao_Total,

	SUM(C.freq_sin1 + C.freq_sin2 + C.freq_sin3 + C.freq_sin4 + C.freq_sin9) AS Qtde_Sinistros,

	SUM(C.premio1) AS Premio_Total,

	SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) AS Indenizacao_Total,

	SUM(C.premio1) / SUM(C.exposicao1) AS Ticket_Medio_Premio,

	SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
		SUM(C.freq_sin1 + C.freq_sin2 + C.freq_sin3 + C.freq_sin4 + C.freq_sin9) AS Custo_Medio_Sinistro,

	SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
		SUM(C.premio1) * 100.0 AS Taxa_Sinistralidade

FROM fato_casco C LEFT JOIN vw_regiao_macro R
	ON C.cod_regiao = R.codigo
GROUP BY R.Regiao_Macro, R.descricao
)

SELECT
	Regiao,
	Descricao_Regiao,
	ROUND(Exposicao_Total,0) AS Exposicao_Total,
	ROUND(Premio_Total,2) AS Premio_Total, 
	ROUND(Indenizacao_Total,2) AS Indenizacao_Total,
	ROUND(Ticket_Medio_Premio,2) AS Ticket_Medio_Premio,
	Qtde_Sinistros,
	ROUND(Custo_Medio_Sinistro,2) AS Custo_Medio_Sinistro,
	Taxa_Sinistralidade,
DENSE_RANK() OVER(ORDER BY Taxa_Sinistralidade DESC) AS Ranking
FROM Analise_Geral;


-- 2. Comparação das regiões com a média geral da carteira

WITH Sinistralidade_Regiao AS (
	SELECT 
		R.descricao AS Desc_Regiao,
		SUM(C.premio1) AS Premio_Total,
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) AS Indenizacao_Total,
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
			SUM(C.premio1) * 100.0 AS Taxa_Sinistralidade
	FROM fato_casco C LEFT JOIN vw_regiao_macro R
	ON C.cod_regiao = R.codigo
GROUP BY R.Regiao_Macro, R.descricao
)

SELECT
	Desc_Regiao,
	ROUND(Taxa_Sinistralidade,2) AS Taxa_Sinistralidade,
	ROUND(AVG(Taxa_Sinistralidade) OVER (), 2) AS media_geral_carteira,
	ROUND(Taxa_Sinistralidade - AVG(Taxa_Sinistralidade) OVER (), 2) AS Desvio_Media,
	DENSE_RANK() OVER (ORDER BY Taxa_Sinistralidade DESC) AS Ranking
FROM Sinistralidade_Regiao
ORDER BY Taxa_Sinistralidade DESC;


-- 3. Categoria de veículos por região , por taxa de sinistralidade

SELECT
	R.descricao AS Regiao,
	Ct.categoria AS Categoria,
	ROUND(SUM(C.premio1),2) AS Premio_Total,
	ROUND(SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9), 2) AS Indenizacao_Total,
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
			SUM(C.premio1) * 100.0 AS Taxa_Sinistralidade
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
					LEFT JOIN dim_categoria Ct ON C.cod_categoria = Ct.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao, Ct.categoria
ORDER BY R.descricao, Taxa_Sinistralidade DESC;


-- 4. Qual tipo de sinistro é mais relevante nessas regiões

SELECT
	R.descricao AS Regiao,
	'Roubo_Furto' AS Tipo_sinistro, SUM(C.indeniz1) AS Vlr_Indenizacao 
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao

UNION ALL

SELECT R.descricao, 'Colisao', SUM(C.indeniz2) 
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao

UNION ALL

SELECT R.descricao, 'Perda_Total', SUM(C.indeniz3) 
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao

UNION ALL

SELECT R.descricao, 'Incendio', SUM(C.indeniz4) 
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao

UNION ALL

SELECT R.descricao, 'Outros', SUM(C.indeniz9)
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
WHERE R.descricao LIKE '%TO%Tocantins%'
   OR R.descricao LIKE '%BA%Bahia%'
   OR R.descricao LIKE '%PI%Piaui%'
   OR R.descricao LIKE '%PA%Par%'
   OR R.descricao LIKE '%MT%Grosso%'
GROUP BY R.descricao
ORDER BY Vlr_Indenizacao DESC;


-- 5. Perfil do segurado nessas regiões

SELECT
	R.descricao AS Regiao,
	S.descricao AS Sexo,
	I.descricao AS Faixa_Etaria,
	SUM(C.premio1) AS Premio_Total,
	SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) AS Indenizacao_Total,
	ROUND(
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) / 
				NULLIF(SUM(C.premio1),0) * 100.0, 2) AS Taxa_Sinistralidade
FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
				  LEFT JOIN dim_sexo S   ON C.cod_sexo   = S.codigo
				  LEFT JOIN dim_idade I  ON C.cod_idade  = I.codigo
WHERE (
	   R.descricao LIKE '%TO%Tocantins%'
	OR R.descricao LIKE '%BA%Bahia%'
    OR R.descricao LIKE '%PI%Piaui%'
    OR R.descricao LIKE '%PA%Par%'
    OR R.descricao LIKE '%MT%Grosso%')
AND (
	   S.descricao LIKE '%M%'
    OR S.descricao LIKE '%F%')
GROUP BY R.descricao, S.descricao, I.descricao
ORDER BY Regiao, Taxa_Sinistralidade DESC;


-- 6. Representatividade Percentual

WITH Indeniz_Regiao AS (
	SELECT
		R.descricao AS Regiao,
		SUM(C.indeniz1 + C.indeniz2 + C.indeniz3 + C.indeniz4 + C.indeniz9) AS Indenizacao_Total
	FROM fato_casco C LEFT JOIN dim_regiao R ON C.cod_regiao = R.codigo
	GROUP BY R.descricao)

SELECT 
	Regiao,
	Indenizacao_Total,
	ROUND(Indenizacao_Total * 100.0 / SUM(Indenizacao_Total) OVER (), 2) AS Percent_Top5,
	ROUND(
		Indenizacao_Total * 100.0 / 
		(SELECT SUM(indeniz1 + indeniz2 + indeniz3 + indeniz4 + indeniz9) FROM fato_casco), 2) AS Percent_Total_Carteira
FROM Indeniz_Regiao
WHERE (Regiao LIKE '%TO%Tocantins%'
	OR Regiao LIKE '%BA%Bahia%'
    OR Regiao LIKE '%PI%Piaui%'
    OR Regiao LIKE '%PA%Par%'
    OR Regiao LIKE '%MT%Grosso%')
ORDER BY Indenizacao_Total DESC;