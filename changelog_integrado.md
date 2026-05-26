# Changelog — Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN

## Objetivo

Identificar, via dados públicos (IBGE, Banco Central, Ipea e outras bases),
o perfil de pessoas potencialmente boas pagadoras que estão fora do radar de
crédito e inclusão financeira do Sistema Financeiro Nacional (SFN).

Conceito central: **thin file** — indivíduos com histórico de crédito
inexistente ou insuficiente, não necessariamente inadimplentes.

O projeto possui natureza **exploratória e analítica**, não preditiva e não
regulatória. Não pretende representar mecanismo formal de concessão de crédito.

---

## Estrutura do Projeto

| Sessão | Descrição | Status |
|--------|-----------|--------|
| 1 | Estruturação da base (view, variáveis, filtros) | ✅ Concluída |
| 2 | EDA completa (quantitativas, qualitativas, regional, temporal) | 🔜 Próxima |
| 3 | Deflação pelo IPCA | ⏳ Pendente |
| 4 | Construção e calibração do score | ⏳ Pendente |
| 5 | Geointeligência (cruzamento com ESTBAN e Censo) | ⏳ Pendente |
| 6 | Visualização e entregável final | ⏳ Pendente |

---

## Sessão 1 — Estruturação da Base e Arquitetura Analítica
**Status:** Concluída

---

### 1.1 Fontes de Dados

| Fonte | Finalidade |
|-------|------------|
| PNAD Contínua (IBGE) | Perfil socioeconômico individual — base primária |
| Censo Demográfico (IBGE) | Estrutura domiciliar, territorial e características urbanas |
| ESTBAN (Banco Central) | Profundidade financeira regional |
| IPEAData | Indicadores econômicos complementares e deflator IPCA |
| Banco Central do Brasil | Indicadores econômicos, monetários e financeiros |

- Microdados PNAD Contínua — período: **2021 a 2025**
- Unidade primária de análise: **indivíduo respondente**
- Tabela utilizada: `basedosdados.br_ibge_pnadc.microdados`

---

### 1.2 Recorte Populacional

Foco em trabalhadores **fora do mercado formal com carteira assinada**,
segmento potencialmente sub-bancarizado e sub-representado nos mecanismos
tradicionais de avaliação de crédito.

**Incluídos:**
- Trabalhadores por conta própria
- Empregados sem carteira assinada (setor privado e doméstico)
- Empregados públicos sem vínculo formal
- Trabalhadores familiares auxiliares

**Excluídos:**
- Empregados com carteira assinada
- Servidores públicos (estatutários)
- Militares

*Justificativa:* reduzir viés institucional e concentrar o modelo em grupos
com menor acesso histórico ao crédito formal.

---

### 1.3 Variáveis da View Base (Versão Reconstruída)

| Variável | Descrição |
|----------|-----------|
| `sigla_uf` | Unidade da Federação |
| `ano` | Ano de referência |
| `tipo_area` | Capital / Resto da RM / Resto da RIDE / Urbano fora de RM / Rural |
| `sexo` | Sexo do respondente |
| `raca_cor` | Raça/cor autodeclarada |
| `escolaridade` | Nível de instrução |
| `faixa_etaria` | Faixa etária |
| `posicao_no_domicilio` | Posição da pessoa na família (responsável, cônjuge, filho, etc.) |
| `posicao_ocupacao` | Posição na ocupação principal |
| `grupamento_atividade` | Setor/grupamento de atividade econômica |
| `tempo_no_trabalho` | Tempo no trabalho atual (faixas) |
| `media_moradores_domicilio` | Média de moradores no domicílio |
| `media_filhos` | Média de filhos |
| `media_horas_trabalhadas` | Horas habitualmente trabalhadas (média da célula) |
| `renda_media_efetiva` | Renda efetiva média no mês de referência |
| `renda_media_habitual` | Renda habitual média declarada |
| `desvio_absoluto_renda` | Diferença absoluta média (R$) entre renda efetiva e habitual |
| `desvio_relativo_renda_pct` | Desvio relativo médio entre renda efetiva e habitual (com sinal) |
| `std_renda_efetiva` | Desvio padrão amostral da renda efetiva dentro da célula |
| `cv_renda_efetiva` | Coeficiente de variação da renda efetiva (std/média) |
| `total_entrevistados` | Número de respondentes na célula |

**Variável removida:** `trimestre` — perda de granularidade temporal
considerada aceitável dado o ganho de cobertura geográfica obtido com
a agregação anual.

**Variáveis renomeadas em 1.10:**
- `condicao_domicilio` → `posicao_no_domicilio` (V2005 mede posição familiar, não imóvel)
- `volatilidade_renda` → `desvio_absoluto_renda`
- `volatilidade_renda_pct` → `desvio_relativo_renda_pct`

