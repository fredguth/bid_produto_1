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
O Projeto #strong[Consultoria Individual de Ciência de Dados e Aprendizado de Máquina no Departamento de Economia da Saúde, Investimento e Desempenho do Ministério da Saúde] \(DESID/MS), é uma iniciativa de 12 meses no âmbito da #emph[Cooperação Técnica BR-T1550] com o Banco Inter-americano de Desenvolvimento \(BID). Seu objetivo maior é fortalecer a capacidade de análise de dados da DESID, integrando técnicas avançadas de ciência de dados e preparando a organização para a adoção de modelos de inteligência artificial.

== Motivação
<motivação>
A Coordenação-Geral de Informações em Economia da Saúde \(CGES/DESID) é uma área multidiprofissional e interdisciplinar responsável por importantes sistemas de registro de informações econômicas de saúde \(SIOPS, BPS e ApuraSUS) e pelo uso desses dados para fornecer evidências econômicas para formulação de políticas, diretrizes e metas para a contínua melhoria do Sistema Único de Saúde \(SUS).

A coordenação conta atualmente com reduzida equipe especializada em dados, a maior parte das análises é realizada em planilhas e os processos de ingestão e transformação de dados são #emph[ad-hoc];.

Essa necessidade se torna ainda mais crítica com a responsabilidade assumida pela CGES na produção futura do Sistema de Contas de Saúde \(SHA), em cooperação com a a Organização para a Cooperação e Desenvolvimento Econômico \(OCDE).

A coordenação tem desprendido grande esforço em reduzir o esforço na simples obtenção dos registros, e aumentar o fornecimento de evidências econômicas baseadas na análise de dados. Tais evidências econômicas são a missão principal da DESID e subsidiam o a formulação de políticas, diretrizes e metas para que as ações e serviços de saúde sejam prestados de forma eficiente, equitativa e com qualidade para melhor acesso da população, atendendo aos princípios da universalidade, igualdade e integralidade da atenção à saúde estabelecidos constitucionalmente para o Sistema Único de Saúde \(SUS).

== Objetivos do Projeto
<objetivos-do-projeto>
- Melhorar a qualidade e facilitar os processos de análise de dados da CGES;
- Reduzir a dependência externa da CGES para a realização de suas funções;
- Apoiar a produção do SHA de acordo com a metodologia da OCDE.
- Criar e melhorar processos de desenvolvimento de produtos de dados.

== Escopo do Projeto
<escopo-do-projeto>
- Análise dos desafios, processos e capacidade técnica atual e desenvolvimento de uma estratégia de utilização de técnicas de Ciência de - Dados e Aprendizado de Máquinas para melhoria dos processos da CGES.
- Desenvolvimento de plano de infraestrutura técnica e capacitação da equipe.
- Desenvolvimento de metodologia de desenvolvimento de produtos de dados.
- Desenvolvimento de proposta de portfólio de produtos de dados.
- Desenvolvimento de produtos de dados: esteiras de dados, relatórios, indicadores, datasets etc.

== Atividades do Consultor Individual
<atividades-do-consultor-individual>
- Geração de planos e relatórios de atividades.
- Colaboração com a equipe da CGES e outras unidades do MS.
- Desenvolvimento de produtos de dados.

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
, caption: [Metadados]
)

= Objetivos
<objetivos>
O presente #emph[Plano de Trabalho] visa:

- Contextualizar o Projeto \(#link(<sec-intro>)[1 Introdução];)
- Apresentar a abordagem de gestão e análise de dados que será adotada \(#link(<sec-metodo>)[3 Método];)
- Descrever os entregáveis e o cronograma de entregas \(#link(<sec-result>)[4 Resultado];)
- Estabelecer expectativas e critérios de sucesso do Projeto \(#link(<sec-conclusao>)[5 Conclusão];)

= Método
<sec-metodo>
== Aspectos Organizacionais
<aspectos-organizacionais>
Muitas organizações já estão na terceira geração de suas #emph[plataformas de dados];, com a esperança de obter #emph[insights] de negócios e tomar decisões rápidas baseadas em evidências. Poucas, porém, podem se dizer verdadeiramente #emph[data-driven];.

Apesar disso, o investimento em tecnologia para análise de dados continua crescendo e o mercado está inundado de diferentes ferramentas e plataformas. Cada uma prometendo ser melhor, mais completa e mais fácil de usar que a outra. Mas, na prática, o que vemos é um cenário de confusão e frustração.

Assim como no desenvolvimento de software, muitas organizações tratam a análise de dados com times especializados na tecnologia, separados das áreas de negócio. No ministério, essa tem sido até agora a diretriz. Há um #emph[datalake] do DATASUS e a DEMAS centraliza o desenvolvimento de "painéis".

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


#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Servir como missão
]
)
]
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

O SUS atua diariamente para melhorar a saúde dos brasileiros, milhares de vezes por dia. A importância da #emph[missão de servir] está fortemente imbuída na cultura do ministério.

Cada #emph[transação] #footnote[Uma transação é uma execução do serviço, um atendimento.] deixa um rastro de dados. A imensa quantidade de dados gerados pelo SUS é visto por alguns como um ativo: essa é uma visão equivocada. Dados só tem valor quando usados.

O #emph[feedback] do usuário, direto e indireto \(via indicadores), fornece informações cruciais para aprimorar o serviço: um fluxo de valor no sentido contrário, do usuário para o serviço.

A missão-maior do SUS vai além de atender o usuário no momento presente, mas também envolve a #emph[evolução contínua] do serviço\* @fig-evolucao, baseada em evidências. Quanto mais rápido o ciclo de #emph[servir];, #emph[analizar] e #emph[aprender];, mais hipóteses podem ser testadas e mais rápido o serviço evolui.

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


#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Evolução orientada a missões
]
)
]
A gestão orientada a evidências estabelece apenas o método da resposta, mas não o que perguntar, para onde evoluir. Para isso é primordial definir escolhas estratégicas, decisões políticas.

