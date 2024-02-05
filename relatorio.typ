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
  margin: (bottom: 1.5cm,left: 5cm,right: 1cm,top: 1.5cm,),
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
#figure([
#box(width: 12083.0pt, image("images/MAD2023.png"))
], caption: figure.caption(
position: bottom, 
[
A imensidão do confuso mercado de ferramentas analíticas.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


Estima-se que o investimento em ferramentas analíticas tenha superado 80 bilhões de dólares em 2023#cite(<snowflake2020s1>);. Muitas organizações já estão na terceira geração de suas #emph[plataformas de dados];, com a esperança de obter #emph[insights] e tomar decisões rápidas baseadas em evidências. Poucas, porém, podem se dizer verdadeiramente #emph[data-driven];.

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Datawarehouses e BI \(primeira geração):] consolidando dados de diversas fontes, essa estratégia foca na limpeza e verificação dos dados antes de torná-los disponíveis. Essa centralização enfrenta desafios de escalabilidade à medida que as fontes de dados aumentam. Principais artefatos são relatórios e painéis \(#emph[dashboards];). Tabelas e relatórios complicados entendidos por poucos especialistas, impacto limitado nos negócios.

#strong[Big Data e Data Lakes \(segunda geração):] Como resposta aos gargalos da geração anterior e aproveitando a redução de custos de #emph[hardware];, #emph[Data Lakes] armazenam dados em arquivos, com transformações ocorrendo no momento do consumo. Embora ofereça flexibilidade, esta abordagem apresenta desafios quanto à qualidade e documentação dos dados.

#strong[Plataformas em Nuvem \(terceira geração):] semelhante à geração anterior, mas modernizada com:

- #strong[\(a)] dados em tempo real \(#emph[streams];);
- #strong[\(b)] processamento unificado de dados em #emph[batch] e #emph[stream];; e
- #strong[\(c)] uso intensivo da nuvem. Embora aborde falhas anteriores, ainda carrega problemas das gerações passadas.

])

Entender por que tantas implantações de plataformas de dados não entregam os resultados esperados é essencial para assegurar o sucesso deste projeto.

#figure([
#box(width: 90%,image("images/missing_leg.svg"))
], caption: figure.caption(
position: bottom, 
[
Investimento em capacidade tecnológica, ferramentas e #emph[know-how];, é condição necessária mais não suficiente para se tornar #emph[data-driven];.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-missing-leg>


Em nossa experiência, muitos projetos pecam por acreditar que basta investimento em tecnologia. Investimento em capacidade tecnológica, ferramentas e #emph[know-how];, é condição necessária mas não suficiente para uma organização se tornar #emph[data-driven] @fig-missing-leg.

Para compreensão do método a ser adotado no presente projeto, partiremos da definição do problema, explorando-o em todas as suas dimensões.

== Definição do Problema
<definição-do-problema>
=== Servir, Aprender e Evoluir
<servir-aprender-e-evoluir>
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


Todo serviço deve transformar seu #emph[usuário] para melhor #footnote[#emph[Usuário] Pessoa ou organização que se beneficia de um serviço. Também chamado de #emph[cliente];.];; um #emph[fluxo de valor] que pode envolver diversas etapas e atendimentos \(@fig-servico). O SUS atua diariamente para melhorar a saúde dos brasileiros, milhares de vezes por dia. A importância de #emph[servir] \(atender) está fortemente imbuída na cultura do Ministério.

Cada #emph[transação] #footnote[Uma transação é uma execução do serviço, um atendimento.] deixa um rastro de dados. A imensa quantidade de dados gerados pelo SUS é visto por alguns como um ativo: essa é uma visão equivocada. Ativos têm valor quando guardados, mas #emph[dados] só tem valor quando usados.

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Dados transacionais:] dados primários que sustentam o funcionamento dos serviços diretos ao usuário e mantêm seu estado atual. Também conhecidos como #emph[dados operacionais];.

#strong[Dados analíticos:] dados derivados das bases transacionais \(secundários), fornecem visão agregada e histórica dos serviços.

])

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


