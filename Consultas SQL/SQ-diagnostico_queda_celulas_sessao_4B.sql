-- =====================================================================
-- DIAGNÓSTICO — Queda de células (v01 ~3.476 → v02 1.008)
-- Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN
-- =====================================================================
-- Objetivo: isolar QUAL mudança da v01→v02 derrubou a contagem de
-- células. Estratégia: contar células sobreviventes ao HAVING >= 30
-- sob diferentes conjuntos de dimensões no GROUP BY, lendo a tabela
-- microdados direto (reproduz a lógica da view sem depender dela).
--
-- Cada bloco isola UMA variável de agrupamento. Comparando as contagens,
-- vemos qual dimensão fragmenta a base. Empilhados via UNION ALL no
-- padrão "raio-x".
--
-- IMPORTANTE: aqui NÃO ponderamos nem aplicamos renda — contamos só
-- células que atingem 30 respondentes sob cada GROUP BY. O objetivo é
-- medir o efeito da GRANULARIDADE, não da renda. Um bloco final isola
-- o efeito do filtro de renda separadamente.
-- =====================================================================


-- =====================================================================
-- BLOCO A — Contagem de células por configuração de GROUP BY
-- Cada linha = um cenário. Comparar a coluna n_celulas entre cenários
-- mostra o custo marginal de cada dimensão.
-- =====================================================================

-- Cenário 1: dimensões da v01 (SEM situacao_domicilio, COM rm_ride,
-- mas com tempo_no_trabalho de 5 faixas ANTIGAS — aqui aproximado pela
-- variável V4032 original, que era o tempo errado da v01).
-- NOTA: não dá para reproduzir exatamente as 5 faixas erradas; usamos
-- a contagem de combinações como proxy. Foco nas comparações 2 vs 3 vs 4.

WITH base AS (
  SELECT
    sigla_uf,
    CAST(ano AS STRING) AS ano,
    CASE V1023
      WHEN '1' THEN 'Capital' WHEN '2' THEN 'Resto da RM'
      WHEN '3' THEN 'Resto da RIDE' WHEN '4' THEN 'Resto da UF'
      ELSE 'Não determinado' END AS tipo_area,
    rm_ride,
    CASE V1022 WHEN '1' THEN 'Urbana' WHEN '2' THEN 'Rural'
      ELSE 'Não determinado' END AS situacao_domicilio,
    V2007 AS sexo, V2010 AS raca_cor, VD3004 AS escolaridade,
    CASE
      WHEN V2009 < 18 THEN '0-17' WHEN V2009 < 30 THEN '18-29'
      WHEN V2009 < 45 THEN '30-44' WHEN V2009 < 60 THEN '45-59'
      ELSE '60+' END AS faixa_etaria,
    V2005 AS posicao_no_domicilio,
    VD4009 AS posicao_ocupacao,
    VD4010 AS grupamento_atividade,
    -- tempo em 7 faixas (v02)
    CASE
      WHEN SAFE_CAST(V4040 AS INT64) = 1 THEN '1'
      WHEN SAFE_CAST(V4040 AS INT64) = 2 THEN '2'
      WHEN SAFE_CAST(V4040 AS INT64) = 3 THEN '3'
      WHEN SAFE_CAST(V4040 AS INT64) = 4 THEN
        CASE
          WHEN SAFE_CAST(V40403 AS INT64) <= 4 THEN '4'
          WHEN SAFE_CAST(V40403 AS INT64) <= 9 THEN '5'
          WHEN SAFE_CAST(V40403 AS INT64) <= 19 THEN '6'
          ELSE '7' END
      ELSE 'ND' END AS tempo_7,
    -- tempo em 4 faixas nativas (sem abrir o balde) — proxy da granularidade menor
    CASE
      WHEN SAFE_CAST(V4040 AS INT64) = 1 THEN '1'
      WHEN SAFE_CAST(V4040 AS INT64) = 2 THEN '2'
      WHEN SAFE_CAST(V4040 AS INT64) = 3 THEN '3'
      WHEN SAFE_CAST(V4040 AS INT64) = 4 THEN '4'
      ELSE 'ND' END AS tempo_4
  FROM `basedosdados.br_ibge_pnadc.microdados`
  WHERE ano BETWEEN 2021 AND 2025
    AND VD4009 IN ('2', '4', '6', '9', '10')
)

SELECT 'C1: v02 completa (rm_ride + sit_dom + tempo_7)' AS cenario,
       COUNT(*) AS n_celulas FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area, rm_ride, situacao_domicilio,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_7
  HAVING COUNT(*) >= 30
)
UNION ALL
SELECT 'C2: SEM rm_ride (sit_dom + tempo_7)',
       COUNT(*) FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area, situacao_domicilio,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_7
  HAVING COUNT(*) >= 30
)
UNION ALL
SELECT 'C3: SEM situacao_domicilio (rm_ride + tempo_7)',
       COUNT(*) FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area, rm_ride,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_7
  HAVING COUNT(*) >= 30
)
UNION ALL
SELECT 'C4: SEM rm_ride E SEM sit_dom (tempo_7)',
       COUNT(*) FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_7
  HAVING COUNT(*) >= 30
)
UNION ALL
SELECT 'C5: v01-like (rm_ride, tempo_4, SEM sit_dom)',
       COUNT(*) FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area, rm_ride,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_4
  HAVING COUNT(*) >= 30
)
UNION ALL
SELECT 'C6: tempo_4, SEM rm_ride, SEM sit_dom',
       COUNT(*) FROM (
  SELECT 1 FROM base
  GROUP BY sigla_uf, ano, tipo_area,
           sexo, raca_cor, escolaridade, faixa_etaria,
           posicao_no_domicilio, posicao_ocupacao, grupamento_atividade, tempo_4
  HAVING COUNT(*) >= 30
)
ORDER BY cenario;
