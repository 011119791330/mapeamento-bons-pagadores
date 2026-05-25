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
| 2 | EDA completa (quantitativas, regional, temporal) | 🔜 Próxima |
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

### 1.3 Variáveis da View Base

| Variável | Descrição |
|----------|-----------|
| `sigla_uf` | Unidade da Federação |
| `ano` | Ano de referência |
| `tipo_area` | Urbano / Rural |
| `sexo` | Sexo do respondente |
| `raca_cor` | Raça/cor autodeclarada |
| `escolaridade` | Nível de instrução |
| `faixa_etaria` | Faixa etária |
| `condicao_domicilio` | Condição de ocupação do domicílio |
| `posicao_ocupacao` | Posição na ocupação principal |
| `grupamento_atividade` | Setor/grupamento de atividade econômica |
| `media_moradores` | Média de moradores no domicílio |
| `media_filhos` | Média de filhos |
| `horas_trabalhadas` | Horas habitualmente trabalhadas |
| `tempo_no_trabalho` | Tempo no trabalho atual |
| `renda_efetiva` | Renda efetiva no mês de referência |
| `renda_habitual` | Renda habitual declarada |
| `volatilidade_renda_pct` | Volatilidade relativa da renda (%) |

**Variável removida:** `trimestre` — perda de granularidade temporal
considerada aceitável dado o ganho de cobertura geográfica obtido com
a agregação anual.

**Variáveis de maior relevância conceitual:**
`renda_habitual`, `renda_efetiva`, `volatilidade_renda_pct`,
`tempo_no_trabalho`, `horas_trabalhadas`, `escolaridade`,
`media_moradores`, `media_filhos`, `faixa_etaria`, `grupamento_atividade`.

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

---

### 1.5 Arquitetura Conceitual do Modelo (Score Composto)

O score adota arquitetura **multidimensional**, estruturada em subíndices
conceituais independentes — mais interpretável, modular e metodologicamente
robusto do que uma abordagem monolítica.

| Subíndice | Objetivo | Variáveis associadas |
|-----------|----------|----------------------|
| **Estabilidade Econômica** | Previsibilidade ocupacional e de renda | `tempo_no_trabalho`, `volatilidade_renda_pct`, `horas_trabalhadas` |
| **Capacidade Financeira** | Potencial de geração de renda e capital humano | `renda_habitual`, `renda_efetiva`, `escolaridade`, `grupamento_atividade` |
| **Vulnerabilidade Familiar** | Pressões estruturais sobre o orçamento | `media_moradores`, `media_filhos` + variáveis futuras do Censo |
| **Maturidade Socioeconômica** | Estágio de consolidação econômica e ocupacional | `faixa_etaria`, `posicao_ocupacao`, `condicao_domicilio` |

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
2. Análise regional (por UF e tipo de área)
3. Análise temporal (evolução 2021–2025)
4. *(eixo a definir na abertura da Sessão 2)*

---

*Documento mantido manualmente. Atualizar ao final de cada sessão.*
*Última atualização: Sessão 1 — integração Claude + ChatGPT.*
