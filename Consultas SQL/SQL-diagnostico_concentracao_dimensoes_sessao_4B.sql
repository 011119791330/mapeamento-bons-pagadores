-- =====================================================================
-- DIAGNÓSTICO — Concentração das dimensões categóricas
-- Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN
-- =====================================================================
-- Objetivo: para cada dimensão do GROUP BY, medir quantas categorias
-- tem e quão concentrada é a distribuição. Variáveis muito concentradas
-- (categoria dominante leva grande %) fragmentam a base via cauda longa
-- de categorias raras — candidatas a reagrupamento.
--
-- Métricas por variável:
--   n_categorias       — quantos valores distintos
--   pct_dominante      — % de respondentes na categoria mais comum
--   pct_top3           — % acumulada nas 3 categorias mais comuns
--   n_cat_relevantes   — categorias com >= 1% do total (resto é cauda)
--
-- Leitura: pct_dominante alto + n_cat_relevantes baixo = forte candidata
-- a reagrupar (juntar a cauda perde pouca informação, ganha massa).
--
-- Lê microdados direto, no escopo do projeto.
-- =====================================================================

WITH escopo AS (
  SELECT
    V2005, V2010, VD3004, VD4010, V2007,
    CASE
      WHEN V2009 < 18 THEN '0-17' WHEN V2009 < 30 THEN '18-29'
      WHEN V2009 < 45 THEN '30-44' WHEN V2009 < 60 THEN '45-59'
      ELSE '60+' END AS faixa_etaria,
    CASE V1023
      WHEN '1' THEN 'Capital' WHEN '2' THEN 'Resto da RM'
      WHEN '3' THEN 'Resto da RIDE' WHEN '4' THEN 'Resto da UF'
      ELSE 'ND' END AS tipo_area
  FROM `basedosdados.br_ibge_pnadc.microdados`
  WHERE ano BETWEEN 2021 AND 2025
    AND VD4009 IN ('2', '4', '6', '9', '10')
),
total AS (SELECT COUNT(*) AS n FROM escopo)

-- Função-padrão por variável: agrega contagem por categoria, calcula
-- participação, e resume. Empilhado via UNION ALL.

SELECT * FROM (
  -- posicao_no_domicilio (V2005) — 19 categorias, suspeita principal
  SELECT
    'posicao_no_domicilio (V2005)' AS variavel,
    COUNT(*)                        AS n_categorias,
    ROUND(100 * MAX(pct), 1)        AS pct_dominante,
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1) AS pct_top3,
    COUNTIF(pct >= 0.01)            AS n_cat_acima_1pct
  FROM (
    SELECT V2005,
           COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY V2005
  )
)
UNION ALL
SELECT * FROM (
  SELECT 'raca_cor (V2010)', COUNT(*),
    ROUND(100 * MAX(pct), 1),
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1),
    COUNTIF(pct >= 0.01)
  FROM (
    SELECT V2010, COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY V2010
  )
)
UNION ALL
SELECT * FROM (
  SELECT 'escolaridade (VD3004)', COUNT(*),
    ROUND(100 * MAX(pct), 1),
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1),
    COUNTIF(pct >= 0.01)
  FROM (
    SELECT VD3004, COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY VD3004
  )
)
UNION ALL
SELECT * FROM (
  SELECT 'grupamento_atividade (VD4010)', COUNT(*),
    ROUND(100 * MAX(pct), 1),
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1),
    COUNTIF(pct >= 0.01)
  FROM (
    SELECT VD4010, COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY VD4010
  )
)
UNION ALL
SELECT * FROM (
  SELECT 'faixa_etaria', COUNT(*),
    ROUND(100 * MAX(pct), 1),
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1),
    COUNTIF(pct >= 0.01)
  FROM (
    SELECT faixa_etaria, COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY faixa_etaria
  )
)
UNION ALL
SELECT * FROM (
  SELECT 'tipo_area (V1023)', COUNT(*),
    ROUND(100 * MAX(pct), 1),
    ROUND(100 * SUM(CASE WHEN rk <= 3 THEN pct ELSE 0 END), 1),
    COUNTIF(pct >= 0.01)
  FROM (
    SELECT tipo_area, COUNT(*) / (SELECT n FROM total) AS pct,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
    FROM escopo GROUP BY tipo_area
  )
)
ORDER BY pct_dominante DESC;
