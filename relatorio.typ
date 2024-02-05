// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => article(
  title: [Plano de Trabalho],
  authors: (
    ( name: [Frederico Guth],
      affiliation: [BID],
      email: [frederico.guth\@saude.gov.br] ),
    ( name: [Gabriel Squeff],
      affiliation: [CGES/DESID/MS],
      email: [gabriel.squeff\@saude.gov.br] ),
    ),
  date: [2024-02-01],
  lang: "pt",
  region: "BR",
  paper: "a4",
  sectionnumbering: "1.1.a",
  toc: true,
  toc_title: [Índice],
  toc_depth: 3,
  cols: 1,
  doc,
)


= Introdução
<sec-intro>
O presente projeto é uma iniciativa de 12 meses no âmbito da #emph[Cooperação Técnica BR-T1550] do Ministério da Saúde com o Banco Inter-americano de Desenvolvimento \(BID). Seu objetivo maior é fortalecer a capacidade de análise de dados do Departamento de Economia da Saúde, Investimento e Desempenho \(DESID/MS), integrando técnicas avançadas de ciência de dados e preparando a organização para a adoção de modelos de inteligência artificial.

== Motivação
<motivação>
#figure([
#box(width: 80%,image("images/pratos.svg"))
], caption: figure.caption(
position: bottom, 
[
Sistemas são meios e não fins.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pratos>


A Coordenação-Geral de Informações em Economia da Saúde \(CGES/DESID) é uma área multidiprofissional e interdisciplinar responsável por importantes sistemas de registro de informações econômicas de saúde \(SIOPS, BPS e ApuraSUS) e pelo uso desses dados para fornecer evidências econômicas para formulação de políticas, diretrizes e metas para a contínua melhoria do Sistema Único de Saúde \(SUS).

#quote(block: true)[
Os sistemas não são fins em si mesmos. Mais Economia!

— Gabriel Squeff
]

Desde o início de 2023, a CGES tem investido em melhorias para automatizar e reduzir esforços na obtenção dos registros e aumentar a produção de evidências econômicas baseadas na análise de dados. Tais evidências são a missão principal da DESID e subsidiam a formulação de políticas, diretrizes e metas para que as ações e serviços de saúde sejam prestados de forma eficiente, equitativa e com qualidade para melhor acesso da população, atendendo aos princípios da universalidade, igualdade e integralidade da atenção à saúde estabelecidos constitucionalmente para o Sistema Único de Saúde \(SUS).

A coordenação identificou a necessidade urgente e prioritária de fortalecer suas capacidades de análise de dados, uma vez que conta atualmente com reduzida equipe especializada na área, a maior parte das análises ainda é realizada apenas em planilhas e os processos de ingestão e transformação de dados são #emph[ad-hoc] e não institucionalizados.

Essa necessidade se torna ainda mais crítica com a responsabilidade assumida pela CGES na produção futura do Sistema de Contas de Saúde \(SHA), em cooperação com a a Organização para a Cooperação e Desenvolvimento Econômico \(OCDE) e outras instituições governamentais brasileiras.

- criação do Núcleo de Engenharia de Dados \(NErD)

== Objetivos do Projeto
<objetivos-do-projeto>
- Melhorar a qualidade e facilitar os processos de análise de dados da CGES;
- Reduzir a dependência externa da CGES para a realização de suas funções;
- Apoiar a produção do SHA de acordo com a metodologia da OCDE.
- Melhorar os processos de desenvolvimento de produtos de dados.

== Escopo do Projeto
<escopo-do-projeto>
- Análise dos desafios, processos e capacidade técnica atual e desenvolvimento de uma estratégia de utilização de técnicas de Ciência de - Dados e Aprendizado de Máquinas para melhoria dos processos da CGES.
- Desenvolvimento de plano de infraestrutura técnica e capacitação da equipe.
- Desenvolvimento de metodologia de desenvolvimento de produtos de dados.
- Desenvolvimento de proposta de portfólio de produtos de dados.
- Desenvolvimento de produtos de dados: esteiras de dados, relatórios, indicadores, datasets etc.

== Este documento
<este-documento>
#figure(
align(center)[#table(
  columns: 2,
  align: (col, row) => (center,left,).at(col),
  inset: 6pt,
  [#strong[Contrato];],
  [Cooperação Técnica BR-T1550],
  [#strong[Projeto];],
  [Consultoria Individual de Ciência de Dados e Aprendizado de Máquina no Departamento de Economia da Saúde, Investimento e Desempenho do Ministério da Saúde],
  [#strong[Produto];],
  [Entregável 1 - Plano de Trabalho],
)]
)

= Objetivos
<objetivos>
O presente #emph[Plano de Trabalho] tem como objetivos:

- Contextualizar o Projeto \(#link(<sec-intro>)[1 Introdução];)
- Apresentar e justificar a abordagem sociotécnica que será adotada \(#link(<sec-metodo>)[3 Método];)
- Descrever os entregáveis e o cronograma de entregas \(#link(<sec-result>)[4 Resultados];)
- Estabelecer expectativas e critérios de sucesso do Projeto \(#link(<sec-conclusao>)[5 Conclusão];)

= Método
<sec-metodo>
== Contexto
<contexto>
- #strong[Reconhecimento do Valor de Decisões Baseadas em Evidências:]
  - Organizações globalmente investem em decisões fundamentadas em dados.
  - Investimento em ferramentas analíticas superou 80 bilhões de dólares em 2023.
- #strong[Desafio em Tornar-se Verdadeiramente Orientado por Dados:]
  - Muitas organizações estão avançando para a terceira geração de plataformas de dados.
  - Poucas alcançaram o estágio de serem orientadas por dados.
- #strong[Falhas nas Iniciativas de Plataformas de Dados:]
  - Falhas atribuídas à não aplicação de aprendizados em arquiteturas distribuídas.
  - Proposta de uma nova arquitetura empresarial de dados: a malha de dados.
- #strong[Saturação do Mercado com Ferramentas Analíticas:]
  - Mercado inundado com diversas ferramentas, prometendo ser a solução definitiva.
  - Situação de confusão e frustração devido à "explosão cambriana" de ferramentas.
- #strong[Evolução das Plataformas de Dados:]
  - De Datawarehouses e BI para Big Data e Data Lakes, e finalmente para Plataformas em Nuvem.
  - Desafios persistem em escalabilidade, qualidade e documentação dos dados.
- #strong[Natureza Holística do Problema:]
  - Necessidade de abordagem que englobe missão, capacidade, governança.
  - Importância da integração de produtos, pessoas, tecnologia e processos.
  - Exige mudança cultural para valorizar orientação por dados.

Optei por usar a abordagem de princípios fundamentais para enfrentar nossa questão. Esta estratégia nos permite desmontar o problema até o básico e então reconstruí-lo, evitando soluções prontas e pensamento padrão. Ao questionar as suposições comuns e focar no essencial, temos a chance de encontrar soluções inovadoras e eficientes que poderiam ser ignoradas de outra forma. A força dessa abordagem está na sua capacidade de nos levar a ideias revolucionárias e avanços significativos na solução de problemas complexos.

Organizações de todos os tamanhos em todo mundo reconhecem o valor de decisões baseadas em evidências. Estima-se que em 2023, o investimento global em ferramentas analíticas superou 80 bilhões de dólares.

According to IDC, the markets for Analytics Data Management and Integration Platforms and Business Intelligence and Analytics Tools, which we believe we address, will have a combined value of \$56 billion by the end of 2020 and \$84 billion by the end of 2023.

Muitas organizações já estão na terceira geração de suas #emph[plataformas de dados];, com a esperança de

Poucas, porém, podem se dizer verdadeiramente #emph[data-driven];.

However what I would like to share with you is an architectural perspective that underpins the failure of many data platform initiatives. I demonstrate how we can adapt and apply the learnings of the past decade in building distributed architectures at scale, to the domain of data; and I will introduce a new enterprise data architecture that I call data mesh.

Apesar disso, o investimento em tecnologia para análise de dados continua crescendo e o mercado está inundado de diferentes ferramentas e plataformas. Cada uma prometendo ser melhor, mais completa e mais fácil de usar que a outra. Mas, na prática, o que vemos é um cenário de confusão e frustração com o que chamam de "explosão cambriana" de ferramentas analíticas.

#figure([
#box(width: 1600.0pt, image("images/landscape.jpeg"))
], caption: figure.caption(
position: bottom, 
[
A "explosão cambriana" do mercado de ferramentas analíticas.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- fabricas de software e escritórios de análise
- mudanças tecnológicas -\> inversão da lógica
- insucesso
- perdido
- devops - dataops - engenharia - processos
- vivendo o passado
- modern data stack

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Datawarehouses e BI \(primeira geração):] consolidando dados de diversas fontes, essa estratégia foca na limpeza e verificação dos dados antes de torná-los disponíveis. Essa centralização enfrenta desafios de escalabilidade à medida que as fontes de dados aumentam. Principais artefatos são relatórios e painéis \(#emph[dashboards];). Tabelas e relatórios complicados entendidos por poucos especialistas, impacto limitado nos negócios.

#strong[Big Data e Data Lakes \(segunda geração):] Como resposta aos gargalos da geração anterior e aproveitando a redução de custos de #emph[hardware];, #emph[Data Lakes] armazenam dados em arquivos, com transformações ocorrendo no momento do consumo. Embora ofereça flexibilidade, esta abordagem apresenta desafios quanto à qualidade e documentação dos dados.

#strong[Plataformas em Nuvem \(terceira geração):] semelhante à geração anterior, mas modernizada com: #emph[\(];a#emph[)] dados em tempo real \(#emph[streams];)#emph[,] #emph[\(];b#emph[)] processamento unificado de dados em #emph[batch] e #emph[stream] e #emph[\(c)] uso intensivo da nuvem. Embora aborde falhas anteriores, ainda carrega problemas das gerações passadas.

])

== Definição do Problema
<definição-do-problema>
- não é problema puramente tecnológico
- first principles
- missão, capacidade, governança
- produtos, pessoas e tecnologia, processos

=== Servir como lição: Evolução contínua
<servir-como-lição-evolução-contínua>
#figure([
#box(width: 90%,image("images/servico.svg"))
], caption: figure.caption(
position: bottom, 
[
Serviço como fluxo de valor e feedback; um ciclo.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-servico>


Todo serviço deve transformar seu #emph[usuário] para melhor #footnote[#emph[Usuário] Pessoa ou organização que se beneficia de um serviço. Também chamado de #emph[cliente];.];; um #emph[fluxo de valor] \(@fig-servico) que pode envolver diversas etapas e atendimentos.

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Dados transacionais:] dados primários que sustentam o funcionamento dos serviços diretos ao usuário e mantêm seu estado atual. Também conhecidos como #emph[dados operacionais];.

#strong[Dados analíticos:] dados derivados das bases transacionais \(secundários), fornecem visão agregada e histórica dos serviços.

])

O SUS atua diariamente para melhorar a saúde dos brasileiros, milhares de vezes por dia. A importância de #emph[servir] \(atender) está fortemente imbuída na cultura do ministério.

Cada #emph[transação] #footnote[Uma transação é uma execução do serviço, um atendimento.] deixa um rastro de dados. A imensa quantidade de dados gerados pelo SUS é visto por alguns como um ativo: essa é uma visão equivocada. Dados só tem valor quando usados.

O #emph[feedback] do usuário, direto e indireto \(via indicadores), fornece informações cruciais para aprimorar o serviço: um fluxo de valor no sentido contrário, do usuário para o serviço.

O propósito do SUS vai além de atender o usuário no momento presente, mas também envolve a #emph[evolução contínua] do serviço @fig-evolucao, baseada em evidências. Quanto mais rápido o ciclo de #emph[servir];, #emph[analizar] e #emph[aprender];, mais hipóteses podem ser testadas e mais rápido o serviço evolui.

#figure([
#box(width: 50%,image("images/evolucao.svg"))
], caption: figure.caption(
position: bottom, 
[
Evolução contínua.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-evolucao>


- Evolução Contínua
- Maestria
- Pessoas e Processos

=== Servir como prisão: Evolução perdida
<servir-como-prisão-evolução-perdida>
"Nos primeiros quatro meses de 2023, mais de 10,3 mil servidores \[1/3 do quadro\] da Secretaria de Saúde do Distrito Federal \(SES-DF) precisaram de atestados de afastamento do trabalho. Grande parte desses servidores são técnicos em enfermagem"\_ #cite(<Schwingel2023>);. Organizações doentes adoecem pessoas. No serviço público, são servidoras #emph[da ponta] \(enfermeiras, médicas, professoras) as que mais adoecem. O que está acontecendo?

#figure([
#box(width: 90%,image("images/grinder.png"))
], caption: figure.caption(
position: bottom, 
[
O "sistema" moendo pessoas. Arte de #emph[Gerald Scarfe] para o filme #emph[The Wall] \(1982).
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-grinder>


Organizações públicas e privadas ainda são majoritariamente estruturadas em silos funcionais @fig-paredes, com equipes especializadas em áreas como negócio, tecnologia, jurídico, controle; herança da burocracia de Weber e da #emph[gestão científica] de Taylor do início do século XX.

Esta estrutura exige que cada seviço seja coordenado entre equipes distintas, com diferentes hierarquias, prioridades e linguagens. Como na gincana em que se amarra o pé de uma criança no da outra: sem sincronia, caem as duas e se andam, é no ritmo da mais lenta.

Os servidores #emph[da ponta] atendem os #emph[usuários reais] \(ex. a mãe precisando de atendimento para o filho), enfrentam a realidade; os servidores #emph[meio] atendem os servidores mais à ponta, #emph[usuários internos];.

Estar na ponta traz clareza da importância da sua contribuição individual,#emph[senso de ];propósito\* \(@fig-danpink). Ao mesmo tempo, exarceba a sensação de #emph[impotência] diante de uma realidade que não se consegue mudar e que parece que os outros \(áreas meio) não enxergam. No setor público, há ainda o #emph["requinte de crueldade"] dos órgão de controle responsabilizarem pessoalmente o gestor #emph[da ponta] por um serviço que este não controla inteiramente.

#figure([
#box(width: 90%,image("images/paredes3.svg"))
], caption: figure.caption(
position: bottom, 
[
Muros organizacionais.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-paredes>


#quote(block: true)[
O servidor na ponta está preso entre a realidade e o muro organizacional. - Governança - Organização e Tecnologia
]

=== Servir como missão: Evolução orientada
<servir-como-missão-evolução-orientada>
A gestão orientada a evidências estabelece apenas o método da resposta, mas não o que perguntar, para onde evoluir. Para isso é primordial definir escolhas estratégicas, decisões políticas.

O conceito de "#emph[missões];" em políticas públicas tem sido popularizado pela economista Mariana Mazzucato #cite(<Mazzucato2022>);. Ela destaca a importância de definir objetivos claros, ambiciosos e mensuráveis para orientar a inovação \(metas #emph[moonshot];).

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Moonshot:] Meta ambiciosa, que requer inovação radical para ser atingida. Remete ao projeto Apollo que ambicionou levar humanos à Lua. Difere-se da missão-maior de servir por ser uma missão-meta, com prazo e escopo definidos.

#emph[Ex.] Meta "Três Bilhões" da OMS: #cite(<gpw13>) - 1 bilhão de pessoas a mais com cobertura universal de saúde. - 1 bilhão de pessoas a mais protegidas de emergências de saúde. - 1 bilhão de pessoas a mais gozando de melhor saúde e bem-estar.

])

A ambição de uma meta #emph[moonshot] envolve essencialmente risco. Elas definem concretamente "#emph[onde];" se quer chegar, mas não "#emph[como];". Para o "#emph[como];" existem "apostas", caminhos-hipótese que se pode testar. Algumas hipóteses vão falhar, mas o aprendizado é parte do processo.

#figure([
#box(width: 90%,image("images/danpink3.svg"))
], caption: figure.caption(
position: bottom, 
[
Auto-motivação segundo Dan Pink. #footnote[Figura inspirada em #emph[sketchplanations];]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-danpink>


#figure([
#box(width: 90%,image("images/missao.svg"))
], caption: figure.caption(
position: bottom, 
[
Arcabouço de Mazzucato.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-mazzucato>


Se a missão é a #emph[função objetivo];, os recursos são apenas variáveis, pois são #emph[virtualmente infinitos];, dependem apenas de #emph[vontade política] \(alocação). As restrições são organizacionais. Em outras palavras, uma meta pode não ser atingida mesmo com recursos ilimitados.

== Síntese
<síntese>
Uma grande contribuição do arcabouço de missões apresentado por Mazzucato é lembrar no debate econômico que a mudança é feita por pessoas. E que as pessoas são motivadas por propósitos \(@fig-danpink). Ao longo dos anos, as lições da teoria sociotécnia foram descobertas, esquecidas e redescobertas várias vezes com diferentes nomes.

#figure([
#box(width: 90%,image("images/alinha_autonomia.svg"))
], caption: figure.caption(
position: bottom, 
[
Governança: Alinhamento e Autonomia.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-governanca>


- problema socio técnica

== Abordagem
<abordagem>
#block(
fill:purple.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Das Minas de Yorkshire ao Spotify
]
)
]
No final dos anos 1940, o carvão era a principal fonte de energia da Inglaterra. Para apoiar a reconstrução industrial pós-guerra, era essencial aumentar a sua produção e reduzir custos. Com esse intuito, introduziram-se novas máquinas nas minas de Yorkshire. A produtividade, contudo, diminuiu.

Chamados para investigar o problema, pesquisadores do Instituto Tavistock descobriram que as novas máquinas alteraram a dinâmica e cooperação entre os mineiros, que antes trabalhavam em equipes multifuncionais e autônomas com foco na resolução de problemas e alto grau de adaptabilidade.

Dessa observação nasceu a teoria sociotécnica, que enfatiza a importância de equilibrar tecnologia e relações humanas. Essa lição foi ora esquecida, ora redescoberta em diferentes contextos:

- No esforço de guerra americano que dobrou o PIB em 4 anos;
- Na reconstrução do devastado Japão com o que se tornou conhecido como sistema Toyota de produção;
- No movimento de Lean Startups e DevOps do Vale do Silício que culminaram no que hoje é referido como modelo Spotify.

])

