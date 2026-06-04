# Changelog — Projeto: Mapeamento de Bons Pagadores Fora do Radar do SFN

## Objetivo

Identificar, via dados públicos (IBGE, Banco Central, Ipea e outras bases),
o perfil de pessoas potencialmente boas pagadoras que estão fora do radar de
crédito e inclusão financeira do Sistema Financeiro Nacional (SFN).

Conceito central: **thin file** — indivíduos com histórico de crédito
inexistente ou insuficiente, não necessariamente inadimplentes.

O projeto possui natureza **exploratória e analítica**, não preditiva e não
regulatória. Não pretende representar mecanismo formal de concessão de crédito.

**Refinamento conceitual (Sessão 2):** o escopo prioritário do projeto são
indivíduos **invisíveis estruturalmente** ao SFN — pessoas que ainda não
foram analisadas, modeladas ou ofertadas pelo sistema financeiro — e não
pessoas que têm crédito disponível e optam por não tomar.

---

## Nota metodológica sobre a condução do projeto

Este projeto é conduzido pelo autor com apoio de ferramentas de IA (Claude
e ChatGPT) para discussão técnica, revisão crítica e elaboração de queries
e documentação. A autoria intelectual das decisões metodológicas é do
autor; as IAs atuam como ferramentas de apoio.

Ao longo do changelog, há registros explícitos de pontos em que a discussão
crítica resultou em ajustes ou em que o autor recusou sugestões iniciais
das IAs de apoio. Essas marcações estão em itálico e prefixadas
(*Crítica do autor:*, *Decisão do autor:*, *Ajuste após questionamento do autor:*),
e visam tornar transparente o processo decisório.

---

## Estrutura do Projeto

| Sessão | Descrição | Status |
|--------|-----------|--------|
| 1 | Estruturação da base (view, variáveis, filtros) | ✅ Concluída |
| 2 | EDA completa (quantitativas, qualitativas, regional, temporal) | ✅ Concluída |
| 3 | Deflação pelo IPCA | ✅ Concluída |
| 4 | Construção e calibração do score | 🔜 Próxima |
| 5 | Geointeligência (cruzamento com ESTBAN e Censo) | ⏳ Pendente |
| 6 | Visualização e entregável final | ⏳ Pendente |

---

## Sessão 1 — Estruturação da Base e Arquitetura Analítica
**Status:** Concluída

---

### 1.1 Fontes de Dados

| Fonte | Finalidade | Momento de entrada no pipeline |
|-------|------------|-------------------------------|
| PNAD Contínua (IBGE) | Perfil socioeconômico individual — base primária | Sessão 1 (já incorporada) |
| IPCA (IBGE/IPEAData) | Deflator monetário | Sessão 3 |
| ESTBAN (Banco Central) | Profundidade financeira regional por município | Sessão 5 |
| Censo Demográfico (IBGE) | Patrimônio domiciliar, infraestrutura urbana | Sessão 5 |
| Indicadores BCB (Selic, expectativas, IDF) | Contexto macroeconômico para storytelling | Sessão 6 |

- Microdados PNAD Contínua — período: **2021 a 2025**
- Unidade primária de análise: **indivíduo respondente**
- Tabela utilizada: `basedosdados.br_ibge_pnadc.microdados`

---

### 1.2 Recorte Populacional

Foco em trabalhadores **fora do mercado formal com carteira assinada**,
segmento potencialmente sub-bancarizado e sub-representado nos mecanismos
tradicionais de avaliação de crédito.

**Incluídos:**
- Trabalhadores autônomos
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

---

### 1.4 Decisões Metodológicas

- **Piso de respondentes por célula:** 30 (reduzido de 50 para ampliar
  cobertura geográfica sem comprometer representatividade estatística)
- **Normalização:** z-score com truncamento, por ser mais robusta a outliers
  e preservar a distribuição relativa entre grupos
- **Unidade analítica do score:** célula-perfil (combinação de variáveis
  categóricas no GROUP BY da view), não indivíduo. Coerente com o objetivo
  de mapear perfis e regiões, não realizar scoring individual estilo SCR

---

### 1.5 Arquitetura Conceitual do Modelo (Score Composto)

Score multidimensional estruturado em subíndices conceituais independentes.

| Subíndice | Objetivo | Variáveis associadas |
|-----------|----------|----------------------|
| **Estabilidade Econômica** | Previsibilidade ocupacional e de renda | `tempo_no_trabalho`, `cv_renda_efetiva`, `media_horas_trabalhadas`, `desvio_relativo_renda_pct` (sinal conjuntural) |
| **Capacidade Financeira** | Potencial de geração de renda e capital humano | `renda_media_habitual`, `renda_media_efetiva`, `escolaridade`, `grupamento_atividade` |
| **Vulnerabilidade Familiar** | Pressões estruturais sobre o orçamento | `media_moradores_domicilio`, `media_filhos` + variáveis futuras do Censo |
| **Maturidade Socioeconômica** | Estágio de consolidação econômica e ocupacional | `faixa_etaria`, `posicao_ocupacao`, `posicao_no_domicilio` + proxy de patrimônio via Censo (Sessão 5) |

---

### 1.6 Estratégia Estatística

- **PCA:** redução dimensional e validação dos subíndices
- **Clusterização (K-Means):** identificação de perfis latentes

---

### 1.7 Estratégia Territorial

Agrupamentos: RMs, RIDEs, macrorregiões, urbano/rural.
Territorialização após clusterização, integração com ESTBAN e Censo.

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

### 1.10 Reconstrução da View Base — Ajustes Pré-EDA

Durante a preparação da Sessão 2, foi realizada análise crítica da view base
que identificou inconsistências relevantes. Ajustes implementados:

**Correções metodológicas:**

- `media_horas_trabalhadas`: `CAST` → `SAFE_CAST` em V4019 (recupera células
  que ficavam nulas por valores especiais)
- `volatilidade_renda_pct` renomeada para `desvio_relativo_renda_pct`
  (correção de nomenclatura — era desvio com sinal, não volatilidade)
- `volatilidade_renda` renomeada para `desvio_absoluto_renda`
- `condicao_domicilio` renomeada para `posicao_no_domicilio` (V2005 mede
  posição familiar, não condição do imóvel)

