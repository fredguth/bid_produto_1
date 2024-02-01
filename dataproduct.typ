#import "@preview/tablex:0.0.5": tablex, hlinex, vlinex, colspanx, rowspanx
#let dataproduct = [

    //  Tabela
    #tablex(
    columns: (1.3fr,3fr),
    align: left + horizon,
    auto-vlines: false,
    stroke: .25pt + gray,
    hlinex(stroke: 0.5pt),
    [*Úteis*], [Dados não usados, não tem valor.],
    [*Interoperáveis*], [Acessíveis de forma programática e em formatos e padrões de conhecidos.],
    [*Descobríveis*], [Publicados em um catálogo público onde possam ser facilmente encontrados. Devem conter _metadados_ como _domínio_, _linhagem_ e _métricas de qualidade_],
    [*Endereçáveis*], [Publicado em um endereço permanente com padrão de nomeação e formato.],
    [*Compreensíveis*], [Contendo documentação que permita qualquer pessoa entender o que os dados significam e como foram calculados.],
    [*Confiáveis*], [Níveis de serviço estabelecidos para atualização e pontualidade, completude, atualidade, disponibilidade e linhagem. Uso de testes automáticos.],
    [*Acessíveis*], [Disponiblizados em formato e padrão que facilitem o consumo pelo usuário.],
    [*Seguros*], [Anonimização de dados. Controle de viés, validade e acesso.],
    hlinex(stroke: 0.5pt),
    )
]
