#import "@preview/tablex:0.0.5": tablex, hlinex, vlinex, colspanx, rowspanx
#let york = [
    No final dos anos 1940, o carvão era a principal fonte de energia da Inglaterra. Para apoiar a reconstrução industrial pós-guerra, era essencial aumentar a sua produção e reduzir custos. Com esse intuito, introduziram-se novas máquinas nas minas de Yorkshire. A produtividade, contudo, diminuiu.

    Chamados para investigar o problema, pesquisadores do Instituto Tavistock descobriram que as novas máquinas alteraram a dinâmica e cooperação entre os mineiros, que antes trabalhavam em equipes multifuncionais e autônomas com foco na resolução de problemas e alto grau de adaptabilidade.

    Dessa observação nasceu a teoria sociotécnica, que enfatiza a importância de equilibrar tecnologia e relações humanas. Essa lição foi ora esquecida, ora re-
    descoberta em diferentes contextos:
    // #set list(indent:0em
    //       , body-indent: 0.5em
    //       , marker: [--])
    - No esforço de guerra americano que dobrou o PIB em 4 anos;
    - Na reconstrução do devastado Japão com o que se tornou conhecido como sistema Toyota de produção;
    - No movimento de Lean Startups e DevOps do Vale do Silício que culminaram no que hoje é referido como modelo Spotify.

    //  Tabela
    #tablex(
    columns: (2fr,3fr),
    align: left + horizon,
    auto-vlines: false,
    stroke: .25pt + gray,
    hlinex(stroke: 0.5pt),
    [*Times Multifuncionais*], [Colaboração entre diferentes especialidades para agilizar e melhorar a qualidade do serviço.],
    [*Foco no Valor*], [Focar em entregar valor aos usuários.],
    [*Eliminação de Desperdícios*], [Eliminar atividades que não agregam valor.],
    [*Autonomia*], [Empoderar equipes para tomar decisões e falhar.],
    [*Alinhamento*], [Garantir alinhamento de padrões e objetivos comuns.],
    [*Entrega Contínua*], [Automatizar com toque humano, reduzindo o tempo entre pedido e feedback do usuário.],
    [*Feedback Contínuo*], [Utilizar o feedback dos usuários em ciclos rápidos de melhoria.],
    [*Melhoria Contínua*], [Otimizar constantemente processos e serviços para alcançar excelência operacional.],
    [*Comunicação Aberta*], [Promover a transparência e compartilhamento de informações.],
    [*Liderança Servil*], [Apoiar, capacitar e servir às equipes, em vez de direcioná-las.],
    hlinex(stroke: 0.5pt),
    )
]



// Na época, o carvão era vital para a indústria, mas a produtividade estava estagnada, e muitos mineiros buscavam trabalhos melhores. O absenteísmo atingia 20% e disputas trabalhistas eram constantes, apesar de melhorias nas condições de trabalho. O Conselho Nacional de Carvão, percebendo a crise, solicitou um estudo comparativo entre minas com diferentes níveis de moral e produção.

// Em um aspecto inovador, observou-se uma nova organização de trabalho em uma camada específica. Grupos autônomos colaboravam eficientemente, com baixo absenteísmo e alta produção, contrastando com o ambiente comum das minas. Eles adotaram práticas antigas, pré-mecanização, em que pequenos grupos autônomos eram responsáveis por ciclos completos de trabalho. Embora a mecanização tenha fragmentado essas práticas, essa mina específica encontrou uma maneira de recuperar a coesão e a autoregulação, fortalecendo sua influência nas decisões de trabalho.

// Em resumo, a inovação Haighmoor propôs um novo modelo, provando que havia alternativas para melhorar a indústria.
