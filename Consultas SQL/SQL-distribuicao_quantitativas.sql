SELECT
  ano,
  posicao_ocupacao,
  COUNT(*) AS n_celulas,
  SUM(total_entrevistados) AS total_pessoas,
  ROUND(SUM(renda_media_habitual * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_hab_ponderada,
  ROUND(SUM(renda_media_efetiva * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_ef_ponderada,
  ROUND(SUM(desvio_relativo_renda_pct * total_entrevistados) / SUM(total_entrevistados), 4) AS desvio_renda_ponderado,
  ROUND(SUM(cv_renda_efetiva * total_entrevistados) / SUM(total_entrevistados), 4) AS cv_renda_ponderado,
  ROUND(SUM(media_moradores_domicilio * total_entrevistados) / SUM(total_entrevistados), 2) AS moradores_ponderado,
  ROUND(SUM(media_horas_trabalhadas * total_entrevistados) / SUM(total_entrevistados), 2) AS horas_ponderadas
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`
GROUP BY ano, posicao_ocupacao
ORDER BY ano, renda_hab_ponderada DESC