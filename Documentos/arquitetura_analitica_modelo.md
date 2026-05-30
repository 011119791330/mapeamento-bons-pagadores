# Arquitetura Analítica do Modelo

## Projeto

# Mapeamento de Potencial de Inclusão Financeira e Perfis Thin File no Brasil

---

# 1. Visão Geral do Projeto

O projeto busca identificar perfis populacionais com potencial de estabilidade financeira e baixa profundidade de relacionamento com o Sistema Financeiro Nacional (SFN), utilizando exclusivamente dados públicos.

A proposta parte do conceito de *thin file*, utilizado para representar indivíduos com histórico de crédito inexistente ou insuficiente, mas que não necessariamente apresentam comportamento financeiro de alto risco.

O foco analítico concentra-se em segmentos economicamente ativos inseridos em relações de trabalho menos formalizadas, frequentemente sub-representados nos mecanismos tradicionais de avaliação de crédito e bancarização.

O modelo pretende explorar padrões socioeconômicos capazes de indicar potencial de inclusão financeira sustentável, utilizando técnicas estatísticas e de segmentação analítica aplicadas a microdados públicos.

Além da PNAD Contínua, o projeto prevê integração gradual com bases territoriais e estruturais do Censo Demográfico do IBGE, permitindo enriquecer análises espaciais, características domiciliares e padrões regionais de infraestrutura socioeconômica.

---

# 2. Objetivo Analítico

O objetivo do modelo não é prever inadimplência individual nem substituir mecanismos formais de concessão de crédito.

A proposta consiste em construir uma estrutura analítica exploratória capaz de:

* identificar padrões socioeconômicos associados à estabilidade financeira potencial;
* segmentar perfis populacionais sub-representados no SFN;
* mapear grupos com possível potencial de bancarização;
* apoiar análises territoriais de inclusão financeira;
* identificar concentrações regionais de perfis thin file economicamente promissores.

---

# 3. Tipologia Conceitual de Invisibilidade ao SFN

A partir da Sessão 2 (EDA), foi formalizada uma distinção conceitual que orienta o escopo prioritário do projeto.

## 3.1 Três status frequentemente confundidos

| Status | Significado |
| ------ | ----------- |
| Bancarizado | Tem relação transacional com banco (conta, cartão, recebimento) |
| Com crédito calculado | Banco já avaliou risco e ofereceu ou pré-aprovou limite |
| Tomador de crédito | De fato utiliza crédito (cheque especial, parcelado, financiamento) |

Cada status é subconjunto do anterior, mas a relação não é trivial. É possível ter alto crédito disponível e não tomar — não por incapacidade, mas por administração financeira disciplinada. Esse perfil é frequentemente classificado como thin file por modelos tradicionais, mas o sistema já o enxerga.

## 3.2 Dois tipos de invisibilidade

* **Invisível estrutural — alvo prioritário do projeto:** pessoa ainda não analisada pelo sistema financeiro. Não tem score, não tem crédito calculado, não recebeu oferta. Representa lacuna real de inclusão financeira.

* **Invisível por escolha — fora do alvo prioritário:** pessoa com crédito disponível que não toma. Aparece em modelos tradicionais como ausência de histórico, mas o sistema já a enxerga e atende comercialmente.

A distinção é central para o entregável final: o projeto busca **descoberta de população nova**, não caça a clientes já existentes no radar do SFN.

## 3.3 Tratamento dos perfis fora do alvo nos dados

Os perfis invisíveis por escolha (tipicamente profissionais qualificados informais capitalizados — médicos PJ, advogados autônomos, consultores) são mantidos na base por honestidade analítica. Na clusterização (Sessão 4), receberão rotulagem explícita como "fora do alvo prioritário", permitindo isolá-los analiticamente sem contaminação dos clusters principais.

---

# 4. Fontes de Dados

| Fonte | Finalidade | Sessão de entrada |
| ----- | ---------- | ----------------- |
| PNAD Contínua (IBGE) | Perfil socioeconômico individual — base primária | Sessão 1 |
| IPCA (IBGE/IPEAData) | Deflator monetário para harmonização temporal | Sessão 3 |
| ESTBAN (Banco Central) | Profundidade financeira regional por município | Sessão 5 |
| Censo Demográfico (IBGE) | Patrimônio domiciliar, infraestrutura urbana | Sessão 5 |
| Indicadores BCB (Selic, IPCA, expectativas, IDF) | Contexto macroeconômico para storytelling | Sessão 6 |

**Compatibilidade territorial:** ESTBAN, PNAD e Censo compartilham o código IBGE de município como chave primária. A integração será feita por agregação ascendente do ESTBAN (granularidade municipal) para o nível analítico da PNAD (UF + RM/RIDE + recorte urbano/rural).

---

# 5. Unidade Analítica

A unidade primária de análise é o **respondente individual** da PNAD Contínua, mas a unidade operacional do modelo (após agregação da view base) é a **célula-perfil**: combinação única de variáveis categóricas no GROUP BY da view, com pelo menos 30 respondentes.

As análises territoriais posteriores serão realizadas em nível agregado:

