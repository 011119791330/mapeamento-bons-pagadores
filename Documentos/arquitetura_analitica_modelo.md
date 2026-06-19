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

**Reenquadramento de escopo (pré-Sessão 4):** embora o vocabulário histórico do projeto enfatize "crédito", o escopo conceitual é o **relacionamento financeiro em sentido amplo** — desde a porta de entrada (conta corrente, meio de pagamento, bancarização básica) até operações complexas (financiamento, capital de giro). A invisibilidade estrutural começa antes do crédito: na ausência de qualquer relação transacional com o SFN. O score socioeconômico é agnóstico ao produto financeiro de destino; o reenquadramento materializa-se na construção da profundidade financeira territorial como índice **multiproduto** (Sessão 5) e no storytelling executivo (Sessão 6), sem alterar base ou deflação.

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

**Atualização (Subseção 4-B):** após a reconstrução da view base, o escopo compreende **1.573 células-perfil** (≥ 30 respondentes cada). A contagem difere da v01 (~3.476) por duas decisões da Subseção B: abertura de `tempo_no_trabalho` para 7 faixas (maior resolução, menos células) e reagrupamento de `posicao_no_domicilio` para 4 grupos (recupera massa). Ver changelog B.3 e B.4.

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

`VD4009` auditado contra o dicionário oficial da basedosdados na Subseção 4-B: os 5 códigos do escopo correspondem a "Empregado do setor privado sem carteira" (2), "Trabalhador doméstico sem carteira" (4), "Empregado público sem carteira" (6), "Conta-própria" (9) e "Trabalhador familiar auxiliar" (10). Rótulo canônico "Conta-própria"; "Autônomos" é sinônimo informal de narrativa. Empregador (cód 8) fica corretamente fora do escopo (é capital, não trabalho precarizado).

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

**Atualização (Subseção 4-B):** `cv_renda_efetiva` e `std_renda_efetiva` passam a ser calculados com **variância ponderada** por `V1028` (peso de pós-estratificação), coerente com as médias ponderadas. Fórmula: variância amostral ponderada com correção de Bessel generalizada, calculada por agregação numa única passada. É uma aproximação de peso de frequência (não estimativa de variância sob desenho amostral complexo), adotada por proporcionalidade. Ponderar o desvio era necessário porque o CV é razão `desvio/média`: com a média já ponderada (decisão da auditoria), deixar o desvio não-ponderado produziria um CV sem interpretação limpa. A invariância do CV à deflação (Sessão 3) sobrevive à ponderação. Ver changelog B.2.

Distinção conceitual registrada (pré-Sessão 4): este subíndice mede **volatilidade observada** (dispersão num retrato, via CV) e **gap conjuntural** (via desvio relativo), mas não mede **risco sistemático** — exposição a choques externos correlacionados (macro, setorial, climático) que atingem uma classe inteira simultaneamente. Duas células com mesmo CV podem ter exposição externa distinta (autônomo agrícola vs. autônomo de comércio urbano). O risco sistemático não é incorporado como variável de score nesta etapa (série de 5 anos insuficiente para estimá-lo de forma defensável; princípio de proporcionalidade), mas (a) já se manifesta indiretamente via `grupamento_atividade` como dimensão padrão — a agricultura puxando o CV é sua assinatura nos dados; (b) será usado como **lente interpretativa** dos clusters; (c) fica registrado como evolução futura possível, mediante integração de fonte externa de volatilidade setorial.

## 7.2 Subíndice de Capacidade Financeira

Objetivo: estimar potencial de geração de renda e capacidade econômica estrutural.

Variáveis associadas:

* `renda_media_habitual`;
* `renda_media_efetiva`;
* `escolaridade`;
* `grupamento_atividade` (dimensão padrão a partir da Sessão 2).

Hipótese econômica: maior capital humano e maior capacidade recorrente de geração de renda tendem a indicar maior potencial de relacionamento financeiro sustentável.

Observação metodológica: as variáveis monetárias serão deflacionadas previamente (Sessão 3) para garantir comparabilidade temporal e evitar distorções inflacionárias, e usadas em sua forma **ponderada e real** (`renda_*_real`) como input do subíndice.

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

**Atualização (Subseção 4-B):** `posicao_no_domicilio` reagrupada de 19 categorias oficiais para **4 grupos** conceituais, ao longo de um eixo de maturidade/autonomia no domicílio:

1. Responsável ou cônjuge (~74,8%) — núcleo do domicílio;
2. Filho(a) ou enteado(a) (~18,2%) — geração descendente direta;
3. Outro parente (~6,4%) — parentela estendida;
4. Não-parente ou demais (~0,6%) — cauda colapsada.

O reagrupamento combina afinidade conceitual com o colapso da cauda longa (11 categorias com menos de 1% de participação), recuperando massa analítica sem descartar nenhum respondente. Cônjuges do mesmo sexo (código 3) foram mantidos no grupo dos cônjuges, e não relegados à cauda por baixa frequência — decisão de coerência conceitual e de integridade de representação de uma realidade que a PNAD nem sempre captura bem. Ver changelog B.4.

