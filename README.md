# Mapeamento de Bons Pagadores Fora do Radar do SFN

![Social Preview](social_preview_mescla_light.png)

> Identificação de perfis socioeconômicos com potencial de estabilidade
> financeira que estão estruturalmente invisíveis ao Sistema Financeiro
> Nacional brasileiro, a partir de dados públicos.

---

## Contexto

O Sistema Financeiro Nacional (SFN) avalia risco de crédito majoritariamente
a partir de histórico transacional registrado em birôs e sistemas internos
dos bancos. Pessoas sem esse histórico — os chamados **thin file** — são
frequentemente tratadas como risco indeterminado e, na prática, ficam
fora do radar do sistema.

Esse fenômeno tem dois rostos diferentes que costumam ser confundidos:

- **Invisível estrutural:** pessoa que nunca foi analisada. Não tem score,
  não recebeu oferta, o sistema não a enxerga.
- **Invisível por escolha:** pessoa com crédito disponível que não toma.
  O sistema já a enxerga, ela apenas não consome.

Este projeto foca no **primeiro grupo** — a lacuna real de inclusão
financeira — e busca mapear, dentro dele, quem teria perfil de bom
pagador se fosse analisado.

---

## Conceito de Thin File

Indivíduos com histórico de crédito inexistente ou insuficiente para
modelos tradicionais de scoring. Importante: **thin file ≠ mau pagador**.
A ausência de histórico é frequentemente confundida com risco, mas pode
refletir apenas ausência de oportunidade ou de necessidade.

Distinções operacionais utilizadas no projeto:

| Status | Significado |
|--------|-------------|
| Bancarizado | Tem relação transacional com banco |
| Com crédito calculado | Banco já avaliou risco e ofereceu limite |
| Tomador de crédito | De fato utiliza crédito |

---

## Escopo Populacional

Foco em trabalhadores **fora do mercado formal com carteira assinada**,
segmento potencialmente sub-bancarizado:

- Trabalhadores autônomos
- Empregados sem carteira (setor privado e doméstico)
- Empregados públicos sem vínculo formal
- Trabalhadores familiares auxiliares

Fonte primária: **PNAD Contínua (IBGE), microdados 2021–2025**.

---

## Stack Técnico

- **Google BigQuery** — processamento dos microdados via tabela pública
  `basedosdados.br_ibge_pnadc.microdados`
- **SQL (GoogleSQL)** — view base, queries de EDA, transformações
- **Power BI** — visualização e dashboard executivo (Sessão 6)
- **Python** *(previsto)* — PCA, K-Means e validações estatísticas
  (Sessão 4 em diante)

Fontes complementares previstas: IPCA (IPEAData), ESTBAN (Banco Central),
Censo Demográfico (IBGE).

---

## Pipeline Analítico

```
PNAD Contínua
  → Limpeza e variáveis derivadas
  → Deflacionamento (IPCA)
  → Padronização (z-score com truncamento)
  → Subíndices socioeconômicos
  → Score composto
  → PCA (redução dimensional)
  → Clusterização (K-Means)
  → Territorialização (RMs, RIDEs, macrorregiões)
  → Dashboard Power BI + Storytelling executivo
```

Score composto estruturado em quatro subíndices:

| Subíndice | O que mede |
|-----------|------------|
| Estabilidade Econômica | Previsibilidade ocupacional e de renda |
| Capacidade Financeira | Potencial de geração de renda e capital humano |
| Vulnerabilidade Familiar | Pressões estruturais sobre o orçamento |
| Maturidade Socioeconômica | Estágio de consolidação econômica |

---

## Estado Atual

| Sessão | Descrição | Status |
|--------|-----------|--------|
| 1 | Estruturação da base | ✅ Concluída |
| 2 | EDA completa | ✅ Concluída |
| 3 | Deflação pelo IPCA | 🔜 Próxima |
| 4 | Construção do score | ⏳ Pendente |
| 5 | Geointeligência | ⏳ Pendente |
| 6 | Visualização e entregável | ⏳ Pendente |

---

## Como Navegar o Repositório

| Arquivo | Conteúdo |
|---------|----------|
| `arquitetura_analitica_modelo.md` | Documento mestre — metodologia consolidada |
| `changelog_integrado.md` | Diário de bordo — histórico completo de decisões |
| `sql/` *(em construção)* | Scripts SQL: view base e queries da EDA |
| `dados/` *(em construção)* | Outputs intermediários das análises |

Para entender **o que** o projeto faz e **como** está estruturado,
comece pelo documento de arquitetura.
Para entender **por que** cada decisão foi tomada e **como** o
projeto chegou ao estado atual, consulte o changelog.

---

## Achados Parciais (Sessão 2)

Alguns resultados da análise exploratória que vale destacar:

- **Trabalhadores autônomos representam ~67% do escopo**, com a
  agricultura concentrando 77–84% dessa categoria
- **Agricultura é o principal puxador de heterogeneidade intra-perfil**
  (CV ~1,4 vs. ~0,7 nas demais atividades de autônomos)
- **Empregado privado sem carteira apresenta gap conjuntural crônico
  negativo** entre renda esperada e renda efetiva (-5% a -8% ao longo
  dos 5 anos analisados)
- Decisão metodológica decorrente: `grupamento_atividade` (setor
  econômico) tratado como **dimensão analítica padrão**, ao lado
  da posição na ocupação

---

## Nota sobre Metodologia de Trabalho

Este projeto é conduzido pelo autor com apoio de ferramentas de IA
(Claude e ChatGPT) para discussão técnica, revisão crítica e elaboração
de queries e documentação. A autoria intelectual das decisões
metodológicas é do autor; as IAs atuam como ferramentas de apoio.

O **changelog do projeto registra explicitamente os pontos de discussão
crítica** entre o autor e as IAs — incluindo questionamentos a sugestões
iniciais, refinamentos conceituais propostos pelo autor e decisões
finais autorais. O objetivo é tornar transparente o processo decisório
e evidenciar que sugestões automatizadas foram filtradas pelo julgamento
técnico do autor, não simplesmente absorvidas.

---

## Limitações e Premissas

- Projeto de natureza **exploratória e analítica**, não preditiva nem
  regulatória
- Não substitui mecanismos formais de concessão de crédito
- Não utiliza dados protegidos por sigilo bancário (SCR, birôs privados)
- Inferências baseadas em **proxies socioeconômicas** de dados públicos
- Granularidade territorial limitada pela PNAD (UF + RM/RIDE +
  recorte urbano/rural)

---

## Autor

Fernando Rocha dos Santos  
Analista de BI
