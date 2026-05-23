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

* Regiões Metropolitanas (RMs);
* RIDEs;
* macrorregiões geográficas;
* recortes urbano/rural.

Essa abordagem busca equilibrar:

* granularidade analítica;
* robustez estatística;
* viabilidade operacional;
* interpretabilidade executiva.

Em etapas posteriores, dados estruturais do Censo IBGE poderão complementar as análises territoriais, especialmente em dimensões relacionadas à infraestrutura urbana, densidade domiciliar e características socioespaciais.

---

# 5. Recorte Populacional

O modelo concentra-se em segmentos da população economicamente ativa com menor inserção formal no sistema tradicional de crédito.

Foram priorizados:

* trabalhadores por conta própria;
* empregados sem carteira assinada;
* empregados domésticos sem carteira;
* empregados públicos sem vínculo formal;
* trabalhadores familiares auxiliares.

Foram excluídos segmentos com maior estabilidade institucional e maior acesso histórico ao crédito formal, como:

* empregados com carteira assinada;
* servidores estatutários;
* militares.

---

# 6. Arquitetura Conceitual do Modelo

O modelo assume que o potencial de estabilidade financeira possui natureza multidimensional.

Dessa forma, o score composto será estruturado a partir de subíndices conceituais independentes, cada um representando dimensões específicas do comportamento socioeconômico observado.

## 6.1 Subíndice de Estabilidade Econômica

Objetivo:
avaliar previsibilidade ocupacional e estabilidade de geração de renda.

Variáveis associadas:

* tempo no trabalho atual;
* volatilidade relativa da renda;
* horas habitualmente trabalhadas.

Hipótese econômica:
maior estabilidade ocupacional e menor volatilidade tendem a indicar maior previsibilidade financeira mesmo em contextos de informalidade.

---

## 6.2 Subíndice de Capacidade Financeira

Objetivo:
estimar potencial de geração de renda e capacidade econômica estrutural.

Variáveis associadas:

* renda habitual;
* renda efetiva;
* escolaridade;
* grupamento de atividade econômica.

Hipótese econômica:
maior capital humano e maior capacidade recorrente de geração de renda tendem a indicar maior potencial de relacionamento financeiro sustentável.

Observação metodológica:
as variáveis monetárias utilizadas no modelo serão deflacionadas previamente para garantir comparabilidade temporal e evitar distorções inflacionárias nas análises estatísticas e nos indicadores derivados.

---

## 6.3 Subíndice de Vulnerabilidade Familiar

Objetivo:
identificar possíveis pressões estruturais sobre orçamento e capacidade financeira.

Variáveis associadas:

* média de moradores no domicílio;
* média de filhos;
* características domiciliares agregadas derivadas do Censo IBGE (etapas futuras).

Hipótese econômica:
maior pressão domiciliar pode reduzir capacidade de poupança, estabilidade financeira e margem de absorção de choques econômicos.

---

## 6.4 Subíndice de Maturidade Socioeconômica

Objetivo:
representar estágio de consolidação econômica e ocupacional do indivíduo.

Variáveis associadas:

* faixa etária;
* posição na ocupação;
* condição do domicílio.

Hipótese econômica:
indivíduos em estágios mais maduros de consolidação profissional e patrimonial tendem a apresentar maior estabilidade financeira potencial.

---

# 7. Pipeline Analítico

O fluxo metodológico do projeto será estruturado nas seguintes etapas:

1. Estruturação e consolidação dos microdados;
2. Limpeza e tratamento estatístico;
3. Construção das variáveis derivadas;
4. Deflacionamento das variáveis monetárias e harmonização temporal das rendas;
5. Integração territorial com bases do Censo IBGE;
6. Padronização estatística das métricas;
7. Construção dos subíndices socioeconômicos;
8. Consolidação do score composto;
9. Redução dimensional via PCA;
10. Clusterização dos perfis socioeconômicos;
11. Territorialização dos clusters;
12. Desenvolvimento dos dashboards analíticos.

