# Projeto_Seguros_Susep
## Analise da Carteira de Seguros de Veículos - 2º Semestre


Projeto de análise de dados do setor de seguros automotivos brasileiro, construído em **SQL Server (T-SQL)** a partir dos microdados públicos da SUSEP (Superintendência de Seguros Privados), segmento **Casco Compreensivo**.

O projeto cobre o pipeline completo: ingestão de CSV bruto → modelagem em esquema estrela → tratamento e normalização de dimensões → análises exploratórias e de negócio (sinistralidade, ticket médio, exposição) via consultas T-SQL avançadas.

---

## 🎯 Objetivo

Simular, de ponta a ponta, o trabalho de um(a) Analista de Dados/BI sobre uma base real de seguros: ingerir um arquivo grande (~3,2 milhões de linhas) com problemas típicos de dado bruto (formatação numérica em padrão brasileiro, chaves sem correspondência, codificação de caracteres), modelá-lo em um formato analítico e responder perguntas de negócio como:

- Qual a taxa de sinistralidade por região, categoria de veículo e perfil do segurado?
- Qual o ticket médio de prêmio por modelo de veículo?
- Como se distribuem as indenizações por tipo de sinistro (roubo/furto, colisão, incêndio, perda total, outros)?

## 🗂️ Fonte dos dados

- **Órgão:** SUSEP — dados públicos de estatísticas de seguros de automóvel (Casco Compreensivo)
- **Arquivo principal:** `arq_casco_comp.csv` (~3,2 milhões de linhas)
- **Arquivos de apoio (dimensões):** categoria de veículo, região, faixa etária, sexo, modelo de veículo

> Os arquivos CSV originais não estão incluídos neste repositório (apenas os scripts SQL do pipeline), por serem volumosos e de origem pública. Os caminhos usados no `BULK INSERT` são locais e devem ser ajustados por quem for reproduzir o projeto.

## 🏗️ Modelo de dados

Esquema estrela com a tabela fato `fato_casco` no centro, conectada a 5 dimensões:

```
                dim_categoria
                      │
   dim_sexo ──── fato_casco ──── dim_regiao
                      │
              dim_idade    dim_veiculo
```

| Tabela | Papel | Observação |
|---|---|---|
| `casco_bruto` | Staging | Todas as colunas em `VARCHAR`, para receber o CSV sem falhas de conversão (separador decimal brasileiro) |
| `fato_casco` | Fato | Métricas de exposição, prêmio, indenização e frequência de sinistro, já tipadas |
| `dim_categoria` | Dimensão | Categoria do veículo |
| `dim_regiao` | Dimensão | Região SUSEP (UF) |
| `dim_idade` | Dimensão | Faixa etária do segurado |
| `dim_sexo` | Dimensão | Sexo do segurado |
| `dim_veiculo` | Dimensão | Modelo do veículo |

`dim_veiculo` não recebeu `FOREIGN KEY` formal — a ligação com `fato_casco` é feita via `LEFT JOIN` nas consultas, para evitar que códigos de modelo sem correspondência interrompessem a carga.

## 🔄 Pipeline (ordem de execução)

| Script | Etapa | O que faz |
|---|---|---|
| `01_criar_banco_e_tabelas.sql` | Setup | Cria o banco `SUSEP_CASCO`, a tabela de staging (`casco_bruto`) e as 5 tabelas de dimensão |
| `02_importar_dados.sql` | Ingestão | Carrega os CSVs via `BULK INSERT` (delimitador `;`, `CODEPAGE 1252` para acentuação) e confere a contagem de linhas de cada tabela |
| `03_modelagem_tabela_fato.sql` | Transformação | Cria `fato_casco` tipada, converte texto → número (`REPLACE` de vírgula por ponto + `CAST`) e aplica as `FOREIGN KEY`s |
| `04_qualidade_e_integridade_dados.sql` | Qualidade de dados | Identifica códigos de dimensão sem correspondência (`LEFT JOIN` + `DISTINCT`) e insere registros "Não informado" para região e veículo, garantindo que nenhuma linha do fato fique órfã; valida nulos nas colunas-chave |
| `05_analise_exploratoria.sql` | EDA | Estatísticas descritivas: contagem de linhas, modelos distintos, exposição zerada, min/max/média de prêmio, distribuição por categoria, sexo, faixa etária e região |
| `06_analise_dados.sql` | Análise de negócio | View de macrorregião, sinistralidade total e por corte, ticket médio, ranking de sinistralidade, distribuição de indenizações por tipo de sinistro, top 10 modelos por ticket médio |
| `07_insights_regioes_risco.sql` | Análise de negócio | Aprofundamento nas 05 regiões de maior sinistralidade |