**Variáveis adicionadas em 1.10:**
- `std_renda_efetiva`
- `cv_renda_efetiva`

**Variáveis de maior relevância conceitual para o score:**
`renda_media_habitual`, `renda_media_efetiva`, `cv_renda_efetiva`,
`tempo_no_trabalho`, `media_horas_trabalhadas`, `escolaridade`,
`media_moradores_domicilio`, `media_filhos`, `faixa_etaria`, `grupamento_atividade`.

Destaque: `tempo_no_trabalho` consolidada como proxy relevante de
estabilidade econômica mesmo em contextos de informalidade.

---

### 1.4 Decisões Metodológicas

- **Piso de respondentes por célula:** 30 (reduzido de 50 para ampliar
  cobertura geográfica sem comprometer representatividade estatística)
- **Normalização:** z-score com truncamento, por ser mais robusta a outliers
  e preservar a distribuição relativa entre grupos; preferível a min-max ou
  log dada a assimetria acentuada das distribuições de renda nos microdados
  brasileiros
- **Unidade analítica do score:** célula-perfil (combinação de variáveis
  categóricas no GROUP BY da view), não indivíduo. Coerente com o objetivo
  de mapear perfis e regiões, não realizar scoring individual estilo SCR

---

### 1.5 Arquitetura Conceitual do Modelo (Score Composto)

O score adota arquitetura **multidimensional**, estruturada em subíndices
conceituais independentes — mais interpretável, modular e metodologicamente
robusto do que uma abordagem monolítica.

| Subíndice | Objetivo | Variáveis associadas |
|-----------|----------|----------------------|
| **Estabilidade Econômica** | Previsibilidade ocupacional e de renda | `tempo_no_trabalho`, `cv_renda_efetiva`, `media_horas_trabalhadas`, `desvio_relativo_renda_pct` (sinal conjuntural) |
| **Capacidade Financeira** | Potencial de geração de renda e capital humano | `renda_media_habitual`, `renda_media_efetiva`, `escolaridade`, `grupamento_atividade` |
| **Vulnerabilidade Familiar** | Pressões estruturais sobre o orçamento | `media_moradores_domicilio`, `media_filhos` + variáveis futuras do Censo |
| **Maturidade Socioeconômica** | Estágio de consolidação econômica e ocupacional | `faixa_etaria`, `posicao_ocupacao`, `posicao_no_domicilio` + proxy de patrimônio via Censo (Sessão 5) |

*Nota:* variáveis monetárias serão deflacionadas antes da padronização
estatística para garantir comparabilidade temporal (Sessão 3).

---

### 1.6 Estratégia Estatística

- **PCA (Principal Component Analysis):** utilizado em etapa posterior para
  identificar redundâncias, reduzir multicolinearidade, validar estrutura dos
  subíndices, calibrar pesos e melhorar eficiência da clusterização.
  Não substituirá a interpretação econômica das dimensões conceituais.
- **Clusterização (K-Means):** identificação de perfis latentes de
  estabilidade financeira; possível avaliação posterior de abordagens
  hierárquicas ou baseadas em densidade.

---

### 1.7 Estratégia Territorial

Análises territoriais em agrupamentos estatisticamente robustos:
- Regiões Metropolitanas (RMs)
- RIDEs
- Macrorregiões geográficas
- Recorte urbano/rural

Territorialização ocorrerá após a clusterização, com caráter complementar.
Integração futura prevista com ESTBAN e Censo IBGE para geointeligência.

---

### 1.8 Pipeline Analítico Consolidado

```
PNAD Contínua
  → Limpeza e tratamento estatístico
  → Construção de variáveis derivadas
  → Deflacionamento (IPCA) e harmonização temporal das rendas
  → Integração territorial (Censo IBGE)
  → Padronização estatística (z-score com truncamento)
  → Construção dos subíndices socioeconômicos
  → Consolidação do score composto
  → PCA (redução dimensional e validação)
  → Clusterização (K-Means)
  → Territorialização dos clusters
  → Dashboard Power BI + Storytelling executivo
```

---

### 1.9 Próxima Sessão — EDA Completa

EDA estruturada em 4 queries:
1. Distribuição das variáveis quantitativas
2. Distribuição das variáveis qualitativas
3. Análise regional (por UF e tipo de área)
4. Análise temporal (evolução 2021–2025)

---

### 1.10 Reconstrução da View Base — Ajustes Pré-EDA

Durante a preparação da Sessão 2, foi realizada análise crítica da view base
que identificou inconsistências relevantes. Ajustes implementados:

**Correções metodológicas:**

