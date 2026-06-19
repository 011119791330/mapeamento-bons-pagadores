-- =====================================================================
-- VIEW BASE v02 — Reconstrução pós-auditoria (Sessão 4, Subseção B)
-- Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN
-- Objeto BigQuery: credito-pnad-2026.pnad_rend_trab.view_renda_media_uf
-- =====================================================================
-- Reconstrói a view base aplicando as correções diagnosticadas na
-- Subseção 4-A. Nome do objeto MANTIDO (estável) para não quebrar o
-- encadeamento da view-filha deflacionada. Versionamento vive no arquivo.
--
-- CORREÇÕES APLICADAS (ref. A.3 / A.5):
--   1. Ponderação por V1028 (peso de pós-estratificação) em TODAS as
--      médias: SUM(w*x)/SUM(w) no lugar de AVG(x).
--   2. V1022 adicionado como dimensão urbano/rural (situacao_domicilio).
--   3. V1023 relabel: Capital / Resto da RM / Resto da RIDE / Resto da UF
--      (removidos os rótulos errados "Urbano fora de RM" e "Rural").
--   4. V2005 remapeado para as 19 categorias oficiais.
--   5. V4039 substitui V4019 para media_horas_trabalhadas (1–120h reais).
--   6. V4040 + V40403 substituem V4032 para tempo_no_trabalho (7 faixas).
--   7. Dispersão (std/CV) agora PONDERADA por V1028 (variância ponderada
--      manual com correção de Bessel generalizada).
--
-- ADIÇÕES À VIEW:
--   - rm_ride: promovido ao SELECT como CÓDIGO CRU (chave de junção
--     territorial; decodificação adiada para a Sessão 5 via dicionário).
--   - situacao_domicilio: novo eixo urbano/rural (V1022).
--   - populacao_expandida: SUM(V1028) — destrava dimensionamento (P4.5).
--
-- NOTAS TÉCNICAS:
--   - Microdados da basedosdados chegam como STRING → SAFE_CAST em todo
--     ponto numérico (peso, horas, faixas de tempo).
--   - peso_amostral = SAFE_CAST(V1028 AS FLOAT64).
--   - HAVING mantido sobre COUNT(*) bruto (robustez amostral = nº de
--     respondentes reais, não população expandida).
-- =====================================================================

