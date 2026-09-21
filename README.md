# No Safe Block

Jogo acadêmico de sobrevivência arcade em um quarteirão 3D isométrico, desenvolvido com auxílio de agentes de IA. O jogador enfrenta hordas de zumbis autônomos; percepção, decisão e ação são demonstráveis no próprio jogo.

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
| Pausar / continuar | Esc |
| Inspecionar agentes | F1 |
| Alternar áudio | M |
| Navegar pelos menus | Tab / Shift+Tab / Enter ou mouse |

A pistola tem 12 tiros por pente e reserva ilimitada. Recarregar leva 1,4 s e bloqueia disparos. Tiros sem foco têm dispersão; com foco, não. O jogador começa com 100 HP. Cada Walker eliminado vale 10 pontos. As hordas começam com 5 inimigos e crescem em 3 a cada rodada; no máximo 30 ficam ativos simultaneamente.

Ao perder o foco da janela, o jogo pausa. Depois de iniciar ou retomar uma partida, solte os botões do mouse antes de disparar/focar novamente, evitando que o clique no menu dispare a arma.

## Agentes e arquitetura

Cada Walker tem estado independente: `IDLE → PATROL → CHASE → ATTACK → DEAD`. A percepção considera distância e audição de tiros. O agente perde o alvo distante, patrulha, recalcula rotas em intervalos de 0,3 s e respeita o intervalo de ataque de 1 s. Ataques e tiros não atravessam paredes. O corpo usa colisão física; `NavigationAgent3D` segue a malha calculada a partir das colisões do mapa.

F1 mostra estado, alvo, distância, HP, área de percepção, caminho, contagem de agentes e FPS. Isso permite explicar percepção → decisão → ação na apresentação.

| Área | Arquivos principais |
|---|---|
| Vida e morte | `src/core/health.gd` |
| Jogador, mira, raycast e arma | `src/player/` |
| FSM e execução do Walker | `src/enemies/` |
| Hordas, ciclo de partida, pontuação, áudio | `src/systems/` |
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

As cinco suítes executam regras, apresentação, layout, controles e integração com física e navegação reais. O runner falha também em erros ou avisos da engine. O workflow `.github/workflows/validate.yml` executa importação e testes em PRs para `develop`/`main` e pushes de desenvolvimento.

Instale os **export templates 4.6.1** pelo menu Editor → Manage Export Templates. Depois:

```sh
mkdir -p builds/windows
godot --headless --path . --export-release macOS builds/NoSafeBlock-macOS.zip
godot --headless --path . --export-release "Windows Desktop" builds/windows/NoSafeBlock.exe
```

Capturas e teste gráfico com 30 agentes:

```sh
godot --path . --script tests/capture_visuals.gd
```

Saída: `builds/screenshots/`. Esse cenário automatizado mantém o jogador invulnerável apenas no script de teste; não representa uma partida normal nem altera o jogo distribuído. A build macOS usa assinatura ad hoc, sem notarização Apple; distribuição pública exige configurar assinatura/notarização apropriadas.

## Trabalho em equipe

Siga [CONTRIBUTING.md](CONTRIBUTING.md): `feature/* → PR → develop → validação → PR → main`. O código desta entrega fica na feature até a revisão da equipe; não confunda implementação local com integração publicada.

As quatro frentes sugeridas são Jogador, Agentes, Sistemas e Mundo/Interface. Atribuam os nomes dos integrantes no PR ou nas issues; não há nomes fornecidos no plano para preencher aqui.

Requisitos originais: [plano de desenvolvimento](plano_desenvolvimento_zombie_survival.md). Decisões: [design](docs/design.md). Evidências: [validação](docs/validation.md).

Runner, Tank, Flanker, novas armas, upgrades e coop continuam fora deste MVP. Não há fome, sede, crafting ou inventário complexo.