O conceito de "#emph[missões];" em políticas públicas tem sido popularizado pela economista Mariana Mazzucato #cite(<Mazzucato2022>);. Ela destaca a importância de definir objetivos claros, ambiciosos e mensuráveis para orientar a inovação \(metas #emph[moonshot];).

A ambição de uma meta #emph[moonshot] envolve essencialmente risco. Elas definem concretamente "#emph[onde];" se quer chegar, mas não "#emph[como];". Para o "#emph[como];" existem "apostas", caminhos-hipótese que se pode testar. Algumas hipóteses vão falhar, mas o aprendizado é parte do processo.

#figure([
#box(width: 90%,image("images/danpink3.svg"))
], caption: figure.caption(
position: bottom, 
[
Auto-motivação segundo Dan Pink. #footnote[Figura inspirada em \@sketchplanations]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-danpink>


Uma grande contribuição do arcabouço de missões apresentado por Mazzucato é lembrar no debate econômico que a mudança é feita por pessoas. E que as pessoas são motivadas por propósitos \(@fig-danpink). Ao longo dos anos, as lições da teoria sociotécnia foram descobertas, esquecidas e redescobertas várias vezes com diferentes nomes.

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

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Servir como prisão
]
)
]
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

Os servidores #emph[da ponta] atendem os #emph[usuários reais] \(ex. a mãe precisando de atendimento para o filho/\* que não para de chorar há dias, a criança desatenta na aula porque já são 9h e ainda não comeu nada\*/); os servidores #emph[meio] atendem os servidores mais à ponta, seus #emph[usuários internos];.

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
O servidor na ponta está preso entre a realidade e o muro organizacional.
]

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Alinhamento e Autonomia
]
)
]
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


== Breve história da Análise de Dados
<breve-história-da-análise-de-dados>
- Modern Data Stack

== Nível de Maturidade em Gestão e Análise de Dados
<nível-de-maturidade-em-gestão-e-análise-de-dados>
- Institucionalização

== Abordagem Data Mesh
<abordagem-data-mesh>
Data Mesh #footnote[Data Mesh é um termo cunhado por Zhamak Dehghani. \(referencia?)] é uma abordagem para escalar e organizar a arquitetura e plataformas de dados baseada nos princípios do #emph[Domain Driven Design];, automação de precessos e #emph[Design Thinking];.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Domínios
]
)
]
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Dados como Produtos
]
)
]
- datasets, esteiras, relatórios,
- FAIR – Findable: Discoverable, Addressable – Acessible: Natively Accessible, System Agnostic, Format Agnostic – Interoperable – Reusable: Value on its own, Trustworthy
- data as code
- contratos, data contracts

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Plataforma de Auto-Serviço
]
)
]
- open source
- DESID Playground
- ingest, transform, serve
- Databricks, Snowflake, Redshift, Microsoft Fabric

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Governança Compartilhada
]
)
]
- INDA - Infra-estrutura Nacional de Dados Abertos

== Gestão Ágil
<gestão-ágil>
- Scrum based
- espiral
- sprints
- retrospective
- no daily

== Riscos e Mitigações
<riscos-e-mitigações>
- falta ferramentas básicas de colaboração e gestão
- datasus

= Resultado
<sec-result>
== Entregáveis
<entregáveis>
+ Plano de Trabalho – Fevereiro 2024 – este documento
+ Mapeamento de sistemas e processos de geração de dados – Março 2024 – current state of organizational capacity, maturity level – mapeamento produtos de dados existentes – mapeamento desafios organizacionais
+ Plano de Infra-estrutura e Capacitação – especificação do DESID PLayground \(infraestrutura de desenvolviomento de produtos de dados) – gap de capacidades
+ Metodologia de Desenvolvimento de Produtos de Dados – documentação de processos
+ Proposta de Portifólio de Produtos de Dados – mapeamento de potenciais produtos de dados – catálogo de produtos
+ Apresentação de Produtos de Dados – pelo menos um por domínio: Orçamentos, Preços, Custos, Contas de Saúde

== Cronograma
<cronograma>
- gantt chart

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