---

# 8. Dimensão Transversal — Grupamento de Atividade

A partir da Sessão 2, `grupamento_atividade` foi promovido a **dimensão analítica padrão**, ao lado de `posicao_ocupacao`. A decisão decorre de achado empírico: a agricultura (que atravessa todas as categorias ocupacionais e representa 77–84% de Autônomos) é o principal puxador de heterogeneidade intra-célula no escopo do projeto.

Tratar `grupamento_atividade` como dimensão padrão:

* Diferencia realidades econômicas dentro da mesma categoria ocupacional;
* Mantém tratamento simétrico entre os 5 segmentos do escopo;
* Evita criar segmentos artificiais (como subdivisões por renda, que seriam circulares);
* Preserva interpretabilidade da clusterização.

---

# 9. Eixos Territoriais da View Base

A view base carrega **dois eixos territoriais independentes e transversais** (distinção confirmada na auditoria 4-A), mais uma chave de junção crua:

* `tipo_area` (de `V1023`): Capital / Resto da RM / Resto da RIDE / Resto da UF;
* `situacao_domicilio` (de `V1022`): Urbana / Rural — **transversal** ao tipo de área (existe rural dentro de capital, RM e RIDE, não apenas no interior; ~636 mil respondentes rurais antes invisíveis sob rótulo errado na v01);
* `rm_ride` (código cru): chave de junção territorial, mantida **sem decodificação** na base.

Princípio estabelecido: **chaves de junção ficam cruas; dimensões terminais de leitura são decodificadas na view.** A decodificação de `rm_ride` (20 RMs + 1 RIDE, confirmadas contra o programa SAS oficial do IBGE) é tarefa da Sessão 5, via JOIN com dicionário oficial — coerente com o princípio de auditar contra a fonte, não contra a memória. `rm_ride` tem NULL legítimo dominante: a maioria do público-alvo (informal, agrícola) está fora de RM/RIDE, reforçando a tese do projeto.

---

# 10. Pipeline Analítico

Fluxo metodológico do projeto:

1. Estruturação e consolidação dos microdados (Sessão 1)
2. Limpeza e tratamento estatístico (Sessão 1)
3. Construção das variáveis derivadas (Sessão 1)
4. Análise exploratória (Sessão 2)
5. Deflacionamento das variáveis monetárias e harmonização temporal (Sessão 3)
6. Auditoria e reconstrução da view base — ponderação por peso amostral, correção de mapeamentos, reagrupamentos (Sessão 4-A e 4-B)
7. Padronização estatística — z-score com truncamento (Sessão 4-C)
8. Construção dos subíndices socioeconômicos (Sessão 4-C)
9. Consolidação do score composto (Sessão 4-C)
10. Redução dimensional via PCA (Sessão 4-C)
11. Clusterização dos perfis socioeconômicos (Sessão 4-C)
12. Integração territorial com Censo IBGE e ESTBAN (Sessão 5)
13. Territorialização dos clusters (Sessão 5)
14. Desenvolvimento dos dashboards e storytelling executivo (Sessão 6)

---

# 11. Estratégia Estatística

O modelo utilizará técnicas de redução dimensional, especialmente Principal Component Analysis (PCA), com os seguintes objetivos:

* identificar redundâncias entre variáveis;
* reduzir multicolinearidade;
* validar a estrutura conceitual dos subíndices;
* calibrar pesos relativos do score composto;
* reduzir ruído estatístico;
* melhorar a eficiência das etapas de clusterização.

O PCA será utilizado como mecanismo complementar de validação estatística, **preservando a interpretabilidade econômica das dimensões conceituais originalmente definidas**.

**Princípio de proporcionalidade adotado:** a sofisticação metodológica deve ser proporcional ao objetivo do projeto (mapeamento de perfis e regiões, não scoring individual) e ao público do entregável final (gerentes de áreas não-técnicas). Decisões metodológicas privilegiam explicabilidade sobre rigor estatístico marginal sempre que o ganho de informação não justifica o custo de comunicação.

**Pesos do score (decisão pré-Sessão 4):** adotado o modelo **híbrido** como hipótese de trabalho — predominância dos pesos conceituais, PCA como mecanismo de ajuste na margem — em vez de pesos iguais (baseline de comparação) ou pesos integralmente derivados do PCA. Coerente com o princípio de proporcionalidade.

**Gate de validação — score vs. proxy de renda (decisão pré-Sessão 4):** após consolidar o score composto, calcular a correlação de Pearson entre score e `renda_media_efetiva_real`. Correlação acima de ~0,8 sinaliza que o score degenerou em termômetro de renda (posição socioeconômica), não estabilidade — exigindo reponderação para baixo do subíndice de Capacidade Financeira. Diagnóstico obrigatório de honestidade analítica.