* Regiões Metropolitanas (RMs);
* RIDEs;
* Macrorregiões geográficas;
* Recortes urbano/rural.

Essa abordagem equilibra granularidade, robustez estatística e interpretabilidade executiva.

---

# 6. Recorte Populacional

O modelo concentra-se em segmentos da população economicamente ativa com menor inserção formal no sistema tradicional de crédito.

**Incluídos:**

* Trabalhadores autônomos;
* Empregados sem carteira assinada;
* Empregados domésticos sem carteira;
* Empregados públicos sem vínculo formal;
* Trabalhadores familiares auxiliares.

**Excluídos:**

* Empregados com carteira assinada;
* Servidores estatutários;
* Militares.

O filtro de escopo populacional vive na view base (`WHERE VD4009 IN ('2', '4', '6', '9', '10')`), garantindo consistência em todas as análises descendentes.

---

# 7. Arquitetura Conceitual do Score Composto

O modelo assume que o potencial de estabilidade financeira possui natureza multidimensional. O score composto é estruturado em quatro subíndices conceituais independentes, mais interpretáveis e modulares do que uma abordagem monolítica.

## 7.1 Subíndice de Estabilidade Econômica

Objetivo: avaliar previsibilidade ocupacional e estabilidade de geração de renda.

Variáveis associadas:

* `tempo_no_trabalho`;
* `cv_renda_efetiva` (coeficiente de variação intra-célula — volatilidade verdadeira);
* `media_horas_trabalhadas`;
* `desvio_relativo_renda_pct` (sinal conjuntural complementar — gap entre renda habitual e efetiva).

Hipótese econômica: maior estabilidade ocupacional e menor volatilidade tendem a indicar maior previsibilidade financeira mesmo em contextos de informalidade.

## 7.2 Subíndice de Capacidade Financeira

Objetivo: estimar potencial de geração de renda e capacidade econômica estrutural.

Variáveis associadas:

* `renda_media_habitual`;
* `renda_media_efetiva`;
* `escolaridade`;
* `grupamento_atividade` (dimensão padrão a partir da Sessão 2).

Hipótese econômica: maior capital humano e maior capacidade recorrente de geração de renda tendem a indicar maior potencial de relacionamento financeiro sustentável.

Observação metodológica: as variáveis monetárias serão deflacionadas previamente (Sessão 3) para garantir comparabilidade temporal e evitar distorções inflacionárias.

## 7.3 Subíndice de Vulnerabilidade Familiar

Objetivo: identificar pressões estruturais sobre orçamento e capacidade financeira.

Variáveis associadas:

* `media_moradores_domicilio`;
* `media_filhos`;
* Características domiciliares agregadas do Censo IBGE (Sessão 5).

Hipótese econômica: maior pressão domiciliar pode reduzir capacidade de poupança, estabilidade financeira e margem de absorção de choques.

## 7.4 Subíndice de Maturidade Socioeconômica

Objetivo: representar estágio de consolidação econômica e ocupacional.

Variáveis associadas:

* `faixa_etaria`;
* `posicao_ocupacao`;
* `posicao_no_domicilio`;
* Proxy de patrimônio imobiliário via Censo (Sessão 5).

Hipótese econômica: indivíduos em estágios mais maduros de consolidação profissional e patrimonial tendem a apresentar maior estabilidade financeira potencial.

---

# 8. Dimensão Transversal — Grupamento de Atividade

A partir da Sessão 2, `grupamento_atividade` foi promovido a **dimensão analítica padrão**, ao lado de `posicao_ocupacao`. A decisão decorre de achado empírico: a agricultura (que atravessa todas as categorias ocupacionais e representa 77–84% de Autônomos) é o principal puxador de heterogeneidade intra-célula no escopo do projeto.

Tratar `grupamento_atividade` como dimensão padrão:

* Diferencia realidades econômicas dentro da mesma categoria ocupacional;
* Mantém tratamento simétrico entre os 5 segmentos do escopo;
* Evita criar segmentos artificiais (como subdivisões por renda, que seriam circulares);
* Preserva interpretabilidade da clusterização.

---

# 9. Pipeline Analítico

Fluxo metodológico do projeto:

1. Estruturação e consolidação dos microdados (Sessão 1)
2. Limpeza e tratamento estatístico (Sessão 1)
3. Construção das variáveis derivadas (Sessão 1)
4. Análise exploratória (Sessão 2)
5. Deflacionamento das variáveis monetárias e harmonização temporal (Sessão 3)
6. Padronização estatística — z-score com truncamento (Sessão 4)
7. Construção dos subíndices socioeconômicos (Sessão 4)
8. Consolidação do score composto (Sessão 4)
9. Redução dimensional via PCA (Sessão 4)
10. Clusterização dos perfis socioeconômicos (Sessão 4)
11. Integração territorial com Censo IBGE e ESTBAN (Sessão 5)
12. Territorialização dos clusters (Sessão 5)
13. Desenvolvimento dos dashboards e storytelling executivo (Sessão 6)

---

# 10. Estratégia Estatística