## 🧠 Técnicas de T-SQL aplicadas

- **CTEs** (`WITH`) para organizar cálculos intermediários antes da agregação final
- **Window functions** — `RANK() OVER (...)`, `SUM(...) OVER (PARTITION BY ...)` — para ranking de sinistralidade e participação percentual sem subconsultas repetidas
- **`CROSS APPLY` com `VALUES`** para "despivotar" as colunas `indeniz1`–`indeniz9` em linhas por tipo de sinistro
- **View (`vw_regiao_macro`)** para reclassificar UF em macrorregião (Norte, Nordeste, Centro-Oeste, Sudeste, Sul), reaproveitada em várias consultas
- **`LEFT JOIN` sistemático** entre fato e dimensões, para não perder linhas quando o código de dimensão está ausente ou não mapeado
- **Conversão de tipos e tratamento de dado bruto**: `REPLACE(coluna, ',', '.')` + `CAST(... AS DECIMAL)` para lidar com o padrão decimal brasileiro vindo do CSV

## 🛠️ Principais desafios técnicos resolvidos

- **Separador decimal brasileiro**: o CSV usa vírgula (`1,03`), incompatível com colunas numéricas do SQL Server — resolvido com staging 100% `VARCHAR` seguido de conversão controlada
- **Chaves de dimensão sem correspondência**: códigos de região e veículo presentes no fato mas ausentes nas tabelas de apoio — identificados via `LEFT JOIN` e tratados com registros "Não informado" (`04_qualidade_e_integridade_dados.sql`) em vez de descartar linhas do fato
- **Integridade referencial seletiva**: `FOREIGN KEY` aplicada em categoria, região, sexo e idade, mas não em veículo, para não travar a carga por códigos órfãos
- **Acentuação em CSV**: uso de `CODEPAGE = '1252'` no `BULK INSERT` para preservar caracteres acentuados nos arquivos de dimensão
- **Erro de conversão de tipo na carga do fato**: durante a criação de `fato_casco`, o SQL Server retornou o erro *"Falha ao converter o varchar valor '.' para o tipo de dados tinyint"* — evidência de que a etapa de conversão de texto para número (Script 03) precisou lidar com valores inválidos/atípicos vindos do CSV bruto antes de fechar a carga

## 📊 Principais insights (resultados reais das queries)

> Números extraídos diretamente da execução dos scripts 05 e 06 (SSMS, execução concluída em 15/08/2026). Percentuais de sinistralidade por região/UF nos itens abaixo saem arredondados em duas casas *antes* da multiplicação por 100 (conforme a query do Script 06), o que gera valores "redondos" como 74.00% — é uma característica da consulta, não um erro de leitura.

**Volume e qualidade da base**
- Base final: **3.210.981 linhas** em `fato_casco`, cobrindo **8.186 modelos de veículo distintos**
- **81.118 linhas** (≈2,5%) têm exposição igual a zero
- Após o tratamento de dimensões (Script 04), **zero valores nulos** em `cod_categoria`, `cod_regiao`, `premio1` e `indeniz1`

**Visão geral financeira**
- Exposição total: **8.258.814**
- Prêmio total: **R$ 12.420.441.676,29**
- Indenização total: **R$ 9.200.431.817,00**
- Quantidade total de sinistros: **2.562.355**
- Taxa de sinistralidade geral (indenização/prêmio): **≈74,07%**
- Ticket médio de prêmio (prêmio/exposição): **R$ 1.503,90**
- Prêmio: mínimo R$ 0,00 · máximo R$ 7.071.011,34 · médio R$ 3.868,11

**Perfil da carteira**
- Categoria de veículo: **Passeio nacional lidera com 52,17%** das linhas, seguido por Pick-up nacional/importada (24,44%) e Passeio importado (9,29%)
- Sexo do segurado: **Masculino 42,86%**, Feminino 32,55%, Jurídica 19,85%, Sem informação 4,73%
- Faixa etária: mais concentrada em "Maior que 55 anos" (21,13%) e "Entre 36 e 45 anos" (21,03%)
- Região com mais linhas: **SP – Metropolitana de São Paulo (7,38%)**, seguida por SP – Ribeirão Preto/Campinas (6,38%) e PR – Metropolitana de Curitiba (4,20%)

