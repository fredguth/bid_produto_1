
#let report(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  iadb_contract: none,
  iadb_project: none,
  iadb_product: none,
  cols: 1,
  lang: "pt",
  region: "BR",
  font: (),
  fontsize: 10pt,
  sectionnumbering: none,
  toc: false,
  toc-depth: none,
  bib_syle: "apa",
  theme: (
    color: blue.darken(30%),
    serif: "Harding Text Web",
    sans: "Lato",
    mono: "SF Mono",
    normal: 10pt,
    small: 8pt,
  ),
  doc,
) = {
  set page(
    paper: "a4",
    margin: (inside: 1cm, top: 1.5cm, outside: 1cm, bottom: 1.5cm),
    numbering: "1",
    header-ascent: .5cm,
    footer-descent: .5cm,
    header: locate(loc => {
      if (loc.page() != 1) {
        block(
          width: 100%,
          stroke: (bottom: 1pt + gray),
          inset: (bottom: 8pt, right: 2pt, left: 2pt),
          [ #set text(font: theme.sans, size: theme.small, fill: gray.darken(50%))
            #grid(
              columns: (1fr, 1fr),
              align(left, []),
              align(right, text(weight: "bold", upper[Relatório])),
            ) ],
        )
      }
    }),
    footer: block(
      width: 100%,
      stroke: (top: 1pt + gray),
      inset: (top: 8pt, right: 2pt),
      [
        #set text(font: theme.sans, size: theme.small, fill: gray.darken(50%))
        #grid(
          columns: (75%, 25%),
          align(left)[#date],
          align(
            right
          )[#counter(page).display() de #locate((loc) => { counter(page).final(loc).first() })],
        )
      ],
    )
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           historical-ligatures: true,
           ligatures: true,
           font: theme.sans,
           size: theme.normal)
  
  set heading(numbering: sectionnumbering)

  if title != none {
    text(font: theme.sans, fill: gray.lighten(60%), upper[Relatório])
    v(.2cm)
    text(font: theme.serif, size: 20pt, weight: "black", title)
    if subtitle != none {
      v(-.3cm)
      text(font: theme.serif, size: 16pt, weight: "light", subtitle)
    }
    v(1cm)
    line(length: 100%, stroke: 2pt + theme.color)
    v(1cm)
  }
 
  grid(columns: (62%, 3%, 35%), text(font: theme.serif, doc) ,[], {
    if authors != none {
       
      if toc {
        block(above: 2em, below: 2em)[
          #outline(
            title: auto,
            depth: 1,
            indent: auto
          );
        ]
     } 
      place(dy:6.5cm, block(fill: blue.lighten(95%),width: 100%,inset: 1em,radius: 6pt)[
        #for (author) in authors [
          #if author.role!= none [*#author.role*]

          #h(1em)#author.name #if author.affiliation!=none {text(font: theme.mono, size: theme.small)[(#author.affiliation)]}
          #if author.email!=none [#v(-.5em)#h(1em)#text(size: theme.small, author.email)]
          
        ]
        #if iadb_contract != none [
          *Contrato*\
          #h(1em)#text(size: theme.small, iadb_contract)
        ]
        #if iadb_project != none [
          *Projeto*\
          #text(size: theme.small, pad(left: 1em,[#iadb_project]))
          
        ]
          #if iadb_product != none [
          *Produto*\
          #h(1em)#text(size: theme.small, iadb_product)
          
        ]
      ])
    }

    
  })





  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  

}
