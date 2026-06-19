-- =====================================================================
-- VALIDAÇÃO PRÉ-PRODUÇÃO — View Base v02 (Sessão 4, Subseção B')
-- Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN
-- =====================================================================
-- Rodar ANTES do CREATE OR REPLACE VIEW. Cada bloco é independente.
-- Objetivo: confirmar que a reconstrução não quebrou nenhuma dimensão
-- e que os pontos de risco identificados na escrita estão controlados.
--
-- Pré-requisito: salvar a v02 como view temporária OU rodar os blocos
-- 4–7 substituindo a referência por uma subquery com o SELECT da v02.
-- Para agilizar, sugere-se materializar a v02 como view ANTES (o risco
-- já foi mitigado nos blocos 1–3, que leem a tabela microdados direto).
-- =====================================================================


-- =====================================================================
-- BLOCO 1 — Formato dos códigos V2005 (zero à esquerda?)
-- Risco: se vier '1' e o CASE usar '01', a dimensão inteira cai no ELSE.
-- (Você já ajustou removendo zeros à esquerda — este bloco CONFIRMA.)
-- =====================================================================
SELECT
  V2005,
  LENGTH(V2005) AS n_caracteres,
  COUNT(*)      AS n
FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10')
GROUP BY V2005
ORDER BY SAFE_CAST(V2005 AS INT64);


-- =====================================================================
-- BLOCO 2 — Existência e domínio de V4040 e V40403
-- Confirma nomes literais e amplitude (V4040: 1–4; V40403: anos).
-- =====================================================================
SELECT
  'V4040'  AS variavel,
  MIN(SAFE_CAST(V4040 AS INT64))  AS minimo,
  MAX(SAFE_CAST(V4040 AS INT64))  AS maximo,
  COUNT(DISTINCT V4040)           AS n_distintos,
  COUNTIF(V4040 IS NULL)          AS n_nulos
FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10')
UNION ALL
SELECT
  'V40403',
  MIN(SAFE_CAST(V40403 AS INT64)),
  MAX(SAFE_CAST(V40403 AS INT64)),
  COUNT(DISTINCT V40403),
  COUNTIF(V40403 IS NULL)
FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10');


-- =====================================================================
-- BLOCO 3 — Risco do V40403 nulo dentro da faixa 4 do V4040
-- Quantos respondentes têm V4040='4' MAS V40403 nulo/zerado?
-- Esses, sem o guard que você adicionou, cairiam em "20+ anos".
-- Esperado após seu ajuste: linha 'PROBLEMA' com n=0 (ou tratada).
-- =====================================================================
SELECT
  CASE
    WHEN SAFE_CAST(V40403 AS INT64) IS NULL THEN 'FAIXA 4 com V40403 NULO/inválido'
    ELSE 'FAIXA 4 com V40403 válido'
  END AS diagnostico,
  COUNT(*) AS n
FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10')
  AND SAFE_CAST(V4040 AS INT64) = 4
GROUP BY diagnostico;


-- =====================================================================
-- BLOCO 4 — Cobertura de media_horas_trabalhadas (V4039) por ocupação
-- Fecha pendência da 2.5: a nulidade de horas era artefato do V4019.
-- Lê a v02 já materializada. Esperado: nulidade baixa e não concentrada
-- estruturalmente em uma única posicao_ocupacao.
-- =====================================================================
SELECT
  posicao_ocupacao,
  COUNT(*)                                          AS n_celulas,
  COUNTIF(media_horas_trabalhadas IS NULL)          AS celulas_horas_null,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(media_horas_trabalhadas IS NULL), COUNT(*)), 2) AS pct_null
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`
GROUP BY posicao_ocupacao
ORDER BY pct_null DESC;


-- =====================================================================
-- BLOCO 5 — Contagem de células e checagem das dimensões novas
-- Confirma volume total de células e o comportamento de rm_ride (NULL
-- legítimo) e situacao_domicilio (Urbana/Rural). Compare nº de células
-- com a v01 (~3.476) — deve MUDAR (rm_ride e situacao_domicilio agora
-- particionam mais finamente).
-- =====================================================================
SELECT
  COUNT(*)                                       AS total_celulas,
  COUNTIF(rm_ride IS NULL)                        AS celulas_sem_rm,
  COUNT(DISTINCT rm_ride)                         AS rm_distintas,
  COUNTIF(situacao_domicilio = 'Rural')          AS celulas_rural,
  COUNTIF(situacao_domicilio = 'Urbana')         AS celulas_urbana,
  COUNTIF(situacao_domicilio = 'Não determinado') AS celulas_area_indef,
  COUNTIF(tempo_no_trabalho = 'Não determinado') AS celulas_tempo_indef,
  COUNTIF(posicao_no_domicilio = 'Não determinado') AS celulas_pos_dom_indef
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`;


-- =====================================================================
-- BLOCO 6 — Sanidade da dispersão ponderada (std/CV)
-- Confirma que a variância ponderada não produziu absurdos: CV >= 0,
-- std >= 0, e quantas células ficaram NULL (degeneradas / 1 respondente).
-- Compare nº de CV null com a v01 (eram 42).
-- =====================================================================
SELECT
  COUNT(*)                              AS total_celulas,
  COUNTIF(cv_renda_efetiva IS NULL)     AS cv_null,
  COUNTIF(std_renda_efetiva IS NULL)    AS std_null,
  COUNTIF(cv_renda_efetiva < 0)         AS cv_negativo_ERRO,
  COUNTIF(std_renda_efetiva < 0)        AS std_negativo_ERRO,
  COUNTIF(cv_renda_efetiva > 2)         AS cv_acima_2,
  ROUND(MIN(cv_renda_efetiva), 4)       AS cv_min,
  ROUND(APPROX_QUANTILES(cv_renda_efetiva, 100)[OFFSET(50)], 4) AS cv_mediana,
  ROUND(MAX(cv_renda_efetiva), 4)       AS cv_max
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`;


-- =====================================================================
-- BLOCO 7 — Impacto da ponderação nas rendas (v01 simples vs v02 ponderada)
-- Compara renda média simples vs ponderada na MESMA partição por ano e
-- posicao_ocupacao, lendo a tabela microdados direto (não depende da view).
-- Esperado (A.2): desvio na casa de 2–4%, uniforme — sem inversão de leitura.
-- =====================================================================
SELECT
  ano,
  CASE VD4009
    WHEN '2' THEN 'Privado sem carteira'
    WHEN '4' THEN 'Doméstico sem carteira'
    WHEN '6' THEN 'Público sem carteira'
    WHEN '9' THEN 'Conta-própria'
    WHEN '10' THEN 'Familiar auxiliar'
  END AS posicao_ocupacao,
  ROUND(AVG(VD4020), 2)                                                AS renda_simples,
  ROUND(SAFE_DIVIDE(SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020),
                    SUM(SAFE_CAST(V1028 AS FLOAT64))), 2)              AS renda_ponderada,
  ROUND(100 * SAFE_DIVIDE(
    SAFE_DIVIDE(SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020),
                SUM(SAFE_CAST(V1028 AS FLOAT64))) - AVG(VD4020),
    AVG(VD4020)), 2)                                                   AS desvio_pct
FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10')
  AND VD4020 IS NOT NULL
GROUP BY ano, posicao_ocupacao
ORDER BY ano, posicao_ocupacao;
