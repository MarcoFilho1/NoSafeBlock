# No Safe Block — expansão de sobrevivência urbana

Status: implementada localmente e validada em 2026-09-21; aguarda integração da equipe.

## Objetivo e premissas

Expandir o jogo de hordas com exploração urbana, defesa de interiores, compras durante a partida, progressão limitada e inimigos com comportamentos distintos. A referência é o ritmo do modo Zumbis de Call of Duty e a variedade urbana de Los Angeles, com cenário e armas fictícias originais.

Preservar Godot 4.6.1, GDScript, desktop, câmera isométrica e arte procedural low-poly. Essas são premissas baseadas no projeto existente. Não implica reproduzir uma cidade real ou mudar para primeira pessoa. A progressão é por partida e reinicia ao morrer.

## Abordagens consideradas

1. **Recomendada: cidade construída com módulos e layout fixo.** Permite bairros reconhecíveis, rotas verificáveis, interiores e posicionamento intencional de lojas. Amplia a base existente com risco controlável.
2. Cidade inteiramente procedural a cada partida. Oferece novidade, mas aumenta muito os riscos de navegação, locais inacessíveis e balanceamento espacial.
3. Várias arenas menores com transições. Reduz o custo de renderização, mas enfraquece a exploração contínua pedida.

## Cidade e exploração

Mapa-alvo de 180 × 180 unidades, aproximadamente 25 vezes a área atual, com câmera acompanhando o jogador. Cinco setores conectados: centro comercial, zona residencial, distrito industrial, avenida com posto e motel, e área de quarentena com laboratório. Ruas largas alternam com becos, pátios e passagens entre edifícios.

Construções variadas: apartamentos, lojas, lanchonete, delegacia, clínica, galpões, motel e laboratório. Ao menos seis interiores acessíveis no térreo, sem telas de carregamento. Fachadas que ocultam o jogador devem desaparecer parcialmente. Veículos abandonados, ônibus, escombros, janelas destruídas, manchas, vegetação seca e iluminação de emergência compõem a atmosfera sem tornar os ataques ilegíveis.

Mapa compacto na interface indica posição, setores e estações de compra descobertas. O centro inicial tem pistola, munição e uma primeira posição defensiva. Armas superiores ficam mais longe, dando motivo para explorar. Não exigir um sistema adicional de desbloqueio de bairros nesta expansão.

## Barricadas

Pontos de construção claramente marcados em entradas e janelas dos interiores. E constrói ou repara o ponto próximo, mediante custo em pontos. Cada barricada possui três estágios visuais de integridade; não é invulnerável. Inimigos atacam a barricada que bloqueia o caminho, e a passagem abre quando ela é destruída.

Bloquear entradas não pode tornar o jogador inalcançável indefinidamente: inimigos podem romper as defesas e interiores têm múltiplos acessos. Reparar não concede pontos, exige proximidade e tem intervalo entre ações. Barricadas são reiniciadas ao começar outra partida.

## Economia, armas e itens

Separar pontuação acumulada de saldo disponível. Mortes e conclusão de hordas concedem pontos; compras debitam somente o saldo. Preços e atributos ficam em catálogos de dados, sem valores dispersos pela interface.

Arsenal inicial proposto: pistola de serviço gratuita, pistola pesada (450), submetralhadora (900), espingarda calibre 12 (1.200), fuzil (1.800), rifle de precisão (2.400), metralhadora leve (3.000), emissor de plasma (4.500) e projetor elétrico (5.500). Valores são parâmetros iniciais sujeitos a testes de balanceamento.

Identidades mecânicas: espingarda lança múltiplos projéteis com dispersão; fuzil combina alcance e cadência; rifle tem alto impacto e baixa cadência; metralhadora troca mobilidade e recarga por sustentação; plasma causa explosão localizada; eletricidade encadeia entre poucos alvos próximos com linha de visão. Efeitos não atravessam paredes arbitrariamente.

Duas armas carregadas, alternadas por 1/2 ou roda do mouse. Comprar uma terceira substitui o slot ativo, com indicação prévia na interface. Pistola conserva reserva infinita como recurso de emergência; demais armas usam reserva limitada, recomprável nas estações. Armas futuras não herdam acidentalmente a reserva infinita do MVP.

Itens adicionais: kit médico de uso imediato, colete reparável e granadas com limite de três. Pequenas chances de drops de munição e tratamento, com duração limitada no chão. Comprar é uma interação no mundo e não pausa as hordas.

## Progressão limitada

