SELECT
  sigla_uf,
  posicao_ocupacao,
  sexo,
  raca_cor,
  faixa_etaria,
  escolaridade,
  tipo_area,

  -- evolução temporal: renda ponderada por ano
  ROUND(SUM(CASE WHEN ano = '2021' THEN renda_media_habitual * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2021' THEN total_entrevistados END), 0), 2) AS renda_2021,
  ROUND(SUM(CASE WHEN ano = '2022' THEN renda_media_habitual * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2022' THEN total_entrevistados END), 0), 2) AS renda_2022,
  ROUND(SUM(CASE WHEN ano = '2023' THEN renda_media_habitual * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2023' THEN total_entrevistados END), 0), 2) AS renda_2023,
  ROUND(SUM(CASE WHEN ano = '2024' THEN renda_media_habitual * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2024' THEN total_entrevistados END), 0), 2) AS renda_2024,
  ROUND(SUM(CASE WHEN ano = '2025' THEN renda_media_habitual * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2025' THEN total_entrevistados END), 0), 2) AS renda_2025,

  -- evolução temporal: volatilidade ponderada por ano
  ROUND(SUM(CASE WHEN ano = '2021' THEN desvio_relativo_renda_pct * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2021' THEN total_entrevistados END), 0), 4) AS vol_2021,
  ROUND(SUM(CASE WHEN ano = '2022' THEN desvio_relativo_renda_pct * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2022' THEN total_entrevistados END), 0), 4) AS vol_2022,
  ROUND(SUM(CASE WHEN ano = '2023' THEN desvio_relativo_renda_pct * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2023' THEN total_entrevistados END), 0), 4) AS vol_2023,
  ROUND(SUM(CASE WHEN ano = '2024' THEN desvio_relativo_renda_pct * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2024' THEN total_entrevistados END), 0), 4) AS vol_2024,
  ROUND(SUM(CASE WHEN ano = '2025' THEN desvio_relativo_renda_pct * total_entrevistados END) /
        NULLIF(SUM(CASE WHEN ano = '2025' THEN total_entrevistados END), 0), 4) AS vol_2025,

  -- desvio padrão interanual da renda
  ROUND(STDDEV(renda_media_habitual), 2) AS desvio_padrao_interanual,

  -- total de respondentes do segmento
  SUM(total_entrevistados) AS total_respondentes

FROM `credito-pnad-2026.pnad_rend_trab.view_renda_media_uf`
WHERE posicao_ocupacao IN (
  'Conta-própria',
  'Empregado no setor privado sem carteira',
  'Trabalhador doméstico sem carteira',
  'Empregado no setor público sem carteira',
  'Trabalhador familiar auxiliar'
)
GROUP BY sigla_uf, posicao_ocupacao, sexo, raca_cor, faixa_etaria, escolaridade, tipo_area
ORDER BY sigla_uf, posicao_ocupacao