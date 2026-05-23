# Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN

## Objetivo
Identificar, via dados públicos (IBGE, Banco Central, Ipea e outras bases),
o perfil de pessoas potencialmente boas pagadoras que estão fora do radar de
crédito e inclusão financeira do Sistema Financeiro Nacional (SFN).
Conceito central: **thin file** — indivíduos com histórico de crédito
inexistente ou insuficiente, não necessariamente inadimplentes.

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

## Sessão 1 — Estruturação da Base
**Status:** Concluída

### Fonte de dados
- Microdados PNAD Contínua — período: **2021 a 2025**
- Unidade de análise: indivíduo (respondente)

### Escopo e segmentos-alvo
Foco em trabalhadores **fora do mercado formal com carteira assinada**,
excluindo vínculos com maior estabilidade e acesso a crédito institucional.

**Incluídos:**
- Conta-própria
- Empregado sem carteira (setor privado e doméstico)
- Empregado público sem carteira
- Trabalhador familiar auxiliar

**Excluídos do escopo:**
- Militares
- Servidores públicos (estatutários)
- Empregados com carteira assinada

### Variáveis da view base

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

**Removido:** `trimestre` — a perda de granularidade temporal foi considerada
aceitável dado o ganho de cobertura geográfica obtido com a agregação anual.

### Decisões metodológicas

- **Piso de respondentes por célula:** 30 (reduzido de 50 para ampliar
  cobertura geográfica sem comprometer representatividade estatística)
- **Normalização:** z-score com truncamento (em vez de min-max ou log),
  por ser mais robusta a outliers e preservar a distribuição relativa
  entre grupos

### Próxima sessão
EDA completa estruturada em 4 queries:
1. Distribuição das variáveis quantitativas
2. Análise regional (por UF e tipo de área)
3. Análise temporal (evolução 2021–2025)
4. *(a definir na abertura da Sessão 2)*

---

*Documento mantido manualmente. Atualizar ao final de cada sessão.*