**Sinistralidade por região**
- Por macrorregião, a **Nordeste** aparece com a maior taxa (≈82%), seguida de Centro-Oeste (≈80%) e Norte (≈81%); Sudeste tem a menor taxa entre as macrorregiões informadas (≈71%)
- No ranking por UF, os maiores índices de sinistralidade (faixa "Crítico", acima de 75%) são **Tocantins (95,54%)**, **Bahia (91,82%)**, **Piauí (88,88%)**, Pará (87,50%) e Mato Grosso (86,31%)
- Em quantidade absoluta de sinistros por UF, **São Paulo concentra 45,18%** do total, seguido por Rio de Janeiro (7,87%) e Minas Gerais (7,84%)

**Sinistralidade por categoria de veículo**
- **Utilitários (nacional e importado)** têm a maior taxa de sinistralidade (131,20% — indenização superando o prêmio arrecadado no agregado), seguidos por "Outros" (96,20%) e Passeio importado (85,10%)
- **Ônibus** tem a menor taxa (32,90%)

**Tipos de sinistro (indenização)**
- **Colisão** responde pela maior fatia da indenização total (34,82%), seguida por Perda Total (28,82%) e Roubo/Furto (22,78%)
- Incêndio representa a menor participação (0,95%)

**Ticket médio (top modelos, exposição > 1.000)**
- Os maiores tickets médios de prêmio aparecem concentrados em **veículos pesados/rebocadores** (ex.: Volvo FH 540 Globetrotter 6x4, R$ 9.867,41; Scania Vabis P310 B 8x2, R$ 8.572,91) e em um modelo de passeio de alto padrão (Range Rover Sport HSE 3.0 TDV6, R$ 8.494,17)

**Ticket médio (top 10 modelos, exposição > 1.000)

#	Modelo	Ticket médio  
1	Volvo Rebocador FH 540 Globetrotter 6x4 E5	R$ 9.867,41  
2	Scania Vabis Caminhão P 310 B 8x2 E5	R$ 8.572,91  
3	Range Rover Sport HSE 3.0 TDV6 Diesel	R$ 8.494,17  
4	Volvo Rebocador FH 460 Globetrotter 6x2 E5	R$ 8.343,77  
5	Scania Vabis Rebocador R 440 A 6x2 E5	R$ 7.116,96  
6	Mercedes Benz Rebocador Axor 2544 S Bluetec 5 6x2	R$ 6.523,24  
7	Atego 2430 6x2 2p (diesel)(E5)	R$ 6.382,95  
8	Hilux SW4 SRX Diamond 4x4 2.8 TB Diesel Aut.	R$ 5.528,25  
9	Volvo Rebocador FH 460 6x2 E5	R$ 5.503,75  
10	Volvo Rebocador FH 540 6x4 E5	R$ 5.370,55  

Entre os 10 modelos com maior ticket médio (considerando apenas modelos com exposição > 1.000), 8 são caminhões/rebocadores pesados (destaque para a marca Volvo, presente em 4 das 10 posições) e apenas 2 são veículos de passeio (Range Rover Sport e Hilux SW4), ambos de alto padrão — coerente com o maior valor segurado desses veículos

**Exposição por gênero e faixa etária

Os percentuais desta consulta são calculados dentro de cada gênero (participação da faixa etária sobre o total daquele gênero), não sobre o total geral da base.

Feminino: distribuição mais concentrada em "Entre 36 e 45 anos" (28,76%) e "Maior que 55 anos" (26,51%); apenas 0,74% sem faixa etária informada
Masculino: também concentrado em "Maior que 55 anos" (36,27%) e "Entre 36 e 45 anos" (23,39%); segue o mesmo padrão da base feminina, mas com maior peso na faixa acima de 55 anos
Jurídica: 76,96% das linhas estão em "Não informada" — esperado, já que faixa etária não se aplica a segurados pessoa jurídica
Sem Informação (gênero não informado): 96,89% também caem em "Não informada" para faixa etária — sugere que, quando o gênero não é preenchido, a idade também costuma não ser



