SELECT
  ano,
  posicao_ocupacao,
  grupamento_atividade,
  COUNT(*) AS n_celulas,
  SUM(total_entrevistados) AS total_pessoas,
  ROUND(SUM(renda_media_habitual * total_entrevistados) / SUM(total_entrevistados), 2) AS renda_hab_ponderada,
  ROUND(SUM(cv_renda_efetiva * total_entrevistados) / SUM(total_entrevistados), 4) AS cv_renda_ponderado
FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`
GROUP BY ano, posicao_ocupacao, grupamento_atividade
ORDER BY ano, posicao_ocupacao, renda_hab_ponderada DESC