Data Mesh #footnote[Data Mesh é um termo cunhado por Zhamak Dehghani. \(referencia?) \#\#\#\# Dados como Produtos - datasets, esteiras, relatórios, - FAIR – Findable: Discoverable, Addressable – Acessible: Natively Accessible, System Agnostic, Format Agnostic – Interoperable – Reusable: Value on its own, Trustworthy - data as code - contratos, data contracts] é uma abordagem para escalar e organizar a arquitetura e plataformas de dados baseada nos princípios do #emph[Domain Driven Design];, automação de precessos e #emph[Design Thinking];.

=== Domínios
<domínios>
- Orçamentos, Preços, Custos

=== Governança Compartilhada
<governança-compartilhada>
- INDA - Infra-estrutura Nacional de Dados Abertos

=== Infra-estrutura de auto-serviço
<infra-estrutura-de-auto-serviço>
- open source
- DESID Playground
- ingest, transform, serve
- Databricks, Snowflake, Redshift, Microsoft Fabric

== Critérios de Sucesso
<critérios-de-sucesso>
=== Nível de Maturidade
<nível-de-maturidade>
- Institucionalização Nível 1: Ad-Hoc Nível 2: Repetível Nível 3: Contínuo Nível 4: Previsível Nível 5: Em otimização

== Gestão de Projeto
<gestão-de-projeto>
- Scrum based
- espiral
- sprints
- retrospective
- no daily

