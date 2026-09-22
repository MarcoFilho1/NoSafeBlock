# Validação da expansão urbana — 2026-09-21

## Ambiente e escopo

Godot `4.6.1.stable.official.14d19694e`, Windows, renderer Compatibility/OpenGL (AMD Radeon(TM) Graphics). Sem plugins ou assets externos. A engine é uma ferramenta local, não um arquivo versionado do jogo.

## Evidência automatizada

Comando: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test.ps1`.

| Suíte | Cobertura |
|---|---|
| `test_rules.gd` | 78 verificações: HP, morte única, munição, recarga parcial, cadência, FSM, hordas pendentes, spawn seguro e limite de população |
| `test_presentation.gd` | 2 verificações: orientação da pistola e rotação do personagem |
| `test_ui.gd` | 4 verificações: vida, munição, instruções e áudio dentro do viewport 1280×800 |
| `test_controls.gd` | 5 verificações: pausa com botão pressionado, novo clique, perda de foco, botão direito e postura de foco |
| `test_integration.gd` | 1.079 verificações com cena e física reais: WASD, paredes, raycast, mortes/pontos, rotas, cooldown, pausa, reinício, segunda horda, obstáculos e 30 agentes |
| `test_city.gd` | Cinco distritos, 11 interiores com saída alternativa e rotas reais pela NavMesh |
| `test_progression.gd` e `test_arsenal.gd` | Saldo atômico, tetos, melhorias, recarga parcial e troca de armas |
| `test_defenses.gd`, `test_effects.gd` e `test_combat.gd` | Barricadas, dano inválido, pausas, cura, explosões e oclusão por paredes |
| `test_enemies.gd`, `test_bosses.gd` e `test_expansion.gd` | Desbloqueio de tipos, chefes, população máxima, compras e reset completo |
| `test_navigation_recovery.gd` | Recuperação de rota após colisão com obstáculo |

Resultado final: 15 suítes, **zero falhas e zero avisos da engine**. O runner rejeita `SCRIPT ERROR`, `ERROR` e `WARNING`, além de códigos de saída não-zero.

## Evidência gráfica

Inspeção da aplicação nativa: menu, partida, compras, interior, barricada e chefes. Capturas geradas pela cena real em `builds/screenshots/`: cinco distritos, interior defendido, 30 inimigos, Carrasco, Matriarca e Aberração.

O cenário gráfico com 30 inimigos foi executado com renderização real, não headless. A cidade ficou pronta em 2.083 ms; uma amostra registrou 40 FPS e `TIME_PROCESS` mediano de 31,34 ms / p95 de 75,05 ms. São métricas pontuais, não uma garantia para outros equipamentos.

## Revisão independente e regressões

Um revisor independente leu a implementação e executou as cinco suítes. Dois achados foram reproduzidos como falhas e corrigidos:

1. Inimigo em alcance de ataque, mas separado por uma árvore: a decisão agora exige linha de visão para atacar e continua navegando quando o ataque está bloqueado.
2. Traço de tiro deslocado da arma: o tiro agora parte da posição real do cano; uma checagem entre corpo e cano impede atravessar paredes quando a arma se projeta além da colisão.

Também foi corrigida a telemetria de patrulha para mostrar seu alvo real. Regressões anteriores cobrem painéis fora da tela, orientação da pistola, aceitação dos pontos da NavMesh, spawn sobreposto e retorno da pausa com o mouse pressionado.

## Builds

- Windows x86_64: preset presente, mas não exportado porque os templates 4.6.1 não estavam instalados neste ambiente.
- macOS universal: não revalidado nesta expansão.
- CI: workflow versionado; execução remota não foi verificada porque nenhuma branch foi publicada.

## Limites e integração

- Implementado: cidade urbana, nove armas, compras, upgrades limitados, barricadas, itens, seis tipos de inimigo, chefes recorrentes, minimapa e apresentação procedural. Coop, crafting, fome e sede não fazem parte desta entrega.
- Não foi feita sessão manual prolongada de vários minutos nem auditoria de acessibilidade ou de todas as proporções de tela. Recomenda-se playtest de balanceamento pela equipe.
- Esta implementação permanece em `feature/city-survival`; `develop` e `main` não receberam merge, e nenhuma branch foi publicada.
- A validação local não substitui aprovação da equipe, teste Windows ou execução futura do CI.

## Referências técnicas

- [Godot 4.6.1 oficial](https://godotengine.org/download/archive/4.6.1-stable/)
- [NavigationAgent3D: pontos de caminho e offset vertical](https://docs.godotengine.org/en/4.6/classes/class_navigationagent3d.html)
- [Exportação macOS](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_macos.html)