SELECT
  sigla_uf,
  CAST(ano AS STRING) AS ano,

  -- ===================================================================
  -- EIXOS TERRITORIAIS (dois eixos transversais — ver A.3)
  -- ===================================================================

  -- V1023: tipo de área (RELABEL — 4 categorias reais, não 5)
  CASE V1023
    WHEN '1' THEN 'Capital'
    WHEN '2' THEN 'Resto da RM'
    WHEN '3' THEN 'Resto da RIDE'
    WHEN '4' THEN 'Resto da UF'
    ELSE 'Não determinado'
  END AS tipo_area,

  -- rm_ride: CÓDIGO CRU (chave de junção; NULL = fora de RM/RIDE).
  -- Decodificação para rótulos oficiais é tarefa da Sessão 5.
  rm_ride,

  -- V1022: situação do domicílio (NOVO — eixo urbano/rural, transversal)
  CASE V1022
    WHEN '1' THEN 'Urbana'
    WHEN '2' THEN 'Rural'
    ELSE 'Não determinado'
  END AS situacao_domicilio,

  -- ===================================================================
  -- DEMOGRAFIA
  -- ===================================================================
  CASE V2007
    WHEN '1' THEN 'Homem'
    WHEN '2' THEN 'Mulher'
    ELSE 'Não identificado'
  END AS sexo,

  CASE V2010
    WHEN '1' THEN 'Branca'
    WHEN '2' THEN 'Preta'
    WHEN '3' THEN 'Amarela'
    WHEN '4' THEN 'Parda'
    WHEN '5' THEN 'Indígena'
    WHEN '9' THEN 'Ignorado'
    ELSE 'Não declarado'
  END AS raca_cor,

  CASE VD3004
    WHEN '1' THEN 'Sem instrução e menos de 1 ano de estudo'
    WHEN '2' THEN 'Fundamental incompleto ou equivalente'
    WHEN '3' THEN 'Fundamental completo ou equivalente'
    WHEN '4' THEN 'Médio incompleto ou equivalente'
    WHEN '5' THEN 'Médio completo ou equivalente'
    WHEN '6' THEN 'Superior incompleto ou equivalente'
    WHEN '7' THEN 'Superior completo'
    ELSE 'Não determinado'
  END AS escolaridade,

  CASE
    WHEN V2009 < 18 THEN '0-17 anos'
    WHEN V2009 < 30 THEN '18-29 anos'
    WHEN V2009 < 45 THEN '30-44 anos'
    WHEN V2009 < 60 THEN '45-59 anos'
    ELSE '60+ anos'
  END AS faixa_etaria,

  -- ===================================================================
  -- POSIÇÃO NO DOMICÍLIO (V2005 — 19 CATEGORIAS OFICIAIS, ver A.5)
  -- ===================================================================
  CASE V2005
    WHEN '01' THEN 'Pessoa responsável'
    WHEN '02' THEN 'Cônjuge/companheiro(a) de sexo diferente'
    WHEN '03' THEN 'Cônjuge/companheiro(a) do mesmo sexo'
    WHEN '04' THEN 'Filho(a) do responsável e do cônjuge'
    WHEN '05' THEN 'Filho(a) somente do responsável'
    WHEN '06' THEN 'Enteado(a)'
    WHEN '07' THEN 'Genro ou nora'
    WHEN '08' THEN 'Pai, mãe, padrasto ou madrasta'
    WHEN '09' THEN 'Sogro(a)'
    WHEN '10' THEN 'Neto(a)'
    WHEN '11' THEN 'Bisneto(a)'
    WHEN '12' THEN 'Irmão ou irmã'
    WHEN '13' THEN 'Avô ou avó'
    WHEN '14' THEN 'Outro parente'
    WHEN '15' THEN 'Agregado(a)'
    WHEN '16' THEN 'Convivente'
    WHEN '17' THEN 'Pensionista'
    WHEN '18' THEN 'Empregado(a) doméstico(a)'
    WHEN '19' THEN 'Parente do(a) empregado(a) doméstico(a)'
    ELSE 'Não determinado'
  END AS posicao_no_domicilio,

  -- ===================================================================
  -- TRABALHO E OCUPAÇÃO
  -- ===================================================================
  CASE VD4009
    WHEN '2' THEN 'Empregado no setor privado sem carteira'
    WHEN '4' THEN 'Trabalhador doméstico sem carteira'
    WHEN '6' THEN 'Empregado no setor público sem carteira'
    WHEN '9' THEN 'Conta-própria'
    WHEN '10' THEN 'Trabalhador familiar auxiliar'
  END AS posicao_ocupacao,

  CASE VD4010
    WHEN '1' THEN 'Agricultura, pecuária, produção florestal, pesca e aquicultura'
    WHEN '2' THEN 'Indústria geral'
    WHEN '3' THEN 'Construção'
    WHEN '4' THEN 'Comércio, reparação de veículos automotores e motocicletas'
    WHEN '5' THEN 'Transporte, armazenagem e correio'
    WHEN '6' THEN 'Alojamento e alimentação'
    WHEN '7' THEN 'Informação, comunicação e atividades financeiras, imobiliárias, profissionais e administrativas'
    WHEN '8' THEN 'Administração pública, defesa e seguridade social'
    WHEN '9' THEN 'Educação, saúde humana e serviços sociais'
    WHEN '10' THEN 'Outros serviços'
    WHEN '11' THEN 'Serviços domésticos'
    WHEN '12' THEN 'Atividades mal definidas'
    ELSE 'Não determinado'
  END AS grupamento_atividade,

  -- tempo_no_trabalho: 7 FAIXAS (V4040 curtas + V40403 abre "2 anos ou mais")
  -- V4040: 1=Menos de 1 mês · 2=1 mês a <1 ano · 3=1 a <2 anos · 4=2 anos ou mais
  -- V40403 (anos completos no trabalho) abre a faixa 4.
  CASE
    WHEN SAFE_CAST(V4040 AS INT64) = 1 THEN '1. Menos de 1 mês'
    WHEN SAFE_CAST(V4040 AS INT64) = 2 THEN '2. 1 mês a menos de 1 ano'
    WHEN SAFE_CAST(V4040 AS INT64) = 3 THEN '3. 1 a menos de 2 anos'
    WHEN SAFE_CAST(V4040 AS INT64) = 4 THEN
      CASE
        WHEN SAFE_CAST(V40403 AS INT64) <= 4  THEN '4. 2 a 4 anos'
        WHEN SAFE_CAST(V40403 AS INT64) <= 9  THEN '5. 5 a 9 anos'
        WHEN SAFE_CAST(V40403 AS INT64) <= 19 THEN '6. 10 a 19 anos'
        ELSE '7. 20 anos ou mais'
      END
    ELSE 'Não determinado'
  END AS tempo_no_trabalho,

  -- ===================================================================
  -- MÉDIAS PONDERADAS POR V1028 (decisão B da auditoria 4-A)
  -- Padrão: SUM(peso * x) / SUM(peso), com SAFE_CAST do peso (STRING).
  -- ===================================================================
  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * CAST(V2001 AS FLOAT64)),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS media_moradores_domicilio,

  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * CAST(VD2003 AS FLOAT64)),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS media_filhos,

  -- V4039 (1–120h reais) substitui V4019 (Sim/Não). Ponderada.
  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * SAFE_CAST(V4039 AS FLOAT64)),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS media_horas_trabalhadas,

  -- ===================================================================
  -- RENDA — MÉDIAS PONDERADAS
  -- ===================================================================
  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS renda_media_efetiva,

  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4016),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS renda_media_habitual,

  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * (VD4020 - VD4016)),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS desvio_absoluto_renda,

  SAFE_DIVIDE(
    SUM(SAFE_CAST(V1028 AS FLOAT64) * SAFE_DIVIDE(VD4020 - VD4016, VD4016)),
    SUM(SAFE_CAST(V1028 AS FLOAT64))
  ) AS desvio_relativo_renda_pct,

  -- ===================================================================
  -- DISPERSÃO INTRA-CÉLULA PONDERADA (item 7 de A.5)
  -- Variância ponderada amostral com correção de Bessel generalizada:
  --   s²_w = [ Σw·x² − (Σw·x)²/Σw ] / [ Σw − Σw²/Σw ]
  -- SAFE.SQRT e SAFE_DIVIDE blindam células degeneradas → NULL.
  -- NOTA: aproximação de peso de frequência; não é estimativa de
  -- variância sob desenho amostral complexo (proporcionalidade).
  -- ===================================================================
  SAFE.SQRT(
    SAFE_DIVIDE(
      SUM(SAFE_CAST(V1028 AS FLOAT64) * POW(VD4020, 2))
        - SAFE_DIVIDE(POW(SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020), 2),
                      SUM(SAFE_CAST(V1028 AS FLOAT64))),
      SUM(SAFE_CAST(V1028 AS FLOAT64))
        - SAFE_DIVIDE(SUM(POW(SAFE_CAST(V1028 AS FLOAT64), 2)),
                      SUM(SAFE_CAST(V1028 AS FLOAT64)))
    )
  ) AS std_renda_efetiva,

  SAFE_DIVIDE(
    SAFE.SQRT(
      SAFE_DIVIDE(
        SUM(SAFE_CAST(V1028 AS FLOAT64) * POW(VD4020, 2))
          - SAFE_DIVIDE(POW(SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020), 2),
                        SUM(SAFE_CAST(V1028 AS FLOAT64))),
        SUM(SAFE_CAST(V1028 AS FLOAT64))
          - SAFE_DIVIDE(SUM(POW(SAFE_CAST(V1028 AS FLOAT64), 2)),
                        SUM(SAFE_CAST(V1028 AS FLOAT64)))
      )
    ),
    SAFE_DIVIDE(
      SUM(SAFE_CAST(V1028 AS FLOAT64) * VD4020),
      SUM(SAFE_CAST(V1028 AS FLOAT64))
    )
  ) AS cv_renda_efetiva,

  -- ===================================================================
  -- CONTAGENS
  -- ===================================================================
  CAST(COUNT(*) AS INT64) AS total_entrevistados,        -- robustez amostral
  SUM(SAFE_CAST(V1028 AS FLOAT64)) AS populacao_expandida -- dimensionamento (P4.5)

FROM `basedosdados.br_ibge_pnadc.microdados`
WHERE ano BETWEEN 2021 AND 2025
  AND VD4009 IN ('2', '4', '6', '9', '10')  -- escopo: informais e sem carteira
GROUP BY
  sigla_uf,
  ano,
  tipo_area,
  rm_ride,
  situacao_domicilio,
  sexo,
  raca_cor,
  escolaridade,
  faixa_etaria,
  posicao_no_domicilio,
  posicao_ocupacao,
  grupamento_atividade,
  tempo_no_trabalho
HAVING total_entrevistados >= 30
  AND renda_media_efetiva IS NOT NULL
ORDER BY renda_media_efetiva DESC