- `media_horas_trabalhadas`: substituído `CAST(V4019 AS FLOAT64)` por
  `SAFE_CAST(V4019 AS FLOAT64)`. O CAST estrito retornava NULL para a
  célula inteira quando V4019 trazia valores especiais — recuperando
  cobertura para trabalhador doméstico, sem carteira e familiar auxiliar.

- `volatilidade_renda_pct` renomeada para `desvio_relativo_renda_pct`.
  A fórmula `AVG((VD4020 - VD4016) / VD4016)` calcula desvio relativo
  médio entre renda efetiva e habitual (com sinal), não volatilidade
  estatística (que é dispersão, sempre ≥ 0). Renomeação corrige o
  rótulo sem alterar o cálculo. A variável permanece útil como **sinal
  conjuntural** (gap entre o que a pessoa esperava ganhar e o que de
  fato ganhou no mês de referência).

- `volatilidade_renda` renomeada para `desvio_absoluto_renda`,
  por consistência (é a diferença absoluta média em R$, não dispersão).

- `condicao_domicilio` renomeada para `posicao_no_domicilio`.
  A variável V2005 captura posição da pessoa na família (responsável,
  cônjuge, filho, etc.), não condição do imóvel. Nome anterior era
  ambíguo.

**Adições à view:**

- `std_renda_efetiva` (`STDDEV_SAMP(VD4020)`): desvio padrão da renda
  efetiva dentro da célula. Mede heterogeneidade individual entre os
  respondentes do mesmo perfil-célula.

- `cv_renda_efetiva` (coeficiente de variação): std dividido pela média.
  Tem dois usos:
  1. **No subíndice de Estabilidade Econômica** como volatilidade
     verdadeira intra-perfil — substitui o papel anteriormente atribuído
     ao `desvio_relativo_renda_pct` no score.
  2. **Como métrica de qualidade/confiabilidade da célula** — CV alto
     indica perfis que misturam populações economicamente heterogêneas.

**Decisão sobre patrimônio imobiliário:**

A variável V0207 (condição de ocupação do imóvel — próprio quitado,
financiado, alugado, cedido) **não está disponível** na tabela
`basedosdados.br_ibge_pnadc.microdados`, que mantém apenas variáveis
do questionário trimestral básico. A informação existe na PNAD Contínua
mas em módulo anual específico (visitas 1 e 5 do painel rotativo).

**Decisão:** patrimônio imobiliário será obtido via **Censo Demográfico
na Sessão 5**, em formato agregado por recorte territorial (% de
domicílios próprios quitados por RM / macrorregião / setor), compatível
com a estratégia territorial já definida. Adia-se para a fonte adequada
em vez de forçar a inclusão na fonte atual.

**Validação da granularidade da view reconstruída:**

Diagnóstico do CV intra-célula em 8.045 células:
- Quartis: 0,00 / 0,48 / 0,63 / 0,86 / 7,58
- Células com CV > 2: 180 (2,24%) — heterogeneidade controlada
- Células com CV null: 42 (0,52%) — apenas 1 respondente com `VD4020`
  preenchido na célula (demais com renda efetiva ausente)
- Células com CV = 0: 2 (0,02%) — irrelevante

**Veredito:** granularidade da view considerada adequada. Não há
necessidade de adicionar dimensões ao `GROUP BY`. As dimensões atuais
(`sigla_uf`, `ano`, `tipo_area`, `rm_ride`, `sexo`, `raca_cor`,
`escolaridade`, `faixa_etaria`, `posicao_no_domicilio`,
`posicao_ocupacao`, `grupamento_atividade`, `tempo_no_trabalho`)
capturam a heterogeneidade socioeconômica relevante.

**Impacto na arquitetura do score (referência para Sessão 4):**

- Subíndice de **Estabilidade Econômica** passa a usar `cv_renda_efetiva`
  como medida de volatilidade verdadeira. O `desvio_relativo_renda_pct`
  permanece como sinal conjuntural complementar (gap renda efetiva vs.
  habitual), não como volatilidade.
- Subíndice de **Maturidade Socioeconômica** mantém `posicao_no_domicilio`
  como proxy de estágio familiar; proxy de patrimônio será incorporada
  na Sessão 5 via Censo.

**Pendências metodológicas registradas para sessões futuras:**

- **Sessão 4:** tratamento das 42 células com `cv_renda_efetiva` null —
  definir entre imputação por perfil similar ou exclusão pontual.
- **Sessão 4:** tratamento das 180 células com CV > 2 (heterogeneidade
  alta) — candidatas a winsorização específica ou flag de menor
  confiabilidade.
- **Sessão 5:** incorporação de proxy de patrimônio imobiliário via
  Censo Demográfico, com agregação territorial compatível.

---

*Documento mantido manualmente. Atualizar ao final de cada sessão.*
*Última atualização: Sessão 1.10 — reconstrução da view base e validação
de granularidade pré-EDA.*
