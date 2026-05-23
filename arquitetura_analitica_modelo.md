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

- identificar padrões socioeconômicos associados à estabilidade financeira potencial;
- segmentar perfis populacionais sub-representados no SFN;
- mapear grupos com possível potencial de bancarização;
- apoiar análises territoriais de inclusão financeira;
- identificar concentrações regionais de perfis thin file economicamente promissores.

---

# 3. Fontes de Dados

| Fonte                         | Finalidade                                                  |
| ----------------------------- | ----------------------------------------------------------- |
| PNAD Contínua (IBGE)          | Perfil socioeconômico individual                            |
| Censo Demográfico (IBGE)      | Estrutura domiciliar, territorial e características urbanas |
| ESTBAN (Banco Central)        | Profundidade financeira regional                            |
| Banco Central do Brasil (BCB) | Indicadores econômicos, monetários e financeiros            |
| IBGE                          | Indicadores territoriais e demográficos complementares      |
| IPEAData                      | Indicadores econômicos complementares                       |

---

# 4. Unidade Analítica

A unidade primária de análise do modelo é o indivíduo respondente da PNAD Contínua.

As análises territoriais posteriores serão realizadas em nível agregado, priorizando agrupamentos regionais estatisticamente mais robustos e operacionalmente mais interpretáveis, como:

- Regiões Metropolitanas (RMs);
- RIDEs;
- macrorregiões geográficas;
- recortes urbano/rural.

Essa abordagem busca equilibrar:

- granularidade analítica;
- robustez estatística;
- viabilidade operacional;
- interpretabilidade executiva.

Em etapas posteriores, dados estruturais do Censo IBGE poderão complementar as análises territoriais, especialmente em dimensões relacionadas à infraestrutura urbana, densidade domiciliar e características socioespaciais.