O #emph[feedback] do usuário, direto e indireto \(via indicadores), fornece informações cruciais para aprimorar o serviço: um fluxo de valor no sentido contrário, do usuário para o serviço. O propósito do SUS vai além de atender o usuário no momento presente, mas também envolve a #emph[evolução contínua] do serviço \(@fig-evolucao,) baseada em evidências. Quanto mais rápido o ciclo de #emph[servir];, #emph[analizar] e #emph[aprender];, mais hipóteses podem ser testadas e mais rápido o serviço evolui.

=== Desafios Organizacionais
<sec-prisao>
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


#quote(block: true)[
"Nos primeiros quatro meses de 2023, mais de 10,3 mil servidores \[1/3 do quadro\] da Secretaria de Saúde do Distrito Federal \(SES-DF) precisaram de atestados de afastamento do trabalho. Grande parte desses servidores são técnicos em enfermagem" – #cite(<Schwingel2023>);.
]

Organizações doentes adoecem pessoas. No serviço público, são servidoras #emph[da ponta];, que tem contato direto com usuário, as que mais adoecem. #emph[O que está acontecendo?]

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


Organizações públicas e privadas ainda são majoritariamente estruturadas em silos funcionais \(@fig-paredes), com equipes especializadas em áreas como negócio, tecnologia, jurídico, controle; herança da burocracia de Weber e da #emph[gestão científica] de Taylor do início do século XX.

Esta estrutura exige que cada serviço seja coordenado entre equipes distintas, com diferentes hierarquias, prioridades e linguagens. A dinâmica lembra a brincadeira da #emph[corrida de três pernas] das #emph[gincanas infantis];, onde se amarra o pé de um criança ao de outra: a falta de alinhamento entre equipes resulta em atrasos e falhas, fazendo com que o conjunto mova-se ao ritmo imposto pela equipe mais lenta.

Os servidores #emph[da ponta] atendem os #emph[usuários reais];, enfrentam a realidade; os servidores #emph[meio] atendem os servidores mais à ponta, #emph[usuários internos];. Estar na ponta traz clareza da importância da sua contribuição individual, #strong[senso de propósito];. Ao mesmo tempo, exarceba a #strong[sensação de impotência] diante de uma realidade que não se tem total autonomia para mudar.

#quote(block: true)[
O servidor na ponta está preso entre a realidade e o muro organizacional.
]