A etapa de deflacionamento será realizada após a construção das variáveis derivadas e antes da padronização estatística, garantindo consistência temporal das métricas financeiras utilizadas no modelo.

---

# 8. Estratégia Estatística

O modelo utilizará técnicas de redução dimensional, especialmente Principal Component Analysis (PCA), com os seguintes objetivos:

* identificar redundâncias entre variáveis;
* reduzir multicolinearidade;
* validar a estrutura conceitual dos subíndices;
* calibrar pesos relativos do score composto;
* reduzir ruído estatístico;
* melhorar a eficiência das etapas de clusterização.

O PCA será utilizado como mecanismo complementar de validação estatística, preservando a interpretabilidade econômica das dimensões conceituais originalmente definidas.

Adicionalmente, o tratamento temporal das variáveis monetárias por meio de deflacionamento busca reduzir vieses inflacionários que poderiam comprometer a comparabilidade estatística entre períodos distintos da PNAD Contínua.

A incorporação futura de variáveis territoriais derivadas do Censo IBGE poderá ampliar a capacidade explicativa dos componentes espaciais e socioeconômicos do modelo.

---

# 9. Estratégia de Clusterização

Após a consolidação dos componentes socioeconômicos, serão aplicadas técnicas de clusterização não supervisionada para identificação de grupos populacionais com características semelhantes.

A clusterização tem como objetivos:

* identificar perfis latentes de estabilidade financeira;
* segmentar grupos thin file heterogêneos;
* identificar padrões socioeconômicos recorrentes;
* apoiar análises de inclusão financeira;
* permitir leituras territoriais agregadas.

Inicialmente será utilizada a técnica K-Means, podendo posteriormente ser avaliadas abordagens hierárquicas ou baseadas em densidade.

---

# 10. Estratégia Territorial

As análises territoriais buscarão identificar padrões regionais de concentração dos clusters socioeconômicos.

Em vez de granularidade municipal extrema, serão priorizados agrupamentos territoriais mais robustos estatisticamente e mais aderentes à proposta executiva do projeto, como:

* Regiões Metropolitanas (RMs);
* RIDEs;
* macrorregiões geográficas;
* recortes urbano/rural.

A territorialização terá caráter complementar à segmentação socioeconômica, buscando identificar possíveis bolsões regionais de baixa profundidade financeira e elevado potencial de inclusão bancária.

A estratégia territorial também prevê integração futura entre dados do ESTBAN e informações estruturais do Censo IBGE, permitindo análises de geointeligência voltadas à relação entre infraestrutura urbana, densidade populacional e profundidade financeira regional.

---

# 11. Limitações do Modelo

O modelo possui natureza exploratória e não pretende representar mecanismo formal de concessão de crédito.

As inferências realizadas baseiam-se exclusivamente em proxies socioeconômicas derivadas de dados públicos, não contemplando:

* histórico bancário individual;
* comportamento transacional;
* dados cadastrais privados;
* informações protegidas por sigilo financeiro;
* modelos proprietários de risco de crédito.

Os resultados devem ser interpretados como instrumento analítico de segmentação e inteligência socioeconômica.

---

# 12. Próximas Etapas

| Etapa                                               | Status    |
| --------------------------------------------------- | --------- |
| EDA aprofundada                                     | Próxima   |
| Deflacionamento e harmonização temporal             | Planejada |
| PCA                                                 | Planejada |
| Clusterização                                       | Planejada |
| Geointeligência: integração com ESTBAN e Censo IBGE | Planejada |
| Integração de indicadores do Banco Central          | Planejada |
| Dashboard Power BI                                  | Planejada |
| Storytelling executivo                              | Planejado |

---

# 13. Considerações Finais

O projeto busca combinar:

* inteligência socioeconômica;
* análise territorial;
* técnicas estatísticas;
* segmentação analítica;
* e dados públicos de larga escala,

com o objetivo de explorar potenciais lacunas de inclusão financeira no Brasil.

A proposta procura equilibrar:

* robustez metodológica;
* interpretabilidade executiva;
* viabilidade operacional;
* e aderência ao contexto do Sistema Financeiro Nacional.
