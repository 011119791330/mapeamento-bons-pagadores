-- =====================================================================
-- Sessão 3 — Deflação pelo IPCA
-- Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN
-- =====================================================================
-- Base de deflação: média anual de 2025 (preços de 2025).
-- Fonte do índice: IBGE/SIDRA tabela 1737, variável "Número-índice
--   (base dez/1993 = 100)", série mensal jan/2021 a dez/2025, Brasil.
-- Critério: índice médio dos 12 meses de cada ano. Justificativa: a renda
--   individual da PNAD é um retrato do mês de referência, mas a renda da
--   célula-perfil é a média de respondentes entrevistados ao longo dos 12
--   meses do ano; o deflator coerente é o nível médio de preços do ano.
-- Variáveis deflacionadas: renda_media_efetiva, renda_media_habitual.
-- NÃO deflacionadas: desvio_absoluto_renda (gap usado só em %), 
--   std_renda_efetiva e cv_renda_efetiva (invariantes/adimensionais).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Bloco 1 — Tabela auxiliar de fatores de deflação
-- ---------------------------------------------------------------------
-- NOTA: `ano` é STRING na view base (microdados via basedosdados chegam
-- como string). A auxiliar alinha o tipo (string entre aspas) para o
-- USING(ano) casar. Não se altera a view base por isso — ela é a fonte.
CREATE OR REPLACE TABLE `credito-pnad-2026.pnad_rend_trab.aux_fatores_deflacao_ipca` AS
SELECT * FROM UNNEST([
  STRUCT('2021' AS ano, 5827.7800 AS indice_medio_anual, 1.252765 AS fator_deflacao_base2025),
  STRUCT('2022', 6368.6042, 1.146380),
  STRUCT('2023', 6661.1500, 1.096033),
  STRUCT('2024', 6952.0733, 1.050168),
  STRUCT('2025', 7300.8417, 1.000000)
]);

-- ---------------------------------------------------------------------
-- Bloco 2 — View-filha deflacionada
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf_deflacionada` AS
SELECT
  b.*,
  b.renda_media_efetiva  * f.fator_deflacao_base2025 AS renda_media_efetiva_real,
  b.renda_media_habitual * f.fator_deflacao_base2025 AS renda_media_habitual_real,
  f.fator_deflacao_base2025
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf` AS b
LEFT JOIN `credito-pnad-2026.pnad_rend_trab.aux_fatores_deflacao_ipca` AS f
  USING (ano);

-- ---------------------------------------------------------------------
-- Bloco 3 — Validação de integridade do JOIN e da deflação
-- ---------------------------------------------------------------------
SELECT
  ano,
  COUNTIF(fator_deflacao_base2025 IS NULL) AS celulas_sem_fator,
  ROUND(AVG(renda_media_efetiva), 2)       AS renda_efetiva_nominal_media,
  ROUND(AVG(renda_media_efetiva_real), 2)  AS renda_efetiva_real_media,
  ROUND(AVG(fator_deflacao_base2025), 4)   AS fator_aplicado
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf_deflacionada`
GROUP BY ano
ORDER BY ano;