## O que os dados mostraram

A sinistralidade média da carteira inteira é **76,92%** — esse é o número de referência para tudo que vem a seguir.

### As cinco regiões que mais preocupam

| Região | Sinistralidade | Desvio da média da carteira | % da indenização |
|---|---|---|---|
| Tocantins | 95,54% | +18,63 p.p. | 0,50% |
| Bahia | 91,82% | +14,91 p.p. | 4,50% |
| Piauí | 88,88% | +11,97 p.p. | 0,65% |
| Pará | 87,50% | +10,59 p.p. | 1,20% |
| Mato Grosso | 86,31% | +9,39 p.p. | 2,14% |

Não é uma região isolada fora da curva — é uma faixa inteira degradando de forma parecida, o que já sinaliza que vale procurar um padrão comum em vez de tratar cada caso separadamente.

**O primeiro ponto que me chamou atenção foi o tamanho real do problema.** Antes de soar alarme: essas cinco regiões juntas respondem por apenas ~9% da indenização total da carteira, e a Bahia sozinha — a maior delas — é só 4,5% do total. São bolsões de risco reais e localizados, não uma ameaça ao resultado agregado. Isso muda o tom da recomendação: vale corrigir, sem pânico.

**O achado que mais me interessou foi que Bahia e Tocantins estão "doentes" de formas opostas.** Ao abrir a sinistralidade em frequência (sinistros por unidade de exposição) e severidade (custo médio por sinistro):

| Região | Frequência de sinistro | Custo médio por sinistro |
|---|---|---|
| Bahia | 0,39 — a mais alta das cinco | R$ 3.760 — a mais baixa |
| Tocantins | 0,25 — a mais baixa das cinco | R$ 7.357 — a mais alta |

A Bahia tem muitos sinistros, mas cada um custa relativamente pouco. Tocantins tem poucos sinistros, mas caros quando acontecem — um perfil mais coerente com perda total ou roubo do que com colisão leve. São dois problemas de natureza diferente escondidos atrás do mesmo número de sinistralidade, e cada um pede uma resposta diferente.

**O achado que eu não esperava foi um problema que atravessa regiões diferentes.** Ao abrir a sinistralidade por categoria de veículo dentro de cada uma das 5 regiões, o quadro completo ficou assim:

| Categoria | BA - Bahia | MT - Mato Grosso | PA - Pará | PI - Piauí | TO - Tocantins |
|---|---|---|---|---|---|
| Motocicleta (nacional e importado) | 52,9% | 58,6% | 36,9% | 55,2% | 32,3% |
| Ônibus (nacional e importado) | 29,2% | 10,0% | 3,9% | 30,2% | 1,7% |
| Outros | 126,3% | 86,6% | **228,5%** | 65,8% | 76,1% |
| Passeio importado | 125,7% | 103,4% | 70,0% | 144,4% | 82,7% |
| Passeio nacional | 89,7% | 84,1% | 73,1% | 90,9% | 87,8% |
| Pick-up (nacional e importado) | 90,4% | 93,2% | 99,2% | 88,9% | 101,6% |
| Utilitários (nacional e importado) | 159,5% | 159,5% | 110,3% | 0,0% | 32,9% |
| Veículo de Carga (nacional e importado) | 87,3% | 51,4% | 72,4% | 60,7% | **146,0%** |

*(células em prejuízo técnico, acima de 100%, destacadas)*

Isso confirmou a suspeita e trouxe um segundo nome para a lista: não é só "Utilitários" (159,5% na Bahia e no Mato Grosso, e ainda 110,3% no Pará — em prejuízo técnico em 3 das 5 regiões). "Passeio importado" segue exatamente o mesmo padrão: 125,7% na Bahia, 103,4% no Mato Grosso e 144,4% no Piauí — também em prejuízo em 3 das 5 regiões, com valores de magnitude parecida entre estados diferentes. Duas categorias distintas repetindo o mesmo comportamento em regiões diferentes é um sinal bem mais forte do que um caso isolado — reforça a hipótese de que o problema está na forma como essas categorias são precificadas, não na geografia onde elas aparecem.