Estações de melhorias oferecem no máximo três níveis por atributo: vida máxima (100 → 125 → 150 → 175), resistência (0 → 8 → 16 → 24%), recarga (redução de 0 → 10 → 20 → 30%) e movimento (bônus de 0 → 5 → 10 → 15%). Cada arma admite duas melhorias de dano, até +40% sobre seu dano base. Não acumular melhorias além do teto nem aplicar multiplicadores novamente ao alternar armas.

Preços crescem por nível. Interface mostra nível atual, efeito seguinte, custo e estado MÁXIMO. Não há invulnerabilidade permanente, cura automática infinita ou melhorias infinitas. Atingir o teto não encerra a partida: sobreviver passa a depender de movimento, recursos e escolha de alvos.

## Inimigos e dificuldade

Introduzir tipos gradualmente, mantendo cada um reconhecível por silhueta, cor, animação e sinalização de ataque:

| Tipo | Primeira horda | Comportamento e resposta do jogador |
| --- | --- | --- |
| Errante | 1 | Pressão corpo a corpo; manter distância |
| Corredor | 3 | Aproximação rápida, pouca resistência; priorizar e usar gargalos |
| Cuspidor | 5 | Projétil telegrafado e poça ácida temporária; sair da área |
| Demolidor | 7 | Investida anunciada e dano elevado em barricadas; desviar lateralmente |
| Gritador | 9 | Fortalece temporariamente aliados próximos; eliminar a fonte |
| Volátil | 12 | Aproximação seguida de explosão anunciada; afastar-se antes da detonação |

Progressão combina quantidade, proporção de especiais, ritmo de surgimento e aumentos moderados de atributos. Velocidade tem teto para preservar a possibilidade de esquiva. Manter inicialmente o teto de 30 inimigos simultâneos, com fila de spawn; aumentar somente mediante evidência de desempenho. Spawns ficam em posições navegáveis próximas da região do jogador, fora de sua área imediata, evitando minutos de caminhada de inimigos vindos da borda distante.

## Chefes

Um chefe obrigatório a cada dez hordas, contado pelo diretor de hordas. A rodada só termina quando o chefe, inimigos vivos e fila de spawn forem resolvidos.

- Horda 10: **Carrasco**, com investida, golpe de área e fase de recuperação que permite contra-ataque.
- Horda 20: **Matriarca**, com projéteis ácidos, zonas contaminadas e invocação limitada de criaturas.
- Horda 30: **Aberração**, com feixe direcional anunciado, descargas em áreas marcadas e mudança de fase em metade da vida.
- Hordas 40 em diante repetem o ciclo, com pressão crescente e limites de velocidade e invocações.

Exibir nome, vida e aviso da chegada. Ataques fortes têm antecipação visual e tempo de esquiva. Invocações respeitam o limite global e entram na contagem da horda; não podem bloquear sua conclusão. Chefes possuem recompensa superior, recebida uma única vez.

## Arquitetura e integração

Manter Health, Weapon, Player, AgentBrain, Enemy, WaveDirector, Game, World e HUD como pontos de integração existentes. Extrair catálogo de armas/inimigos/upgrades, economia/progressão, estações de interação, barricadas e efeitos de combate para módulos focados.

Game coordena a partida e eventos, mas não deve concentrar catálogos e lógica de todas as habilidades. World monta módulos urbanos, colisões, locais de interação e pontos de spawn. Player executa intenção e combate; regras de custo e limites permanecem testáveis sem UI. Enemy compartilha movimentação/percepção e delega ataques especiais. HUD apresenta saldo, arma/reserva, interação próxima, upgrades, chefe e mapa.

Planejar navegação de barricadas sem rebake completo por reparo: pontos de entrada e alvos de defesa explícitos, remoção de colisão ao destruir e verificação com física real. Pausa congela temporizadores de habilidades, projéteis e efeitos; reinício remove drops, perigos, barricadas e modificadores da partida anterior.

## Entrega e validação

Implementar em fatias integradas: cidade/câmera/interiores; economia/arsenal/upgrades/barricadas; inimigos/chefes/diretor; acabamento e balanceamento. Todas pertencem à expansão solicitada.

Executar importação headless e as suítes existentes, adaptando somente expectativas alteradas intencionalmente. Adicionar testes de regras para compras sem saldo, compra duplicada, limites, troca de armas, munição, dano e conclusão de hordas com chefes. Integração deve verificar tiros bloqueados por paredes, rotas de interiores, ataque/destruição de barricadas, spawns seguros, pausa e reinício completos.

Validar graficamente câmera, oclusão, leitura de ataques, interiores, HUD e cenário com 30 agentes. Registrar tempos/FPS medidos e limitações, sem prometer desempenho antes da medição. Documentar controles, novos sistemas e como executar. Exportar Windows se a engine e os templates estiverem disponíveis; a validação no editor continua obrigatória.