**Adições à view:**

- `std_renda_efetiva` e `cv_renda_efetiva` — dispersão intra-célula
  (volatilidade verdadeira)

**Filtro de escopo movido para a view:**

`WHERE VD4009 IN ('2', '4', '6', '9', '10')` — garante que todas as queries
descendentes operem sobre o público-alvo, sem necessidade de filtro
redundante. *Ajuste após questionamento do autor:* a primeira versão das
queries da EDA carregava o filtro de escopo nas queries individuais, com
risco de inconsistência. Padronizou-se na view.

**Decisão sobre patrimônio imobiliário:**

V0207 (condição de ocupação do imóvel) **não está disponível** na tabela
da `basedosdados`. **Decisão:** adiar para a Sessão 5 via Censo Demográfico,
em formato agregado por recorte territorial.

**Validação da granularidade da view reconstruída:**

Diagnóstico do CV intra-célula em 8.045 células (antes do filtro de escopo):
- Quartis: 0,00 / 0,48 / 0,63 / 0,86 / 7,58
- Células com CV > 2: 180 (2,24%) — heterogeneidade controlada
- Células com CV null: 42 (0,52%) — apenas 1 respondente com `VD4020`
  preenchido na célula
- Granularidade considerada adequada.

Após aplicação do filtro de escopo, restaram 3.476 células no escopo
alvo do projeto.

---

## Sessão 2 — Análise Exploratória de Dados (EDA)
**Status:** Concluída

---

### 2.1 Estrutura da EDA

EDA estruturada em 4 queries principais + 1 query exploratória complementar:

| # | Query | Granularidade | Objetivo |
|---|-------|---------------|----------|
| 1 | Distribuição quantitativas | `ano × posicao_ocupacao` | Caracterizar evolução agregada por categoria |
| 2 | Distribuição qualitativas | `ano × escolaridade × raça × idade × área × tempo × sexo` | Identificar perfis qualitativos extremos e medianos |
| 3 | Evolução da renda | `UF × perfil × área` com pivot por ano | Trajetória temporal por perfil |
| 4 | Perfil regional | `UF × tipo_area × posicao × demografia × escolaridade` | Variação regional |
| 5 | Subgrupos ocupacionais (exploratória) | `ano × posicao_ocupacao × grupamento_atividade` | Investigar heterogeneidade intra-categoria |

---

### 2.2 Achados Substantivos

**Composição do escopo**

- Autônomos representam **~67% do total de respondentes do recorte** nos
  5 anos analisados. Indica que o projeto está predominantemente
  caracterizando autônomos. *Implicação registrada:* na Sessão 4
  (clusterização), atenção para que o peso de Autônomos não dilua
  os perfis menores.

- Trabalhador familiar auxiliar é categoria muito pequena (~3-5% do
  escopo) e tem peculiaridade metodológica: `renda_media_habitual`
  frequentemente ausente, característico de trabalho sem remuneração
  regular declarada.

**Heterogeneidade intra-célula**

CV ponderado por `posicao_ocupacao`:

| Categoria | CV típico |
|-----------|-----------|
| Autônomos | 1,20–1,31 |
| Empregado público sem carteira | 0,49–0,99 |
| Empregado privado sem carteira | 0,75–0,79 |
| Trabalhador doméstico sem carteira | 0,64–0,73 |
| Trabalhador familiar auxiliar | 0,01–0,43 |

- **Autônomos têm CV acima de 1**, indicando célula que mistura
  populações economicamente distintas dentro da mesma categoria
  ocupacional.

- **Trabalhador doméstico é ocupacionalmente o mais homogêneo** dentro
  do escopo (CV 0,6–0,7), perfil mais previsível.

**Causa raiz da heterogeneidade — Agricultura**