#figure([
#box(width: 90%,image("images/danpink3.svg"))
], caption: figure.caption(
position: bottom, 
[
Auto-motivação segundo Dan Pink \(Figura inspirada em #emph[\@sketchplanations];)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-danpink>


Dan Pink argumenta que a auto-motivação é impulsionada por três elementos fundamentais: autonomia, maestria e propósito #cite(<pink2010drive>);. Autonomia refere-se à capacidade de controlar o próprio trabalho; maestria é o desejo de evoluir continuamente em algo que importa; e propósito diz respeito à conexão do trabalho com algo maior e mais significativo. Pink sugere que quando esses três elementos estão presentes, os indivíduos são mais motivados, engajados e produtivos.

Em certa medida, a organização em silos produz a antítese das condições para a automotivação.

=== Evolução orientada a missões
<sec-missoes>
A gestão orientada a evidências estabelece apenas o método da resposta, mas não o que perguntar, para onde evoluir. Para isso é primordial definir escolhas estratégicas, decisões políticas.

O conceito de "#emph[missões];" em políticas públicas tem sido popularizado pela economista Mariana Mazzucato #cite(<Mazzucato2022>);. Ela destaca a importância de definir objetivos claros, ambiciosos e mensuráveis para orientar a inovação, metas #emph[moonshot];.

#block(
fill:yellow.lighten(90%),
outset:1em,
radius:6pt,
width:70%,
[
#strong[Moonshot:] Meta ambiciosa, que requer inovação radical para ser atingida. Remete ao projeto Apollo que ambicionou levar humanos à Lua. Difere-se da missão-maior de servir por ser uma missão-meta, com prazo e escopo definidos.

#emph[Ex.] Meta "Três Bilhões" da OMS: #cite(<gpw13>)

- 1 bilhão de pessoas a mais com cobertura universal de saúde.
- 1 bilhão de pessoas a mais protegidas de emergências de saúde.
- 1 bilhão de pessoas a mais gozando de melhor saúde e bem-estar.

])

A ambição de uma meta #emph[moonshot] envolve essencialmente risco. Elas definem concretamente "#emph[onde];" se quer chegar, mas não "#emph[como];". Para o "#emph[como];" existem "apostas", caminhos-hipótese que se pode testar. Algumas hipóteses vão falhar, mas o aprendizado é parte do processo.

=== Cultura organizacional
<sec-cultura>
Uma grande contribuição do arcabouço de missões apresentado por Mazzucato é lembrar no debate econômico que mudança é feita por pessoas e que as pessoas são motivadas por propósitos \(@fig-danpink). Para criar um ambiente em que os indivíduos se auto-motivem, é importante criar uma cultura organizacional adequada. Para isso, é importante pensar em governança.

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


Governança é o conjunto de políticas, procedimentos, padrões e responsabilidades estabelecidos para orientar e monitorar a gestão e o uso de recursos \(incluindo dados, tecnologia e processos) de maneira eficaz e alinhada com os objetivos da organização. A governança garante que haja clareza nas decisões, responsabilidades e que os riscos sejam gerenciados adequadamente, protegendo os interesses de todas as partes envolvidas.

A relação entre #emph[alinhamento] e #emph[autonomia] entre equipes e pessoas determina a governança em uma organização. Quando há pouco alinhamento e pouca autonomia, o resultado tende a ser a uma cultura apática, onde a falta de direção clara e a restrição na tomada de decisão geram desengajamento e falta de iniciativa. Em contraste, um cenário de muito alinhamento com pouca autonomia caracteriza a autocracia, que limita a inovação e a velocidade das mudanças. Por outro lado, pouco alinhamento combinado com muita autonomia pode levar a uma forma de anarquia, onde há esforços descoordenados e ineficiência.

Muros organizacionais \(@sec-prisao) favorecem o surgimento de #emph[autocracia] dentro dos silos e #emph[anarquia] entre silos.

O ideal é uma cultura ágil, de muito alinhamento e muita autonomia, que propicia decisões rápidas, bem embasadas e invadoras. Para tanto, é preciso romper com silos e montar equipes multifuncionais, autônomas e responsáveis por um ou mais serviços do início ao fim e alinhadas à estragégia maior.

#figure([
#box(width: 90%,image("images/missao.svg"))
], caption: figure.caption(
position: bottom, 
[
O arcabouço socio-técnico
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-missao>


== Abordagem sociotécnica
<abordagem-sociotécnica>
A análise do problema torna transparente que além de direcionamento estratégico \(missão) e capacidade técnica, a evolução contínua de um serviço depende de uma cultura organizacional adequada, ou seja, depende de aspectos sociais. Esse é o argumento central da teoria sociotécnica, cujas lições foram descobertas, esquecidas e redescobertas várias vezes com diferentes nomes ao longo dos anos, das minas de carvão de Yorkshire, ao vale do silício.

=== Das minas de carvão de Yorkshire ao Spotify
<das-minas-de-carvão-de-yorkshire-ao-spotify>
No final dos anos 1940, o carvão era a principal fonte de energia da Inglaterra. Para apoiar a recostrução industrial pós-guerra, era essencial aumentar a sua produção e reduzir custos. Com esse intuito, introduziram-se novas máquinas nas minas de Yorkshire. A produtividade, contudo, diminuiu.

Chamados para investigar o problema, pesquisadores do Instituto Tavistock descobriram que as novas máquinas alteraram a dinâmica e cooperação entre os mineiros, que antes trabalhavam em equipes multifuncionais e autônomas com foco na resolução de problemas e alto grau de adaptabilidade.

Dessa observação nasceu a teoria sociotécnica, que enfatiza a importância de equilibrar tecnologia e relações humanas. Essa lição foi ora esquecida, ora redescoberta em diferentes contextos:

- No esforço de guerra americano que dobrou o PIB em 4 anos;
- Na reconstrução do devastado Japão com o que se tornou conhecido como sistema Toyota de produção \(Lean Manufacturing);
- No movimento de Lean Startups e DevOps do Vale do Silício que culminaram no que hoje é referido como modelo Spotify.

#figure(
align(center)[#table(
  columns: 2,
  align: (col, row) => (left,left,).at(col),
  inset: 6pt,
  [Princípio], [Descrição],
  [#strong[Foco no Valor];],
  [Focar em entregar valor aos usuários.],
  [#strong[Times Multifuncionais];],
  [Colaboração entre diferentes especialidades para agilizar e melhorar a qualidade do serviço.],
  [#strong[Autonomia];],
  [Empoderar equipes para tomar decisões e falhar.],
  [#strong[Alinhamento];],
  [Garantir alinhamento de padrões e objetivos comuns.],
  [#strong[Entrega Contínua];],
  [Automatizar com toque humano, reduzindo o tempo entre pedido e feedback do usuário.],
  [#strong[Feedback Contínuo];],
  [Utilizar o feedback dos usuários em ciclos rápidos de melhoria.],
  [#strong[Melhoria Contínua];],
  [Otimizar constantemente processos e serviços para alcançar excelência operacional.],
  [#strong[Eliminação de Desperdícios];],
  [Eliminar atividades que não agregam valor.],
  [#strong[Comunicação Aberta];],
  [Promover a transparência e compartilhamento de informações.],
  [#strong[Liderança Servil];],
  [Apoiar, capacitar e servir às equipes, em vez de direcioná-las.],
)]
, caption: [Os 10 princípios sociotécnicos]
)

=== DevOps: Abordagem sociotécnica no desenvolvimento de software
<devops-abordagem-sociotécnica-no-desenvolvimento-de-software>
No início do milênio, a prestação de serviços via web começou a se sofisticar e #emph[sites] passaram a ficar cada vez mais parecidos com #emph[aplicações];.

Em grande medida, a #emph[web];, que foi criada como uma plataforma para publicação e consumo de documentos \(páginas), é um ambiente hostil para desenvolvimento de \_aplicações. Desenvolver #emph[webapps] envolve coordenar trabalhos muito distintos que vão desde aspectos visuais e de usabilidade \(UI/UX), lidar com a diversidade de navegadores e suas respectivas compatibilidades tecnológicas, interoperabilidade com bancos de dados e sistemas de terceiro e questões de manutenção da infra-estrutura.

A entrega de valor acontece quando novas #emph[funcionalidades] são publicadas e usadas pelos usuários. A evolução do serviço e ganho de competitividade depende de acelerar o ciclo de lançamento, análise e aprendizado. Ainda assim, mesmo entre os líderes de mercado, este era um processo lento, arriscado e custoso e o desenvolvimento de aplicações web envolvia lidar com diversos desafios:

+ #strong[Silos entre Desenvolvimento e Operações];: As equipes de desenvolvimento e operações \(negócios) trabalhavam frequentemente em isolamento, com pouca colaboração ou comunicação entre elas. Isso levava a uma transferência ineficaz do software do desenvolvimento para a produção, com operações lutando para gerenciar e manter aplicativos que não compreendiam completamente.

+ #strong[Ciclos de Lançamento Lentos];: Os métodos de desenvolvimento de software tradicionais, como o modelo em cascata, dominavam, levando a ciclos de lançamento longos e inflexíveis. Isso dificultava a capacidade das empresas de responder rapidamente às mudanças no mercado ou às necessidades dos clientes.

+ #strong[Falta de Automação];: A automação em áreas como testes, integração e implantação de software era limitada ou inexistente. Isso resultava em processos manuais propensos a erros, atrasos significativos e uma qualidade de produto inconsistente.

+ #strong[Dificuldades de Escalabilidade e Estabilidade];: Com a popularidade crescente da internet e das aplicações web, as organizações enfrentavam desafios significativos em escalar e manter a estabilidade de seus sistemas sob demanda variável. A falta de práticas e ferramentas adequadas para gerenciar a infraestrutura de TI complicava esses problemas.

+ #strong[Desafios de Qualidade e Confiabilidade];: A falta de práticas contínuas de integração e testes levava frequentemente a bugs de software e problemas de confiabilidade que só eram descobertos após o lançamento. Isso afetava negativamente a experiência do usuário e a reputação das empresas.

+ #strong[Resistência à Mudança];: Existia uma resistência cultural significativa à mudança dentro das organizações. Isso incluía a hesitação em adotar novas tecnologias e práticas, bem como a dificuldade em quebrar os silos organizacionais existentes.

Por volta dos anos 2000, a Amazon implantava melhoria em sua plataforma de e-commerce em ciclos que duravam de muitos meses e até anos. Já em 2015, o varejista implantava mais de 50 milhões de melhorias por ano \(uma implantação por segundo)#cite(<HowAmazon>);. Em 15 anos a empresa mudou totalmente os seus processos e as inovações criadas no processo deram origem a todo uma nova linha de negócios, a AWS \(Amazon Web Services).

O lançamento do #emph[framework] Rails em 2004 é um marco na trajetória de disseminação de práticas culturais para o desenvolvimento de aplicações web. Surge a ideia de #strong[convenção sobre configuração];, ou seja, a adoção de padrões de processo que tornam possível automatizar tarefas do desenvolvimento.

Já no final dos anos 2000, início dos anos 2010, os aspectos sociotécnicos começaram a ser disseminados e conhecidos como #strong[DevOps] a integração dos silos de desenvolvimento e operações.

Hoje o desenvolvimento web é muito mais engenharia que arte e processos de:

- contole de versão;
- testes automatizados;
- integração contínua \(Continuous Integration, CI);
- implantação contínua \(Continuous Deployment, CD);

estão bastante disseminados em toda a indústria.

=== DataOps: Abordagem socio-técnica para Dados
<dataops-abordagem-socio-técnica-para-dados>
Nos últimos poucos anos, as equipes responsáveis de gestão e análise de dados despertaram para as vantagens da abordagem socio-técnica e começaram a desenvolver e disseminar metodologia ágeis similares ao DevOps. Esse movimento passou a ser chamado #strong[DataOps];.

== Arcabouço Data Mesh
<arcabouço-data-mesh>
O presente projeto pretende aplicar uma metodologia sociotécnica chamada #strong[Data Mesh];, proposta por Zhamak Dehghani em 2019 e adotada por empresas como Netflix e PayPal.

Data Mesh propõe uma arquitetura de dados descentralizada, com foco no design orientado ao domínio e auto-serviço. Inspirado em teorias de design orientado ao domínio e topologias de equipe, o Data Mesh busca escalar a análise de dados através da descentralização, transferindo a responsabilidade dos dados de equipes especialistas em dados para as equipes de domínio \(áreas de negócio), com suporte de uma equipe de plataforma de dados.

Data Mesh é baseada em quadtro princípios fundamentais:

+ Dados como Produto;
+ Propriedade do Domínio;
+ Plataforma Auto-Serviço de Dados;
+ Governança Compartilhada.

=== Dados como Produto
<dados-como-produto>
Encarar os dados como um produto implica tratá-los com o mesmo nível de cuidado e atenção dedicados ao desenvolvimento de produtos de software.

Um dado tem valor quando usado e para que seja usado ele precisa ter algumas características identificadas pelo acrônimo #emph[FAIR];:

#figure(
align(center)[#table(
  columns: 2,
  align: (col, row) => (left,left,).at(col),
  inset: 6pt,
  [Princípio FAIR], [Descrição],
  [Localizável],
  [Os dados devem ser facilmente descobertos e endereçáveis tanto por humanos quanto por computadores.],
  [Acessível],
  [Os dados devem ser nativamente acessíveis e independentes de sistemas e formatos, permitindo o acesso através de diversas plataformas e ferramentas.],
  [Interoperável],
  [Os dados devem ser capazes de se integrar com outros conjuntos de dados, aplicações e processos de trabalho para análise, armazenamento e processamento.],
  [Reutilizável],
  [Os dados devem possuir valor intrínseco, ser confiáveis e estruturados de forma que suportem sua reutilização em diferentes contextos.],
)]
)

Além dessas características, é importante a #emph[codificação] de todo o processo de transformação dos dados, o que permite a criação de processos automáticos de documentação, testes e publicação dos dados.

=== Propriedade do Domínio
<propriedade-do-domínio>
Este princípio enfatiza a importância de atribuir a autonomia e responsabilidade dos dados às equipes que estão intimamente ligadas ao domínio específico do negócio. A ideia é que as equipes de domínio, que possuem conhecimento especializado sobre seus respectivos setores, estão melhor posicionadas para gerenciar, curar e atualizar os dados de maneira eficaz. Isso promove uma maior qualidade e relevância dos dados, já que a equipe de domínio entende as nuances e requisitos específicos dos dados que gerencia.

No contexto do Projeto, os domínios da CGES são:

- Orçamentos
- Preços
- Custos
- SHA

=== Governança Compartilhada
<governança-compartilhada>
Este princípio enfatiza a importância de manter padrões e políticas de dados coesos em todos os domínios de uma organização e até entre organizações.

Além de facilitar a interoperabilidade e automação, a adoção de #strong[convenções] facilita a comunicação entre equipes e reduz a quantidade de decisões de pouca relevância que precisam ser tomadas.

No contexto deste projeto, além de buscar criar políticas de governança compartilhadas entre as coordenações da DESID, buscaremos alinhar nossas políticas a outras áreas como o DEMAS e às políticas da Infra-estrutura Nacional de Dados Abertos \(INDA).

=== Infra-estrutura de auto-serviço
<infra-estrutura-de-auto-serviço>
A ideia de uma plataforma de dados auto-serviço é fornecer às equipes as ferramentas e capacidades necessárias para acessar, manipular e analisar dados sem depender excessivamente de suporte técnico especializado. Isso democratiza o acesso aos dados e capacita os usuários finais, permitindo que eles realizem tarefas de dados de forma independente, com agilidade e eficiência. Essas plataformas são projetadas para serem intuitivas e fáceis de usar, reduzindo barreiras para o trabalho com dados.

No contexto deste projeto, será desenvolvida uma plataforma auto-serviço de análise de dados para o DESID baseada em ferramentas open-source: DESID Playground. O #strong[DESID Playground] éum dos principais entregáveis do projeto.

== Critérios de Sucesso
<critérios-de-sucesso>
O conceito de nível de maturidade é aplicada por diferentes governos e organizações para avaliar qualitativamente a eficácia das práticas de gestão e análise de dados e monitorar a evolução desses processos. À medida que uma organização avança nos níveis de maturidade, ela implementa práticas de governança de dados mais formalizadas e padronizadas, alcançando maior eficiência, qualidade dos dados e capacidade de inovação.

#figure(
align(center)[#table(
  columns: 3,
  align: (col, row) => (center,left,left,).at(col),
  inset: 6pt,
  [#strong[Nível];], [#strong[Nome];], [#strong[Descrição];],
  [1],
  [Inicial],
  [Processos ad-hoc, não estruturados e frequentemente caóticos.],
  [2],
  [Repetível],
  [Processos gerenciáveis e repetitivos, mas com pouca formalização.],
  [3],
  [Definido],
  [Processos documentados, padronizados e integrados.],
  [4],
  [Gerenciado],
  [Processos monitorados e controlados, com melhoria contínua baseada em métricas.],
  [5],
  [Otimizado],
  [Foco na otimização contínua e no uso de dados para inovação e vantagem competitiva.],
)]
, caption: [Níveis de Maturidade de Processos de Governança de Dados]
)

Acreditamos que a melhor forma de medir o sucesso deste projeto é através de uma auto-avaliação da equipe beneficiária \(CGES/DESID) do nível de maturidade da análise de dados antes e depois do projeto.

A auto-avaliação inicial é um dos entregáveis da próxima etapa do projeto;

== Gestão de Projeto
<gestão-de-projeto>
A gestão do projeto será livremente inspirada na metodologia ágil Scrum:

- #emph[sprints] de 2 a 3 semanas para cada domínio;
- uma reunião de retrospectiva da #emph[sprint] anterior e planejamento da próxima #emph[sprint];;
- sem reuniões de alinhamento diário;

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
- Auto-avaliação do nível de maturidade

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
Este plano de trabalho representa o primeiro entregável de um projeto ambicioso, cujo objetivo principal é promover a evolução da governança da análise de dados da CGES/DESID.

Esperamos contribuir para uma evolução nas práticas, processos e ferramentas de análise de dados que represente a elevação de pelo menos um nível de maturidade até o término do projeto.

A descrição dos entregáveis e o cronograma apresentado reflete a nossa melhor estimativa para a conclusão das etapas planejadas. No entanto, caso identifiquemos oportunidades para adiantar as entregas sem comprometer a qualidade, certamente o faremos. Este compromisso não apenas reflete a nossa dedicação em atingir os objetivos estabelecidos, mas também em superar as expectativas da equipe.

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