**Balanceamento diagnóstico do PCA — "balanceamento virtual comparativo" (decisão pré-Sessão 4):** dado que autônomos são ~67% do escopo, os primeiros componentes principais podem refletir prioritariamente a variação interna dos autônomos (dominância estrutural), deixando os perfis menores projetados numa régua que não é a deles. Para diagnosticar — **sem alterar a base de produção** — o PCA é executado em dois cenários: (1) base real (proporções intactas; é a régua que segue no pipeline) e (2) cópia temporária e descartável balanceada por `posicao_ocupacao` (N igual por categoria, amostragem sem reposição). Comparam-se os *loadings* dos dois cenários: semelhantes → estrutura robusta/universal; muito diferentes → dominância confirmada (achado analítico, não defeito; pode motivar clusterização por estrato). Explicitamente **não** se adota oversampling, undersampling definitivo, SMOTE ou geração sintética — o balanceamento é exclusivamente diagnóstico. Ressalva: se a menor categoria tiver poucas células, considerar balancear até a segunda menor ou usar PCA estratificado, para evitar confundir dominância com efeito de tamanho amostral.

**Regime de CV pós-reconstrução (Subseção 4-B):** sob a base ponderada e com partição mais fina, a mediana do CV intra-célula subiu para ~1,07 (era ~0,6 na v01), com máximo ~17,9 e zero CV nulos. O tratamento de outliers de CV previsto antes da padronização z-score (P4.8) ganha relevância: células pequenas sob ponderação podem inflar o CV quando poucos respondentes de peso alto dominam. Winsorização ou flag de baixa confiabilidade a definir na Subseção C.

---

# 12. Estratégia de Clusterização

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

**Dimensionamento dos clusters (decisão pré-Sessão 4, destravada na 4-B):** após clusterizar, estimar a população potencial por cluster — a ponte entre o resultado analítico e a leitura executiva (tamanho de mercado, escala de iniciativas de inclusão). A coluna `populacao_expandida` (`SUM(V1028)`) foi adicionada à view base na Subseção 4-B, destravando esse dimensionamento. Distinção operacional a observar: **`populacao_expandida`** (peso) responde "quantas pessoas o cluster representa" (tamanho de mercado); **`total_entrevistados`** (contagem bruta) responde "quão confiável é a estimativa" (robustez amostral). O piso de robustez (`HAVING COUNT(*) >= 30`) é sempre sobre a contagem bruta, nunca sobre população expandida.

---

# 13. Estratégia Territorial

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

Todas as fontes usam código IBGE de município como chave primária. Integração será feita por agregação ascendente. O código `rm_ride` (cru na base) é a chave estabelecida para essa integração.

---

# 14. Limitações do Modelo

O modelo possui natureza exploratória e não pretende representar mecanismo formal de concessão de crédito.

As inferências baseiam-se exclusivamente em proxies socioeconômicas derivadas de dados públicos, não contemplando:

* histórico bancário individual;
* comportamento transacional;
* dados cadastrais privados;
* informações protegidas por sigilo financeiro;
* modelos proprietários de risco de crédito.

Os resultados devem ser interpretados como instrumento analítico de segmentação e inteligência socioeconômica, não como mecanismo de scoring.

Limitações metodológicas adicionais registradas na reconstrução (Subseção 4-B):

* Médias e dispersão são ponderadas pelo peso de pós-estratificação da PNAD (`V1028`). A variância ponderada usa aproximação de peso de frequência, não estimativa sob desenho amostral complexo — escolha de proporcionalidade, documentada.
* A ponderação tem efeito pequeno e estável nas categorias grandes (Conta-própria, ~12% de desvio vs. média simples), mas instável nas categorias pequenas (familiar auxiliar oscila entre 0% e 50% conforme o ano) — efeito de cauda amostral, a tratar na construção do score.
* Granularidade territorial limitada pela PNAD a UF + RM/RIDE + recorte urbano/rural; `rm_ride` mantido cru e decodificado apenas na Sessão 5.

---

# 15. Próximas Etapas

| Etapa | Status |
| ----- | ------ |
| EDA aprofundada | ✅ Concluída (Sessão 2) |
| Deflacionamento e harmonização temporal | ✅ Concluída (Sessão 3) |
| Auditoria da view base | ✅ Concluída (Sessão 4-A) |
| Reconstrução da view base + view-filha | ✅ Concluída (Sessão 4-B) |
| Padronização e construção dos subíndices | 🔜 Próxima (Sessão 4-C) |
| Consolidação do score composto | Planejada (Sessão 4-C) |
| PCA + balanceamento diagnóstico | Planejada (Sessão 4-C) |
| Clusterização | Planejada (Sessão 4-C) |
| Integração com ESTBAN e Censo IBGE | Planejada (Sessão 5) |
| Territorialização dos clusters | Planejada (Sessão 5) |
| Dashboard Power BI | Planejada (Sessão 6) |
| Storytelling executivo | Planejado (Sessão 6) |

---

# 16. Considerações Finais

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

*Documento de arquitetura — atualizado na Subseção 4-B (reconstrução da view base: ponderação por peso amostral, correção de mapeamentos, reagrupamento de posição no domicílio, eixos territoriais).*
*Reflete decisões metodológicas consolidadas; o histórico das discussões críticas está registrado no changelog do projeto (changelog_integrado.md).*