Vale registrar também dois pontos fora desse padrão principal, que têm outra natureza: "Outros" dispara para 228,5% no Pará — um valor tão destoante do resto da linha (65,8% a 126,3% nas demais regiões) que merece investigação à parte, possivelmente um efeito de baixo volume distorcendo o percentual, como já vimos acontecer no cruzamento sexo × idade. E "Veículo de Carga" só aparece em prejuízo em Tocantins (146,0%) — isolado, sem repetir nas outras 4 regiões, o que sugere que ali sim o problema pode ser mais específico do contexto local (frota de carga na região) do que da categoria em si.

Também não encontrei um único tipo de sinistro dominando o resultado: na Bahia, Perda Total, Colisão e Roubo/Furto têm valores próximos entre si; no Mato Grosso, Perda Total e Colisão praticamente empatam. O problema é distribuído, o que sugere que a solução também precisa ser.

**Por fim, um alerta sobre os próprios dados que preferi documentar em vez de esconder.** Ao cruzar sexo e faixa etária, alguns recortes de segurados marcados como "Sem Informação" mostraram sinistralidade acima de 20.000%. Não é erro de cálculo — é o efeito de uma base de prêmio quase nula dividindo um sinistro real (poucas apólices, um sinistro caro, e a divisão explode). Registrei isso explicitamente porque é o tipo de número que, sem contexto, parece um achado forte e na verdade é ruído estatístico. Nos recortes com volume confiável, o sinal real na Bahia é outro: segurados homens entre 26 e 45 anos rodam entre 107% e 123% de sinistralidade, pior que o observado no público feminino equivalente.

## Decisões de qualidade de dados

- Linhas com `exposicao1 = 0` foram mantidas na fato, mas identificadas separadamente na EDA — excluí-las mudaria as métricas de sinistralidade sem necessidade.
- Valores vazios ou em notação científica foram tratados como zero, via `TRY_CAST` + `ISNULL`, de forma consciente e documentada.
- Recortes com prêmio ou exposição muito baixos (como sexo "Sem Informação") produzem sinistralidade estatisticamente não confiável (>1000%) — documentado como limitação, não apresentado como achado.


## 📈 Dashboard (Power BI)

Este projeto também inclui um **dashboard em Power BI**, construído sobre o modelo estrela e as métricas apresentadas neste repositório (medidas DAX de Sinistralidade, Ticket Médio e Exposição, entre outras). O dashboard faz parte do escopo completo do projeto.

🔗 **Link do dashboard/repositório do Power BI:** *https://app.powerbi.com/view?r=eyJrIjoiZTllMGM3MWItZWVhMi00OWQ1LWJkM2MtYzYzYjRmYmRmNjIyIiwidCI6ImIyZTcyZjRjLWMxMzItNDc2NS1iZGMyLTRjNjNjYmQzZmU4YiJ9*

## Camada de visualização (Power BI)

O modelo `fato_casco` + dimensões alimenta o Power BI via Import. Principais medidas DAX:

```dax
Exposicao_Total = SUM(fato_casco[exposicao1])
Premio_Total = SUM(fato_casco[premio1])
Indenizacao_Total =
    SUM(fato_casco[indeniz1]) + SUM(fato_casco[indeniz2]) +
    SUM(fato_casco[indeniz3]) + SUM(fato_casco[indeniz4]) + SUM(fato_casco[indeniz9])
Taxa_Sinistralidade = DIVIDE([Indenizacao_Total], [Premio_Total], 0) * 100
Frequencia_Sinistro = DIVIDE([Qtde_Sinistros], [Exposicao_Total], 0)
Severidade_Media = DIVIDE([Indenizacao_Total], [Qtde_Sinistros], 0)
Sinistralidade_Media_Carteira = CALCULATE([Taxa_Sinistralidade], ALL(dim_regiao))
Desvio_Media_Carteira = [Taxa_Sinistralidade] - [Sinistralidade_Media_Carteira]
```

Três painéis compõem a análise: visão geral da carteira (KPIs, prêmio/indenização por região, mapa de sinistros), sinistralidade por categoria e perfil do segurado, e um terceiro dedicado às cinco regiões mais críticas — de onde vieram os achados acima.



## 👤 Autor

**Cristiane Lima**
[LinkedIn](https://www.linkedin.com/in/cristiane-lima9)


*Projeto desenvolvido como parte da Pós-graduação em Data Analytics (FIAP/Alura), com foco em transição de carreira para Análise de Dados/BI.*
