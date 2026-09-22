# No Safe Block

Jogo acadêmico de sobrevivência arcade em uma cidade 3D isométrica. O jogador enfrenta hordas de zumbis autônomos, explora cinco distritos, fortalece o personagem e compra recursos durante a partida.

**Engine: Godot 4.6.1 standard · Linguagem: GDScript · Plataforma: desktop com teclado e mouse.**

## Jogar

Na entrega local, abra `builds/macos/No Safe Block.app`, ou descompacte `builds/NoSafeBlock-macOS.zip` e abra o aplicativo. A build funciona sem editor. O executável Windows é `builds/windows/NoSafeBlock.exe`; a exportação pode ser feita no macOS, mas a execução precisa ser validada em Windows.

As builds são locais e ignoradas pelo Git. Não são baixadas ao clonar o repositório.

Para executar a partir do código:

1. Instale [Godot 4.6.1 standard](https://godotengine.org/download/archive/4.6.1-stable/) (não é necessária a edição .NET).
2. Importe `project.godot` no gerenciador de projetos.
3. Pressione **F6** com `scenes/main.tscn` aberta, ou **F5** para executar o projeto.
4. Escolha **INICIAR PARTIDA**.

Pelo terminal, com o executável Godot no PATH:

```sh
godot --path .
```

## Controles

| Ação | Controle |
|---|---|
| Movimento relativo à tela | WASD |
| Mira e rotação | Mouse |
| Disparo | Botão esquerdo; pode manter pressionado |
| Foco: precisão máxima, postura e retículo diferentes, movimento mais lento | Segurar botão direito |
| Recarregar | R |
| Interagir, comprar ou reparar | E |
| Alternar arma | 1 / 2 ou roda do mouse |
| Lançar granada | G |
| Pausar / continuar | Esc |
| Inspecionar agentes | F1 |
| Alternar áudio | M |
| Navegar pelos menus | Tab / Shift+Tab / Enter ou mouse |

A pistola inicial tem 12 tiros e reserva ilimitada. As demais armas usam reserva limitada, recarregável em estações. A partida começa com 100 HP, e upgrades limitados podem elevar vida, resistência, velocidade, recarga e dano das armas. O saldo é ganho ao eliminar hostis e sobreviver a hordas; ele é separado da pontuação total e paga compras e reparos. As hordas começam com 5 inimigos, crescem em 3 por rodada e mantêm no máximo 30 inimigos ativos.

Ao perder o foco da janela, o jogo pausa. Depois de iniciar ou retomar uma partida, solte os botões do mouse antes de disparar/focar novamente, evitando que o clique no menu dispare a arma.

## Cidade, defesa e arsenal

A cidade mede 180 × 180 unidades e reúne Centro, Palm Heights, Iron Yard, Sunset Avenue e Zona Zero. Há lojas, apartamentos, clínica, delegacia, motel, galpões, posto e laboratório, com 11 interiores que possuem duas saídas. O minimapa mostra posição, distritos e estações descobertas.

Barricadas podem ser construídas ou reparadas nas entradas marcadas. Elas têm três estágios de integridade, bloqueiam tiros e movimentação, e os zumbis atacam a barreira até abrir a passagem. Não existe posição permanentemente segura: cada interior possui rotas alternativas.

O arsenal inclui pistola de serviço, pistola pesada, submetralhadora, calibre 12, fuzil, rifle de precisão, metralhadora leve, emissor de plasma e projetor elétrico. O plasma causa dano em área; o projetor elétrico encadeia para até três inimigos expostos. Cada partida permite duas armas carregadas; comprar uma terceira substitui a arma ativa. Kits médicos, colete e granadas são comprados em estações. Munição e cura também podem cair de inimigos abatidos.

## Ameaças e chefes

Além do Errante, as hordas liberam Corredor, Cuspidor, Demolidor, Gritador e Volátil. Seus ataques têm sinais visuais antes de causar dano: ácido, investida, fortalecimento de aliados e explosão.

Um chefe entra a cada dez hordas: Carrasco na 10, Matriarca na 20 e Aberração na 30; o ciclo se repete. Chefes possuem barra de vida, ataques anunciados e recompensas únicas. A rodada só termina depois do chefe, das invocações e dos demais inimigos.

## Agentes e arquitetura

Cada inimigo mantém estados independentes: `IDLE → PATROL → CHASE → ATTACK → DEAD`. A percepção considera distância e audição de tiros. Inimigos especiais acrescentam fases anunciadas de habilidade. Ataques, explosões e corrente elétrica respeitam paredes; o corpo usa colisão física e `NavigationAgent3D` segue a malha gerada das colisões do mapa.

F1 mostra estado, alvo, distância, HP, área de percepção, caminho, contagem de agentes e FPS. Isso permite explicar percepção → decisão → ação na apresentação.

| Área | Arquivos principais |
|---|---|
| Vida e morte | `src/core/health.gd` |
| Jogador, mira, raycast e arma | `src/player/` |
| FSM, tipos e chefes | `src/enemies/` |
| Hordas, economia, ciclo de partida e áudio | `src/systems/` |
| Construção do mapa e objetos | `src/world/` |
| Animações procedurais | `src/visuals/actor_visual.gd` |
| Menus, HUD, retículo | `src/ui/` |
| Cena de entrada | `scenes/main.tscn` |

O mundo e os personagens são construídos em código com primitivas Godot. A cena de entrada é pequena por decisão de integração: os colaboradores podem editar módulos distintos sem disputar um arquivo de cena gigante. Não há plugins, modelos, texturas ou pacotes de áudio externos; os sons são sintetizados localmente.

## Testes e builds

```sh
godot --headless --path . --editor --import
bash scripts/test.sh
```

Para apontar para um binário fora do PATH:

```sh
GODOT_BIN="/caminho/Godot.app/Contents/MacOS/Godot" bash scripts/test.sh
```

As 15 suítes executam regras, apresentação, layout, controles, integração, cidade, progressão, arsenal, barricadas, efeitos, inimigos, chefes, expansão, recuperação de navegação e combate com física real. O runner falha também em erros ou avisos da engine.

Instale os **export templates 4.6.1** pelo menu Editor → Manage Export Templates. Depois:

```sh
mkdir -p builds/windows
godot --headless --path . --export-release macOS builds/NoSafeBlock-macOS.zip
godot --headless --path . --export-release "Windows Desktop" builds/windows/NoSafeBlock.exe
```

Capturas e teste gráfico com 30 agentes:

```sh
godot --path . --script tests/capture_expansion.gd
```

Saída: `builds/screenshots/`. Esse cenário automatizado mantém o jogador invulnerável apenas no script de teste; não representa uma partida normal nem altera o jogo distribuído. A build macOS usa assinatura ad hoc, sem notarização Apple; distribuição pública exige configurar assinatura/notarização apropriadas.

## Trabalho em equipe

Siga [CONTRIBUTING.md](CONTRIBUTING.md): `feature/* → PR → develop → validação → PR → main`. O código desta entrega fica na feature até a revisão da equipe; não confunda implementação local com integração publicada.

As quatro frentes sugeridas são Jogador, Agentes, Sistemas e Mundo/Interface. Atribuam os nomes dos integrantes no PR ou nas issues; não há nomes fornecidos no plano para preencher aqui.

Requisitos originais: [plano de desenvolvimento](plano_desenvolvimento_zombie_survival.md). Decisões: [design](docs/design.md). Evidências: [validação](docs/validation.md).

Cooperação, crafting, fome e sede continuam fora do escopo. A expansão preserva partidas individuais rápidas, sem inventário complexo.
