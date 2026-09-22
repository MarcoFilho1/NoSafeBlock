# Validação do MVP — 2026-09-21

## Ambiente e escopo

Godot `4.6.1.stable.official.14d19694e`, macOS Apple Silicon, renderer Compatibility/OpenGL (Apple M5). Engine baixada do repositório oficial `godotengine/godot-builds`. Sem plugins ou assets externos. A engine e os templates de exportação são ferramentas locais, não arquivos versionados do jogo.

## Evidência automatizada

Comando: `GODOT_BIN=/caminho/Godot.app/Contents/MacOS/Godot bash scripts/test.sh`.

| Suíte | Cobertura |
|---|---|
| `test_rules.gd` | 78 verificações: HP, morte única, munição, recarga parcial, cadência, FSM, hordas pendentes, spawn seguro e limite de população |
| `test_presentation.gd` | 2 verificações: orientação da pistola e rotação do personagem |
| `test_ui.gd` | 4 verificações: vida, munição, instruções e áudio dentro do viewport 1280×800 |
| `test_controls.gd` | 5 verificações: pausa com botão pressionado, novo clique, perda de foco, botão direito e postura de foco |
| `test_integration.gd` | 942 verificações com cena e física reais: WASD nas quatro direções, paredes, raycast, morte/pontos únicos, rotas de todos os spawns, contorno de prédio, cooldown, pausa, game over, três reinícios, segunda horda, obstáculo estreito, 30 agentes e pares sem sobreposição no spawn |

Resultado final: cinco suítes, **1.031 verificações, zero falhas e zero avisos da engine**. O runner rejeita `SCRIPT ERROR`, `ERROR` e `WARNING`, além de códigos de saída não-zero. Comparações entre pares na prova de 30 agentes explicam a quantidade alta de verificações; não representam centenas de cenários independentes.

## Evidência gráfica

Inspeção da aplicação nativa: menu, partida, disparo e pausa. Capturas geradas pela cena real em `builds/screenshots/`: `menu.png`, `gameplay-30-agents.png`, `agents-debug.png`, `game-over.png`.

O cenário gráfico com 30 agentes foi executado com renderização real, não headless. Uma amostra registrou 83 FPS e `TIME_PROCESS` mediano de 22,03 ms / p95 de 25,93 ms. São métricas pontuais da engine nesta máquina, coletadas por mecanismos diferentes; não equivalem a benchmark sustentado ou garantia para outros equipamentos. O modo de depuração desenha raios e caminhos de todos os agentes e tem custo adicional.

## Revisão independente e regressões

Um revisor independente leu a implementação e executou as cinco suítes. Dois achados foram reproduzidos como falhas e corrigidos:

1. Inimigo em alcance de ataque, mas separado por uma árvore: a decisão agora exige linha de visão para atacar e continua navegando quando o ataque está bloqueado.
2. Traço de tiro deslocado da arma: o tiro agora parte da posição real do cano; uma checagem entre corpo e cano impede atravessar paredes quando a arma se projeta além da colisão.

Também foi corrigida a telemetria de patrulha para mostrar seu alvo real. Regressões anteriores cobrem painéis fora da tela, orientação da pistola, aceitação dos pontos da NavMesh, spawn sobreposto e retorno da pausa com o mouse pressionado.

## Builds

- macOS universal: exportação release, pacote `.app`, assinatura ad hoc verificada, execução headless do binário exportado e abertura gráfica do aplicativo independente; menu, início, F1, morte por ataques, Game Over, reinício, pausa e retorno ao menu conferidos na build. Distribuição pública ainda requer a estratégia de assinatura/notarização da equipe.
- Windows x86_64: exportação release pelo preset. Execução em Windows **não validada** neste ambiente macOS.
- CI: workflow versionado para importação e testes Linux; execução no GitHub **não verificada**, pois esta entrega não publicou branches.

## Limites e integração

- Implementado: um Walker, uma pistola, loop completo e apresentação procedural. Tipos adicionais, armas, upgrades e coop não fazem parte desta entrega.
- Não foi feita sessão manual prolongada de vários minutos nem auditoria de acessibilidade ou de todas as proporções de tela. Recomenda-se playtest de balanceamento pela equipe.
- O plano original exige funcionamento em `develop` para considerar a entrega integrada. Esta implementação permanece em `feature/zombie-survival-mvp`; `develop` e `main` não receberam merge, e nenhuma branch foi publicada.
- A validação local não substitui aprovação da equipe, teste Windows ou execução futura do CI.

## Referências técnicas

- [Godot 4.6.1 oficial](https://godotengine.org/download/archive/4.6.1-stable/)
- [NavigationAgent3D: pontos de caminho e offset vertical](https://docs.godotengine.org/en/4.6/classes/class_navigationagent3d.html)
- [Exportação macOS](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_macos.html)