A query exploratória (#5) revelou que **agricultura é o principal puxador
de heterogeneidade** dentro de Autônomos:

- Autônomos + Agricultura: CV 1,32–1,47 em todos os anos
- Autônomos + outras atividades: CV 0,45–1,04

Agricultura representa **77–84% do total de Autônomos**. Retirando-a,
o CV agregado cairia para faixa compatível com os demais perfis.

*Crítica do autor:* a heterogeneidade da agricultura era hipótese
levantada pelo autor antes da consulta, confirmada empiricamente. A
categoria "Agricultura, pecuária, produção florestal, pesca e aquicultura"
da PNAD é estruturalmente ampla (inclui agricultor familiar de
subsistência, pequeno produtor, pescador artesanal, produtor de
commodities em pequena escala) e captura realidades econômicas
muito distintas sob o mesmo rótulo.

**Decisão metodológica resultante:** `grupamento_atividade` passa a ser
**dimensão padrão** da análise daqui em diante, ao lado de
`posicao_ocupacao`. *Decisão do autor:* tratamento simétrico para todos
os 5 segmentos, não apenas para Autônomos, dado que `grupamento_atividade`
é uma dimensão transversal e relevante para diferenciar realidades dentro
de cada categoria ocupacional.

**Evolução da renda (nominal, sem deflação)**

| Categoria | 2021 | 2025 | Variação nominal |
|-----------|------|------|------------------|
| Autônomos | 1.590 | 2.388 | +50% |
| Empregado privado s/ carteira | 733 | 1.078 | +47% |
| Trabalhador doméstico s/ carteira | 658 | 799 | +21% |
| Empregado público s/ carteira | 2.318 | 2.254 | -3% |

Com IPCA acumulado 2021–2025 de aproximadamente 30%, as duas primeiras
categorias teriam crescimento real positivo, doméstico estaria próximo
da estabilidade real, e empregado público sem carteira teria perda real
significativa. *Confirmação dependente da Sessão 3 (deflação).*

**Desvio relativo de renda (gap habitual vs. efetiva)**

- Empregado privado sem carteira mantém **gap negativo crônico** entre
  -5,4% e -7,7% — segmento ganhou sistematicamente menos do que esperava
  ao longo dos 5 anos. Sinal conjuntural relevante para o subíndice de
  Estabilidade Econômica.

**Perfis qualitativos no topo da distribuição**

As linhas de maior renda na query qualitativas são concentradas em
combinações **Superior completo + Branca + Capital + Homem**, com renda
habitual de R$ 7.000–13.000 dentro do escopo informal. *Crítica do autor:*
esse perfil **não é o alvo prioritário do projeto**, embora apareça nos
dados. Trata-se majoritariamente de profissionais qualificados
capitalizados (médicos PJ, advogados autônomos, consultores) que
provavelmente já estão bancarizados e com crédito calculado pelo SFN,
mesmo que não tomem crédito ativamente. *Decisão do autor:* manter na
base por honestidade analítica, com rotulagem explícita pós-clusterização
como "fora do alvo prioritário".

---

### 2.3 Tipologia Conceitual — Invisibilidade ao SFN

Refinamento conceitual proposto pelo autor durante a Sessão 2,
distinguindo três status frequentemente confundidos:

| Status | Significado |
|--------|-------------|
| **Bancarizado** | Tem relação transacional com banco (conta, cartão, recebimento) |
| **Com crédito calculado** | Banco já avaliou risco e ofereceu ou pré-aprovou limite |
| **Tomador de crédito** | De fato utiliza crédito |

A partir dessa distinção, dois tipos de **invisibilidade ao SFN**:

- **Invisível estrutural (alvo do projeto):** pessoa que ainda não foi
  analisada pelo sistema — não tem score, não tem crédito calculado,
  não recebeu oferta. Lacuna real de inclusão financeira.

- **Invisível por escolha (fora do alvo):** pessoa com crédito disponível
  que não toma. Aparece em modelos tradicionais como thin file por
  ausência de uso, mas o sistema já a enxerga. Não é o foco.

*Decisão do autor:* manter ambos os grupos nos dados durante a análise,
com rotulagem explícita na clusterização. O contraste entre eles é
narrativamente útil no entregável final (Sessão 6) — mostra a diferença
entre **descoberta de população nova** e **caça a clientes existentes**.

---

### 2.4 Decisões Metodológicas da Sessão 2

**Padronização do CV em queries agregadoras**

- Forma de agregação adotada: CV ponderado pelo `total_entrevistados`
  (`SUM(cv_renda_efetiva * total_entrevistados) / SUM(total_entrevistados)`)

- *Crítica do autor:* a IA de apoio sugeriu inicialmente três opções
  (ponderação simples, recálculo via decomposição de variância, ou
  estatísticas descritivas — média/mediana/contagem). O autor questionou
  se mais sofisticação estatística era proporcional ao objetivo do
  projeto (mapeamento de perfis e regiões, não scoring individual) e
  ao público do entregável (gerentes de áreas não-técnicas).

- *Decisão do autor:* adotar a versão mais simples (ponderação) por
  princípio de explicabilidade. A IA de apoio reconheceu viés de
  sofisticação injustificada na sugestão inicial.

**Remoção do desvio padrão interanual da query temporal**

- A query de evolução temporal tinha `STDDEV(renda_media_habitual)` calculado
  sobre todas as células do grupo, sem separar dispersão entre células
  do mesmo ano da dispersão entre anos.

- *Decisão conjunta:* remover da EDA. Se necessário no futuro, calcular
  separadamente com CTE adequado sobre os 5 valores anuais agregados.

**`grupamento_atividade` como dimensão padrão**

- Decisão central da Sessão 2: incorporar `grupamento_atividade` como
  dimensão analítica padrão em todas as etapas posteriores
  (score, clusterização, territorialização).

- *Decisão do autor:* não re-rodar retroativamente as 4 queries da EDA
  com essa dimensão. EDA é fotografia do momento — cada sessão produz
  sua própria fotografia. Os achados da EDA principal não são
  invalidados pela query exploratória complementar.

---

### 2.5 Pendências e Hipóteses para Sessões Futuras

**Para Sessão 3 (Deflação):**

- Aplicar IPCA acumulado sobre `renda_media_efetiva`, `renda_media_habitual`,
  `desvio_absoluto_renda` e `std_renda_efetiva`
- Confirmar/refutar hipóteses sobre variação real de renda (atualmente
  baseadas em variação nominal)

**Para Sessão 4 (Score):**

- Tratamento das 42 células com `cv_renda_efetiva` null
- Tratamento de células com CV > 2 (heterogeneidade alta) — winsorização
  ou flag de baixa confiabilidade
- Atenção à dominância de Autônomos (~67% do escopo) no balanceamento
  da clusterização
- Investigar se `media_horas_trabalhadas` permanece estruturalmente nula
  para perfis fora de Autônomos — pode indicar limitação da fonte
  PNAD para a variável; considerar imputação ou exclusão do score

**Para Sessão 5 (Geointeligência):**

- Incorporar proxy de patrimônio imobiliário via Censo Demográfico
- Estratégia de compatibilidade territorial: agregar ESTBAN (município,
  código IBGE) para o nível da PNAD (UF + RM/RIDE + área), via cruzamento
  pelo código IBGE de município
- *Pergunta levantada pelo autor:* verificou-se que Bacen (ESTBAN) e IBGE
  (PNAD/Censo) compartilham o código IBGE de município como chave
  primária. Compatibilidade resolvida por agregação ascendente.

**Para Sessão 6 (Entregável):**

- Comunicar explicitamente a distinção **invisível estrutural** vs.
  **invisível por escolha** para evitar interpretação errada do projeto
- Indicadores macro do BCB (Selic, IPCA, expectativas) entram aqui como
  contexto, não como variáveis do modelo

---

### 2.6 Discussões e Refinamentos Metodológicos

Esta seção registra pontos específicos da Sessão 2 em que a discussão
crítica entre o autor e a IA de apoio resultou em ajustes metodológicos
ou conceituais significativos. O objetivo é tornar transparente o processo
decisório do projeto e evidenciar que as decisões finais são autorais,
não simplesmente absorvidas de sugestões automatizadas.

**(1) Manutenção do desvio relativo de renda**

A IA de apoio inicialmente sugeriu substituir `desvio_relativo_renda_pct`
pelo CV verdadeiro como medida única de instabilidade. O autor argumentou
que as duas métricas medem fenômenos diferentes — gap conjuntural (com
sinal) vs. dispersão estrutural (sempre positiva) — e que ambas têm valor
analítico. Decisão final: manter as duas variáveis, com nomes claros.

**(2) Recusa de dimensão circular no GROUP BY**

Surgiu a possibilidade de adicionar faixa de renda como dimensão de
agregação para reduzir heterogeneidade intra-célula. O autor não aceitou,
implicitamente, por reconhecer que segmentar por renda e depois usar
renda como input do score introduziria circularidade metodológica.
Caminho efetivamente adotado: usar `grupamento_atividade` como dimensão
diferenciadora (não-circular).

**(3) Opção descritiva vs. ponderada para o CV**

Inicialmente a IA recomendou ponderação simples (Opção 1). O autor
questionou por que não a Opção 3 (estatísticas descritivas — média,
mediana, contagem de células com CV alto). A IA reconheceu viés de
simetria injustificado e propôs Opção 3. O autor então questionou se
três métricas de CV não seriam excessivas para o objetivo. Decisão
final: voltar à Opção 1 (ponderada), mas pelo motivo correto
(explicabilidade), não pelo motivo original (consistência cosmética).

**(4) Crítica ao excesso de sofisticação estatística**

O autor levantou que sofisticação metodológica precisa ser proporcional
ao objetivo e ao público do entregável. Como o projeto não faz scoring
individual e o público inclui gerentes de áreas não-técnicas, métricas
finas (mediana de CV, contagens condicionais, decomposição de variância)
poderiam comprometer explicabilidade. A IA concordou e ajustou a
recomendação.

**(5) Recusa do termo "thin file premium"**

A IA introduziu o termo "thin file premium" para descrever profissionais
qualificados informais de alta renda. O autor recusou o termo (inadequado
e enviesado por linguagem de marketing financeiro) e refinou a
conceituação para "invisível por escolha", baseado na distinção entre
crédito disponível e crédito tomado.

**(6) Distinção entre bancarizado, com crédito calculado e tomador**

Conceituação proposta integralmente pelo autor durante a Sessão 2.
A IA não havia articulado essa distinção. Passou a integrar a tipologia
conceitual do projeto (seção 2.3).

**(7) Subsegmentar todos os perfis, não apenas Autônomos**

A IA sugeriu inicialmente subsegmentar apenas Autônomos por
`grupamento_atividade`, dado que era o perfil com CV mais alto. O autor
questionou se tratamento assimétrico não geraria viés analítico.
A IA concordou após reflexão: tratar `grupamento_atividade` como
dimensão padrão para todos os 5 segmentos.

**(8) Intuição sobre agricultura como contaminadora do CV**

A hipótese de que a agricultura seria o principal puxador da
heterogeneidade de Autônomos foi levantada pelo autor antes da
execução da query exploratória. Os dados confirmaram a hipótese:
CV de Autônomos agrícolas ~1,4 vs. ~0,7 nas demais atividades.

**(9) Recusa de re-rodar EDA retroativamente**

Após a decisão de incorporar `grupamento_atividade` como dimensão padrão,
a IA sugeriu re-rodar as 4 queries originais com essa dimensão. O autor
recusou: a EDA cumpriu sua função descritiva, e re-rodar
retroativamente teria custo elevado e ganho marginal. Decisão final:
registrar a query exploratória como complemento, não substituição.

**(10) Pergunta sobre compatibilidade territorial Bacen × IBGE**

Pergunta crítica levantada pelo autor antes da Sessão 5. Sem essa
provocação, o planejamento territorial teria avançado sem verificar
compatibilidade entre fontes. Resposta documentada na seção 2.5:
ESTBAN usa código IBGE de município como chave, compatibilidade
resolvida por agregação ascendente para o nível da PNAD.

---

### 2.7 Próxima Sessão — Deflação pelo IPCA

Aplicação do IPCA acumulado sobre as variáveis monetárias da view base
para harmonização temporal das comparações. Refinamentos esperados:

- Decidir entre IPCA nacional único vs. IPCAs regionais
- Definir ano-base para o deflacionamento
- Atualizar a view base (ou criar view-filha) com colunas deflacionadas
- Re-confirmar achados nominais de evolução de renda em termos reais

---

## Sessão 3 — Deflação pelo IPCA
**Status:** Concluída

---

### 3.1 Decisões Metodológicas

- **Índice:** IPCA nacional único. *Decisão do autor:* índices regionais
  exigiriam distribuir corretamente cada IPCA-RM pelas células
  correspondentes, e as cestas regionais (urbanas/metropolitanas) não
  representam o escopo majoritariamente agrícola e rural-disperso do
  projeto. O nacional é o estimador menos enviesado para um recorte que
  não casa com nenhuma cesta regional específica.
- **Ano-base:** 2025 (preços de 2025). Justificativa comunicacional:
  valores expressos na régua do ano mais recente são os mais intuitivos
  para o público executivo. A escolha de base não altera conclusões
  relativas, apenas o denominador.
- **Critério temporal do deflator:** índice médio dos 12 meses de cada ano.
  *Justificativa corrigida em discussão:* a renda individual da PNAD é um
  retrato do mês de referência, não um fluxo anual — mas a
  `renda_media_efetiva` da célula-perfil agrega respondentes entrevistados
  ao longo dos 12 meses (a PNAD distribui a amostra no tempo). O deflator
  coerente com uma média de retratos espalhados pelo ano é o nível médio
  de preços do ano, não o de dezembro. Hipótese assumida: amostra
  aproximadamente uniforme ao longo do ano dentro de cada célula.
- **Variáveis deflacionadas:** `renda_media_efetiva` e `renda_media_habitual`,
  apenas. *Decisão do autor:* não deflacionar medidas estatísticas
  derivadas — `desvio_absoluto_renda` (o gap será usado apenas em termos
  percentuais, via `desvio_relativo_renda_pct`), `std_renda_efetiva` e
  `cv_renda_efetiva` (este é adimensional; numerador e denominador escalam
  pelo mesmo fator intra-ano e o CV deflacionado é idêntico ao nominal —
  invariância documentada para evitar dupla contagem na Sessão 4).

---

### 3.2 Fonte e Fatores

- Fonte: IBGE/SIDRA tabela 1737, variável "Número-índice
  (base dez/1993 = 100)", série mensal jan/2021–dez/2025, Brasil.
- Uso do número-índice (e não da variação acumulada) por carregar o nível
  diretamente: `fator_ano = índice_médio_2025 / índice_médio_ano`.

| Ano | Índice médio (12m) | Fator (base 2025) |
|-----|--------------------|-------------------|
| 2021 | 5.827,78 | 1,252765 |
| 2022 | 6.368,60 | 1,146380 |
| 2023 | 6.661,15 | 1,096033 |
| 2024 | 6.952,07 | 1,050168 |
| 2025 | 7.300,84 | 1,000000 |

- Inflação acumulada aplicada (média 2021 → média 2025): **25,3%**. Nota: a
  EDA estimara ~30% de cabeça; o valor real é menor. O critério
  dezembro-contra-dezembro daria 21,0% — a diferença de ~4 p.p. é o efeito
  da escolha média-anual vs. ponto-final, e justifica registrar o critério
  explicitamente.

---

### 3.3 Arquitetura — Decisão sobre Materialização

- **View-filha em vez de colunas embutidas na view base.** *Decisão do
  autor:* a view base permanece extração pura da PNAD (fonte da verdade
  nominal); cada fonte externa entra como camada rastreável. Estabelece o
  padrão que valerá para ESTBAN e Censo (Sessão 5): integração externa =
  nova camada, não alteração da base.
- **Tabela auxiliar de fatores** (`aux_fatores_deflacao_ipca`) em vez de
  constantes espalhadas nas queries: auditável, reaproveitável, e isola a
  fonte (rebasear ou revisar o IPCA = trocar uma tabela, não dezenas de
  queries).
- Objetos criados em `credito-pnad-2026.pnad_rend_trab`:
  - `aux_fatores_deflacao_ipca` (tabela)
  - `view_renda_media_uf_deflacionada` (view-filha; adiciona
    `renda_media_efetiva_real` e `renda_media_habitual_real` ao lado das
    nominais)
- **Nota técnica:** `ano` é `STRING` na view base (padrão da basedosdados —
  microdados chegam como string). A tabela auxiliar alinhou o tipo (não se
  casta a view base). Padrão a observar em todos os joins externos futuros,
  especialmente código de município na Sessão 5.
- `JOIN` de enriquecimento feito com `LEFT JOIN` (não `INNER`): linha sem
  fator correspondente fica visível com `NULL` em vez de desaparecer
  silenciosamente.

---

### 3.4 Achados Reais (validação contra a base)

Reconfirmação das hipóteses nominais da EDA, agora em termos reais
(preços de 2025):

| Categoria | Var. nominal 21→25 | Var. real 21→25 |
|-----------|--------------------|-----------------|
| Autônomos | +50% | **+19,9%** |
| Empregado privado s/ carteira | +47% | **+17,4%** |
| Trab. doméstico s/ carteira | +21% | **−3,1%** |
| Empregado público s/ carteira | −3% | **−22,4%** |

- A deflação **inverte a leitura** de duas categorias: doméstico, que
  parecia crescer, perdeu poder de compra; empregado público sem carteira
  teve perda real severa (quase ¼ do poder de compra). Confirma que a
  Sessão 3 tem peso analítico, não cosmético.
- *Pendência herdada para Sessão 4:* as variações por categoria acima usam
  os agregados da EDA cruzados com os fatores. A view-filha já permite
  recalcular isso célula a célula com `grupamento_atividade` como dimensão —
  recomendado refazer no início da Sessão 4 sobre a base real.

---

### 3.5 Próxima Sessão — Construção e Calibração do Score

Pendências que entram na Sessão 4 (herdadas da 2.5, inalteradas pela
deflação):

- Tratamento das 42 células com `cv_renda_efetiva` null e das 180 com CV > 2
- Dominância de Autônomos (~67%) no balanceamento da clusterização
- `media_horas_trabalhadas` estruturalmente nula fora de Autônomos —
  imputar ou excluir
- Usar `renda_*_real` (não nominal) como input dos subíndices de
  Capacidade Financeira

---

## Pré-Sessão 4 — Discussão Metodológica (avaliação de nota técnica externa)
**Status:** Decisões registradas; Sessão 4 ainda não iniciada

Esta seção registra decisões tomadas a partir da avaliação crítica de uma
nota técnica produzida com apoio do ChatGPT (`nota_tecnica_reflexoes_sessao_4.md`),
discutida antes da abertura formal da Sessão 4. A nota foi majoritariamente
**convergente** com a arquitetura já consolidada; os pontos abaixo são os que
geraram decisão nova ou refinamento.

### P4.1 Gate de validação — score vs. proxy de renda

Risco identificado na nota: renda, escolaridade, posição ocupacional e
maturidade são empiricamente correlacionadas; mesmo com subíndices
conceitualmente separados, o score composto pode acabar medindo
essencialmente **posição socioeconômica** (capacidade), não estabilidade.

*Decisão:* incorporar como **gate de validação obrigatório** da Sessão 4 a
correlação de Pearson entre o score final e a `renda_media_efetiva_real`.
Critério de alerta: correlação acima de ~0,8 indica que o score virou
termômetro de renda → reponderar para baixo o subíndice de Capacidade
Financeira. Diagnóstico barato e honesto, executado após a consolidação do
score.

### P4.2 Pesos dos subíndices — modelo híbrido como linha de partida

Três cenários considerados (da nota): (A) pesos iguais 25% cada; (B) pesos
integralmente derivados do PCA; (C) híbrido — predominância dos pesos
conceituais, PCA como ajuste.

*Decisão:* adotar o **Cenário C (híbrido)** como hipótese de trabalho,
coerente com o princípio de proporcionalidade do projeto (PCA valida e
calibra na margem; não substitui a interpretação econômica). Pesos iguais
permanecem como baseline de comparação. Decisão final de pesos depende do
resultado do gate P4.1 e do PCA.

### P4.3 Balanceamento diagnóstico do PCA ("balanceamento virtual comparativo")

Conceito de **dominância estrutural** (da nota): como autônomos são ~67% do
escopo, ~67% da variância total que o PCA otimiza vem deles. Os primeiros
componentes principais — que estruturam o espaço onde o K-Means desenha os
clusters — podem alinhar-se com "o que separa autônomos entre si", deixando
os perfis menores (familiar auxiliar, público sem carteira) projetados numa
régua que não é a deles.

*Discussão crítica do autor:* a proporção 67% reflete a realidade da PNAD e
**não deve ser alterada** na base de produção — não mexemos nos dados, apenas
recortamos. Questão levantada: se a base reflete a realidade, por que
balancear?

*Esclarecimento e decisão:* a distinção é entre **balancear para corrigir**
(rejeitado — distorceria a realidade e contaminaria os clusters) e
**balancear para diagnosticar** (aceito — apenas mede). O procedimento:

1. PCA na base real (3.476 células, proporções intactas) → guarda os
   *loadings*. Esta é a régua de produção; é ela que segue no pipeline.
2. Cópia temporária e descartável com N igual de células por
   `posicao_ocupacao` (amostragem aleatória sem reposição). Não reflete o
   Brasil e não pretende; é instrumento de laboratório.
3. PCA na cópia balanceada → guarda *esses* loadings.
4. Comparação dos dois conjuntos de loadings (ângulo entre subespaços ou
   correlação componente a componente).

Leitura: loadings **semelhantes** → estrutura robusta/universal, dominância
não distorce a régua, segue-se tranquilo com o PCA da base real. Loadings
**muito diferentes** → dominância confirmada; é **achado analítico** (não
defeito), que pode motivar clusterização por estrato ocupacional. Em nenhum
cenário a base de produção é alterada.

*Explicitamente NÃO adotados:* oversampling, undersampling definitivo, SMOTE,
geração sintética. O balanceamento é exclusivamente diagnóstico, sobre cópia
descartável.

*Ressalva técnica:* se `familiar auxiliar` (~3-5% do escopo) tiver
pouquíssimas células, a base balanceada (limitada pela menor categoria) pode
ficar pequena demais para um PCA estável — nesse caso a divergência de
loadings pode ser efeito de tamanho de amostra, não de dominância real.
Alternativas: balancear até a segunda menor categoria, ou rodar PCA
estratificado por posição ocupacional e comparar eixos entre estratos.
Decisão da rota fica para a execução, vendo os N reais por categoria.

### P4.4 Risco sistemático / resiliência econômica — conceito aceito, materialização adiada

A nota (seção 7.1) sugeriu um índice de resiliência econômica. Na leitura
inicial, pareceria redundante com `desvio_relativo_renda_pct` e
`cv_renda_efetiva` (que já estão em Estabilidade Econômica — criar índice das
mesmas variáveis seria dupla contagem).

*Refinamento do autor:* a intenção não era re-empacotar o gap interno, mas
introduzir uma dimensão de **risco sistemático** — exposição a choques
externos correlacionados (macro, setorial, climático) que atingem uma classe
inteira de uma vez. Distinção válida e qualitativamente diferente do que o
modelo captura hoje: o CV mede **volatilidade observada num retrato**, não
**fragilidade latente a choques sistêmicos**. Duas células com mesmo CV podem
ter exposição externa completamente diferente (ex.: autônomo agrícola
— safra, preço de commodity, seca — vs. autônomo de comércio urbano).

*Avaliação:* conceito aprovado, mas **materialização como subíndice de score
recusada/adiada** por dois motivos:
- **Série insuficiente:** medir risco sistemático de forma defensável exigiria
  estimar a sensibilidade da renda setorial ao ciclo macro (um *beta*) ou a
  variância interanual por setor. Com apenas 5 pontos anuais (2021–2025),
  qualquer estimativa é estatisticamente frágil.
- **Proporcionalidade:** adicionaria sofisticação não-auditável pelo público
  executivo, com ganho de informação incerto.

*Observação central:* uma versão modesta do conceito **já está latente** na
decisão de tratar `grupamento_atividade` como dimensão padrão. A agricultura
puxando o CV para ~1,4 **é** a assinatura do risco sistemático aparecendo nos
dados — pela porta da heterogeneidade, sem o rótulo financeiro.

*Decisão:* (a) registrar o conceito como **lente interpretativa** dos clusters
e do storytelling ("cluster estável porém setorialmente exposto"); (b)
opcionalmente, ao final da Sessão 4, testar variância interanual da renda real
por setor como **variável diagnóstica** (não como peso no score) — mesma
filosofia do balanceamento diagnóstico do PCA; (c) deixar registrada como
**evolução futura** (módulo posterior) a possibilidade de cruzar
`grupamento_atividade` com fonte externa de volatilidade setorial (PIB
setorial trimestral do IBGE, índices de preços agrícolas) para estimar
exposição com série adequada — expansão de escopo de fontes, fora da Sessão 4.

### P4.5 Dimensionamento de clusters via peso amostral

A nota (seção 7.2) sugeriu dimensionar os clusters (população potencial por
cluster, tamanho de mercado). *Avaliação: incluir* — é a ponte entre o
analítico e o executivo (um cluster sem tamanho é curiosidade estatística; com
tamanho é case de negócio).

*Ponto técnico:* a view base hoje guarda `total_entrevistados` (contagem bruta
de respondentes), não população expandida. Dimensionamento populacional real
exige a **soma dos pesos amostrais da PNAD** por célula (variável de peso com
calibração de pós-estratificação). *Ação:* verificar se a `basedosdados` expõe
a variável de peso; se sim, avaliar adicionar coluna de população expandida
(`SUM(peso)`) à base **antes** de clusterizar. Se não expuser, documentar como
limitação e dimensionar por contagem de respondentes (proxy mais grosseiro).

### P4.6 Reenquadramento de escopo — de "crédito" para relacionamento financeiro multiproduto

*Insight do autor:* o escopo do projeto não deve se restringir a crédito, mas
abranger um espectro mais amplo de produtos financeiros — da porta de entrada
(conta corrente, meio de pagamento) a operações complexas (financiamento,
capital de giro). A invisibilidade estrutural começa antes do crédito, em "não
tem relação transacional nenhuma".

*Avaliação:* o ajuste é de **enquadramento, não de cálculo**. O score
socioeconômico (estabilidade + capacidade) é agnóstico ao produto financeiro
de destino. *Decisão:* (a) **não reabrir** as Sessões 1–3 — base e deflação
são indiferentes ao produto; (b) ajustar o **tom conceitual** (arquitetura,
README, storytelling) de "potencial de crédito" para "potencial de
relacionamento financeiro / inclusão", com crédito como um dos andares; (c)
materializar concretamente na **Sessão 5**, construindo a profundidade
financeira territorial como índice **multiproduto** a partir das rubricas do
ESTBAN além de crédito (depósitos à vista, poupança, nº de agências).

### P4.7 Indicador de Oportunidade de Inclusão Financeira — confirmação de agenda

A nota (seções 5 e 7.3) propôs *Oportunidade = Potencial × Gap de Profundidade
Financeira*. *Avaliação:* não é ideia nova — é a Estratégia Territorial (seção
12 da arquitetura) já consolidada. Adotada a nuance terminológica **"gap de
profundidade"** (distância até um patamar de referência) em vez de "baixa
profundidade" (nível absoluto), por dialogar melhor com o reenquadramento
multiproduto (P4.6). Confirma a separação conceitual potencial × oportunidade.

### P4.8 Ordem de execução sugerida para a Sessão 4

Tratamento de nulos/outliers (42 células CV null, 180 com CV > 2) **antes** da
padronização z-score — outlier não tratado distorce média e desvio e contamina
todo o score a jusante.

---

## Sessão 4 — Subseção A: Auditoria Diagnóstica da View Base
**Status:** Concluída (diagnóstico). Correções e implementação do score em subseções seguintes.

Na abertura da Sessão 4, antes de construir o score, dois gatilhos levaram a uma
auditoria sistemática da view base contra a documentação oficial e contra os
próprios dados:

1. O achado de que `V1028` (peso de pós-estratificação) destrava a P4.5 expôs que
   a view base usava **média aritmética simples**, não ponderada.
2. A investigação do peso revelou, por um volume destoante (uma categoria
   territorial com 1,3 milhão de respondentes), que o mapeamento de uma variável
   estava incorreto — o que motivou auditar **todas** as variáveis da view.

A auditoria confirmou **um problema de método (ponderação)** e **quatro erros de
mapeamento de variável**, todos originados na implementação da Sessão 1. Escopo e
rendas permaneceram íntegros — razão pela qual os achados de evolução de renda da
EDA e a Sessão 3 inteira sobrevivem sem reprocessamento conceitual.

---

### A.1 Método de verificação adotado

Princípio estabelecido: **uma variável se audita pelo que ela contém, não pelo que
se presume que contenha.** Cada suspeita foi resolvida empiricamente, sem depender
de fé em documentação:

- **Autodeclaração de tipo:** `SELECT MIN, MAX, COUNT(DISTINCT)` por variável. Uma
  variável que varre de 1 a 2 é binária; uma que varre de 1 a 120 é contínua.
  Os dados se autodeclaram independentemente de qualquer dicionário.
- **Contagem de categorias:** `COUNT(DISTINCT)` + volume por código, cruzado com o
  dicionário oficial da `basedosdados` (`br_ibge_pnadc.dicionario`) e com o programa
  de leitura SAS do IBGE.
- **Coerência de volume:** o tamanho relativo de cada categoria valida o rótulo
  (ex.: código raro com volume pequeno confirma a versão correta do mapeamento).

Esse procedimento descartou a hipótese de descasamento de versão/visita do
dicionário: as variáveis corretas existem na tabela, com os intervalos esperados.
Os erros foram de **seleção/transcrição de variável na Sessão 1**, não de fonte.

---

### A.2 Diagnóstico do método de ponderação (decisão B)

A view base usava `AVG(VD4020)` (média simples), não ponderada pelo peso amostral
`V1028`. Diagnóstico empírico do impacto (sobre a tabela microdados):

- **Desvio relativo mediano (com sinal):** +1,8%
- **Desvio relativo absoluto mediano:** 4,0%
- **Desvio absoluto p90 / p99:** 13,3% / 38,0%
- **Sistematicidade territorial:** desvio médio entre +2,3% e +3,1% entre todos os
  tipos de área — **uniforme**, sem padrão direcional que distorça o eixo geográfico.

*Decisão do autor (B):* adotar a ponderação por `V1028` nas variáveis de renda. O
viés é pequeno e uniforme — o z-score da Sessão 4 o absorveria, e (A) manter média
simples seria defensável. Optou-se por (B) por dois motivos: (1) as médias
ponderadas são as estimativas corretas da população (prática padrão do IBGE),
imprimindo maior honestidade analítica; (2) o custo computacional de ponderar é
nulo, e a abertura da Sessão 4 é o momento mais barato para corrigir, antes de o
score ser erguido sobre a base. A natureza de autoaprendizado do projeto torna o
registro transparente da correção um ativo, não um passivo.

*Distinção registrada:* o peso tem dois usos — (a) **expansor populacional**
(`SUM(V1028)`), incontroverso, necessário para dimensionar clusters (P4.5); e (b)
**ponderador de médias** (`SUM(x·V1028)/SUM(V1028)`), objeto da decisão acima.

*Pendência técnica para a subseção de correção:* decidir se a ponderação se estende
ao desvio-padrão / CV intra-célula. `STDDEV_SAMP` não é ponderado; a coerência plena
exigiria variância ponderada calculada manualmente. Implicação direta no subíndice
de Estabilidade Econômica.

---

### A.3 Erros de mapeamento confirmados

| Variável (view) | Implementação Sessão 1 (errada) | Correto (confirmado) | Método de confirmação |
|---|---|---|---|
| Território | usava só `V1023`, com `5='Rural'` e `4='Urbano fora de RM'` | `V1023` só tem 1–4; `4`=**Resto da UF**; **não existe rural em V1023** | query crua `V1023` (só 1–4) |
| Urbano/Rural | **ausente da view** | `V1022`: `1`=Urbana, `2`=Rural — variável transversal a `V1023` | query cruzada `V1022 × V1023` (587k rurais em "Resto da UF") |
| `V2005` posição domicílio | `CASE` de 16 categorias, deslocado a partir do código 03 | **19 categorias** (versão atual da PNAD) | `COUNT(DISTINCT)`=19 + volume do cód. 03 (11.776 = cônjuge mesmo sexo, raro) |
| Horas trabalhadas | `V4019` (Sim/Não) tratada como horas | **`V4039`** (1 a 120 horas) | autodeclaração: `V4019` min=1/max=2; `V4039` min=1/max=120 |
| Tempo no trabalho | `V4032` (Sim/Não) com faixas de meses inexistentes | **`V4040`** (1–4 faixas) + auxiliares | autodeclaração: `V4032` min=1/max=2; `V4040` min=1/max=4 |

**Detalhamento territorial:** rural e urbano (`V1022`) são **transversais** ao tipo
de área (`V1023`) — existe rural dentro de capital (13.329), de RM (30.276) e de
RIDE (5.350), além do grosso em Resto da UF (586.957). Total rural no escopo:
~636 mil respondentes, antes invisíveis por fusão com urbano sob o rótulo errado.
São dois eixos independentes; ambos necessários.

**Detalhamento `V2005`:** o `CASE` antigo (16 categorias) não distinguia
"cônjuge de sexo diferente / mesmo sexo" nem "filho do casal / filho só do
responsável", deslocando todos os rótulos a partir do código 03. Rótulos oficiais
das 19 categorias anexados em A.5.

---

### A.4 Decisão de design — granularidade de `tempo_no_trabalho`

A variável nativa `V4040` tem 4 faixas, mas "2 anos ou mais" concentra **65,4%** do
escopo — baixo poder discriminante. A abertura desse balde via `V40403` (anos)
revelou distribuição rica e quase uniforme:

| Faixa fina (dentro de "2 anos ou mais") | % do balde |
|---|---|
| 2 a 4 anos | 31,2% |
| 5 a 9 anos | 21,1% |
| 10 a 19 anos | 22,3% |
| 20+ anos | 25,5% |

*Decisão do autor:* adotar **granularidade fina (7 faixas)** — as 3 faixas nativas
curtas (`V4040` 1–3) mais 4 faixas longas derivadas de `V40403`. Justificativa
econômica: tempo no trabalho é proxy de estabilidade ocupacional (núcleo do
subíndice de Estabilidade); distinguir o informal veterano (20+ anos) do recém-entrado
(2–4 anos) é sinal de alto valor que a variável nativa descartava. Cobertura validada:
a soma das faixas finas (1.302.596) bate exatamente com o total da faixa 4 — zero
nulos, nenhum respondente perdido na transição.

Faixas finais: Menos de 1 mês · 1 mês a <1 ano · 1 a <2 anos · 2 a 4 anos ·
5 a 9 anos · 10 a 19 anos · 20+ anos.

---

### A.5 Mapa de correções para a subseção seguinte (reconstrução da view)

1. **Ponderação** por `V1028` nas rendas (`SUM(x·V1028)/SUM(V1028)`) + coluna
   `populacao_expandida = SUM(V1028)`.
2. **`V1022`** adicionado como dimensão urbano/rural (`1`=Urbana, `2`=Rural).
3. **`V1023`** relabel: Capital / Resto da RM / Resto da RIDE / **Resto da UF**
   (remover "Rural" e "Urbano fora de RM").
4. **`V2005`** remapeado para as 19 categorias oficiais.
5. **`V4039`** substitui `V4019` para `media_horas_trabalhadas`.
6. **`V4040` + `V40403`** substituem `V4032` para `tempo_no_trabalho` (7 faixas).
7. **Pendência:** decidir ponderação do desvio-padrão / CV intra-célula.

**Impacto retroativo a tratar:** EDA territorial precisa ser refeita (recorte de
área estava errado); achados de renda da EDA e Sessão 3 permanecem válidos (escopo
`VD4009` e rendas `VD4020`/`VD4016` confirmados íntegros).

**Rótulos oficiais V2005 (19 categorias):**
01 Pessoa responsável · 02 Cônjuge sexo diferente · 03 Cônjuge mesmo sexo ·
04 Filho do responsável e do cônjuge · 05 Filho somente do responsável ·
06 Enteado(a) · 07 Genro/nora · 08 Pai/mãe/padrasto/madrasta · 09 Sogro(a) ·
10 Neto(a) · 11 Bisneto(a) · 12 Irmão/irmã · 13 Avô/avó · 14 Outro parente ·
15 Agregado(a) · 16 Convivente · 17 Pensionista · 18 Empregado(a) doméstico(a) ·
19 Parente do(a) empregado(a) doméstico(a).

---

### A.6 Aprendizados metodológicos

- **Validar variáveis contra os dados antes de construir lógica sobre elas.** Um
  `SELECT MIN, MAX, COUNT(DISTINCT)` por variável, na Sessão 1, teria evitado os
  quatro erros em segundos. Passa a ser etapa obrigatória ao incorporar qualquer
  variável nova (princípio a observar especialmente nos joins externos da Sessão 5).
- **Implementação inicial das variáveis foi da IA de apoio (Claude), na Sessão 1;**
  os erros de mapeamento originaram-se ali, sem validação contra a fonte. Registro
  de responsabilidade explícito.
- **Desconforto intelectual é um dado.** O questionamento do autor sobre a
  inconsistência ("não faz sentido por tipo de variável") foi o que destravou a
  auditoria. O aprendizado correspondente: sinais de incômodo analítico merecem ser
  puxados até o fim, inclusive contra sugestões automatizadas de IA.
- **Momento da correção.** Erros contidos antes da construção do score; reparo
  custou uma subseção de diagnóstico, não o projeto. A disciplina de auditar a
  fundação antes de erguer o modelo provou seu valor.

---

*Documento mantido manualmente. Atualizar ao final de cada sessão.*
*Última atualização: Sessão 4 — Subseção A (auditoria diagnóstica da view base).
Quatro erros de mapeamento e o método de ponderação confirmados; correções (Subseção B)
e implementação do score (Subseção C) pendentes.*
