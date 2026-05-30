-- Perfil regional por UF recorte social

SELECT
  sigla_uf,
  tipo_area,
  posicao_ocupacao,
  sexo,
  raca_cor,
  faixa_etaria,
  escolaridade,
  SUM(total_entrevistados) AS total_respondentes,
  ROUND(SUM(renda_media_habitual * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_hab_ponderada,
  ROUND(SUM(renda_media_efetiva * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_ef_ponderada,
  ROUND(SUM(desvio_relativo_renda_pct * total_entrevistados) / SUM(total_entrevistados), 4) AS dev_rel_renda_ponderada,
  ROUND(SUM(media_moradores_domicilio * total_entrevistados) / SUM(total_entrevistados), 2) AS moradores_ponderado
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`

GROUP BY sigla_uf, tipo_area, posicao_ocupacao, sexo, raca_cor, faixa_etaria, escolaridade
ORDER BY sigla_uf, renda_hab_ponderada DESC