== Riscos e Mitigações
<riscos-e-mitigações>
- falta ferramentas básicas de colaboração e gestão
- datasus

= Resultados
<sec-result>
== Entregáveis
<entregáveis>
#figure(
align(center)[#table(
  columns: 4,
  align: (col, row) => (left,left,left,center,).at(col),
  inset: 6pt,
  [Entrega], [Data], [Produto], [% Projeto],
  [1],
  [02-Fev-2024],
  [#strike[Plano de Trabalho];],
  [10%],
  [2],
  [04-Mar-2024],
  [Mapeamento de sistemas e processos de geração de dados],
  [20%],
  [3],
  [01-Abr-2024],
  [Descrição da Infraestrutura de Desenvolvimento de Produtos de Dados],
  [20%],
  [4],
  [01-Jul-2024],
  [Mapeamento de potenciais produtos de dados],
  [20%],
  [5],
  [06-Dez-2024],
  [Apresentação de Produtos de Dados],
  [30%],
)]
)

=== Mapeamento de sistemas e processos de geração de dados
<mapeamento-de-sistemas-e-processos-de-geração-de-dados>
- Auto-avaliação do nível de maturidade
- Mapeamento produtos de dados atuais
- Mapeamento do gap de capacidades

=== Descrição da Infraestrutura de Desenvolvimento de Produtos de Dados
<descrição-da-infraestrutura-de-desenvolvimento-de-produtos-de-dados>
- Especificação DESID Playground
- Documentação de processos de desenvolvimento de produtos
- Proposta de plano de capacitação

=== Mapeamento de potenciais produtos de dados
<mapeamento-de-potenciais-produtos-de-dados>
- Proposta de catálogo de produtos

=== Apresentação de Produtos de Dados
<apresentação-de-produtos-de-dados>
- 1 ou mais produtos do domínio Orçamentos \(SIOPS)
- 1 ou mais produtos do domínio Preços \(BPS)
- 1 ou mais produtos do domínio Custos \(ApuraSUS)
- 1 ou mais produtos do domínio Contas de Saúde \(SHA)

== Cronograma
<cronograma>
#block[
#block[
#block[
#block[

#block[
#box(width: 8.17in, image("relatorio_files/figure-typst/mermaid-figure-1.png"))

]

]
]
]
]
= Conclusão
<sec-conclusao>
nível de maturidade 2

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Referências
]
)
]
#block[
] <refs>



#bibliography("references.bib")

