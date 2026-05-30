SELECT
  ano,
  escolaridade,
  raca_cor,
  faixa_etaria,
  tipo_area,
  tempo_no_trabalho,
  sexo,
  COUNT(*) AS n_celulas,
  SUM(total_entrevistados) AS total_pessoas,
  ROUND(SUM(renda_media_habitual * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_hab_ponderada,
  ROUND(SUM(desvio_relativo_renda_pct * total_entrevistados) / SUM(total_entrevistados), 4) AS desvio_renda_ponderado,
  ROUND(SUM(cv_renda_efetiva * total_entrevistados) / SUM(total_entrevistados), 4) AS cv_renda_ponderado
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`
GROUP BY ano, escolaridade, raca_cor, faixa_etaria, tipo_area, tempo_no_trabalho, sexo
ORDER BY renda_hab_ponderada DESC