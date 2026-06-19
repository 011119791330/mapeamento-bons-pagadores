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

> **Nota de escopo:** embora o vocabulário do projeto enfatize "crédito"
> e "bons pagadores", o escopo conceitual é o **relacionamento financeiro
> em sentido amplo** — da porta de entrada (conta corrente, meio de
> pagamento, bancarização básica) a operações complexas (financiamento,
> capital de giro). A invisibilidade estrutural começa antes do crédito,
> na ausência de qualquer relação transacional com o SFN. O score
> socioeconômico é agnóstico ao produto de destino; o enquadramento
> multiproduto materializa-se na profundidade financeira territorial
> (Sessão 5) e no storytelling (Sessão 6).

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

- Trabalhadores autônomos (conta-própria)
- Empregados sem carteira (setor privado e doméstico)
- Empregados públicos sem vínculo formal
- Trabalhadores familiares auxiliares

Fonte primária: **PNAD Contínua (IBGE), microdados 2021–2025**.

---

## Stack Técnico

- **Google BigQuery** — processamento dos microdados via tabela pública
  `basedosdados.br_ibge_pnadc.microdados`; view base e view-filha
  deflacionada materializadas em `credito-pnad-2026.pnad_rend_trab`
- **SQL (GoogleSQL)** — view base, queries de EDA, transformações.
  Médias e dispersão ponderadas pelo peso de pós-estratificação (`V1028`)
- **Power BI** — visualização e dashboard executivo (Sessão 6)
- **Python** *(previsto)* — PCA, K-Means e validações estatísticas
  (Sessão 4-C em diante)

Fontes complementares: IPCA (IBGE/SIDRA tabela 1737, **já integrado**),
ESTBAN (Banco Central) e Censo Demográfico (IBGE) *(previstos)*.

---

## Pipeline Analítico

```
PNAD Contínua
  → Limpeza e variáveis derivadas
  → Deflacionamento (IPCA, base 2025)
  → Auditoria e reconstrução da view base (ponderação por peso amostral)
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
| 3 | Deflação pelo IPCA | ✅ Concluída |
| 4A | Auditoria da view base | ✅ Concluída |
| 4B | Reconstrução da view (ponderação + correções) | ✅ Concluída |
| 4C | Construção do score | 🔜 Próxima |
| 5 | Geointeligência | ⏳ Pendente |
| 6 | Visualização e entregável | ⏳ Pendente |

---

## Como Navegar o Repositório

| Arquivo | Conteúdo |
|---------|----------|
| `arquitetura_analitica_modelo.md` | Documento mestre — metodologia consolidada |
| `changelog_integrado.md` | Diário de bordo — histórico completo de decisões |
| `v02_view_renda_media_uf.sql` | View base reconstruída (Sessão 4-B) |
| `recriar_view_filha_deflacionada.sql` | View-filha deflacionada recriada sobre a v02 |
| `v02_validacao_pre_producao.sql` | Queries de validação da reconstrução |
| `sql/` *(em construção)* | Scripts SQL: view base, queries da EDA, deflação |
| `dados/` *(em construção)* | Outputs intermediários e tabelas auxiliares |

Para entender **o que** o projeto faz e **como** está estruturado,
comece pelo documento de arquitetura.
Para entender **por que** cada decisão foi tomada e **como** o
projeto chegou ao estado atual, consulte o changelog.

---

## Achados Parciais

**Sessão 2 (EDA):**

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

**Sessão 3 (Deflação):**

- A deflação pelo IPCA (base 2025) **inverteu a leitura da evolução de
  renda** de duas categorias que a análise nominal mascarava:
  - **Trabalhador doméstico s/ carteira:** +21% nominal, mas **−3% real**
    — estagnação disfarçada de crescimento
  - **Empregado público s/ carteira:** −3% nominal, mas **−22% real**
    — perda de quase ¼ do poder de compra em 4 anos
- Autônomos (+20% real) e empregado privado s/ carteira (+17% real)
  mantiveram ganho real sólido
- Demonstra por que a harmonização temporal é etapa crítica, não cosmética:
  sem deflacionar, perfis em precarização apareceriam como ascendentes

**Sessão 4-A (Auditoria) e 4-B (Reconstrução):**

- Auditoria forense da view base contra o dicionário oficial e contra os
  próprios dados revelou **quatro erros de mapeamento de variável**
  (V1023 com rótulos errados, V1022/urbano-rural ausente, V2005 em versão
  desatualizada, e horas/tempo usando variáveis binárias erradas) e o uso
  de **média simples em vez de ponderada** — todos originados na Sessão 1,
  corrigidos sem afetar escopo nem rendas (que estavam íntegros)
- View base reconstruída (v02): médias e dispersão agora **ponderadas pelo
  peso de pós-estratificação** (V1028); `tempo_no_trabalho` aberto em
  7 faixas; `posicao_no_domicilio` reagrupado de 19 para 4 grupos; eixo
  urbano/rural (V1022) adicionado; `populacao_expandida` adicionada para
  dimensionar clusters
- Escopo final: **1.573 células-perfil** (≥ 30 respondentes cada)
- A ponderação tem efeito pequeno e estável nas categorias grandes
  (Conta-própria, ~12% de desvio vs. média simples), mas **instável nas
  categorias pequenas** (familiar auxiliar oscila 0–50% conforme o ano) —
  efeito de cauda amostral, a tratar na construção do score
- **Decisão de integridade de dados:** no reagrupamento de posição no
  domicílio, cônjuges do mesmo sexo foram mantidos junto aos demais
  cônjuges (não relegados à cauda "outros" por baixa frequência),
  preservando a visibilidade de uma realidade que a PNAD nem sempre
  captura bem

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
- Médias e dispersão ponderadas pelo peso de pós-estratificação da PNAD
  (V1028); a variância ponderada usa aproximação de peso de frequência,
  não estimativa sob desenho amostral complexo — escolha de
  proporcionalidade, documentada
- Granularidade territorial limitada pela PNAD (UF + RM/RIDE +
  recorte urbano/rural); o código de RM/RIDE (`rm_ride`) é mantido cru na
  base e decodificado apenas na integração territorial da Sessão 5

---

## Autor

Fernando Rocha dos Santos
Analista de BI