O modelo utilizará técnicas de redução dimensional, especialmente Principal Component Analysis (PCA), com os seguintes objetivos:

* identificar redundâncias entre variáveis;
* reduzir multicolinearidade;
* validar a estrutura conceitual dos subíndices;
* calibrar pesos relativos do score composto;
* reduzir ruído estatístico;
* melhorar a eficiência das etapas de clusterização.

O PCA será utilizado como mecanismo complementar de validação estatística, **preservando a interpretabilidade econômica das dimensões conceituais originalmente definidas**.

**Princípio de proporcionalidade adotado:** a sofisticação metodológica deve ser proporcional ao objetivo do projeto (mapeamento de perfis e regiões, não scoring individual) e ao público do entregável final (gerentes de áreas não-técnicas). Decisões metodológicas privilegiam explicabilidade sobre rigor estatístico marginal sempre que o ganho de informação não justifica o custo de comunicação.

---

# 11. Estratégia de Clusterização

Após a consolidação dos componentes socioeconômicos, serão aplicadas técnicas de clusterização não supervisionada.

Objetivos:

* identificar perfis latentes de estabilidade financeira;
* segmentar grupos thin file heterogêneos;
* identificar padrões socioeconômicos recorrentes;
* apoiar análises de inclusão financeira;
* permitir leituras territoriais agregadas;
* **isolar analiticamente o perfil "invisível por escolha"** (alta renda informal capitalizada) para que não contamine os clusters principais.

Técnica inicialmente prevista: K-Means. Podem ser avaliadas posteriormente abordagens hierárquicas ou baseadas em densidade.

**Atenção metodológica:** Autônomos representam ~67% do escopo. A clusterização precisa garantir que o peso dessa categoria não dilua a especificidade dos perfis menores (familiar auxiliar, empregado público sem carteira).

---

# 12. Estratégia Territorial

As análises territoriais buscarão identificar padrões regionais de concentração dos clusters socioeconômicos.

Serão priorizados agrupamentos mais robustos estatisticamente e mais aderentes à proposta executiva do projeto:

* Regiões Metropolitanas (RMs);
* RIDEs;
* Macrorregiões geográficas;
* Recortes urbano/rural.

A territorialização tem caráter complementar à segmentação socioeconômica, buscando identificar **regiões com perfis bons + baixa profundidade do sistema financeiro** — combinação onde mora a lacuna real de inclusão.

**Compatibilidade entre fontes (verificada na Sessão 2):**

| Fonte | Granularidade nativa | Granularidade útil para o projeto |
| ----- | -------------------- | --------------------------------- |
| PNAD | UF + área | UF + RM/RIDE + área |
| ESTBAN | Município (cód. IBGE) | Agregado para RM/UF |
| Censo | Setor censitário | Agregado para RM/UF |

Todas as fontes usam código IBGE de município como chave primária. Integração será feita por agregação ascendente.

---

# 13. Limitações do Modelo

O modelo possui natureza exploratória e não pretende representar mecanismo formal de concessão de crédito.

As inferências baseiam-se exclusivamente em proxies socioeconômicas derivadas de dados públicos, não contemplando:

* histórico bancário individual;
* comportamento transacional;
* dados cadastrais privados;
* informações protegidas por sigilo financeiro;
* modelos proprietários de risco de crédito.

Os resultados devem ser interpretados como instrumento analítico de segmentação e inteligência socioeconômica, não como mecanismo de scoring.

---

# 14. Próximas Etapas

| Etapa | Status |
| ----- | ------ |
| EDA aprofundada | ✅ Concluída (Sessão 2) |
| Deflacionamento e harmonização temporal | 🔜 Próxima (Sessão 3) |
| Padronização e construção dos subíndices | Planejada (Sessão 4) |
| Consolidação do score composto | Planejada (Sessão 4) |
| PCA | Planejada (Sessão 4) |
| Clusterização | Planejada (Sessão 4) |
| Integração com ESTBAN e Censo IBGE | Planejada (Sessão 5) |
| Territorialização dos clusters | Planejada (Sessão 5) |
| Dashboard Power BI | Planejada (Sessão 6) |
| Storytelling executivo | Planejado (Sessão 6) |

---

# 15. Considerações Finais

O projeto busca combinar:

* inteligência socioeconômica;
* análise territorial;
* técnicas estatísticas;
* segmentação analítica;
* dados públicos de larga escala,

com o objetivo de explorar lacunas reais de inclusão financeira no Brasil — entendidas não como ausência genérica de histórico de crédito, mas como **invisibilidade estrutural ao sistema financeiro**.

A proposta busca equilibrar:

* robustez metodológica;
* interpretabilidade executiva;
* viabilidade operacional;
* aderência ao contexto do Sistema Financeiro Nacional;
* honestidade analítica na separação entre o que o sistema **ainda não viu** e o que o sistema **viu e não atende**.

---

*Documento de arquitetura — atualizado ao final da Sessão 2.*
*Reflete decisões metodológicas consolidadas; o histórico das discussões críticas está registrado no changelog do projeto.*
