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

# Validação das melhorias gráficas — 2026-09-22

## Ambiente e escopo

Godot `4.6.1.stable.official.14d19694e`, Windows 11, renderer Compatibility/OpenGL. Branch `feature/melhorias-graficas`, rebaseada sobre `feature/agente-flanker` em `51b1c77`. A base é a branch de feature mais avançada do repositório: `develop` ainda contém apenas o README, então não havia base integrada disponível. Escopo: apresentação apenas — kit de primitivas, fachadas, telhados, mobiliário urbano, veículos, árvores e extremidades dos atores. Nenhuma regra, rota ou contrato de agente foi alterado.

## Evidência automatizada

As 15 suítes foram executadas antes e depois da mudança, com o mesmo binário:

| Momento | Resultado |
|---|---|
| Base (`feature/agente-flanker`) | 15 suítes, 0 falhas, 0 avisos |
| Depois das melhorias | 15 suítes, 0 falhas, 0 avisos |

`test_city.gd` continua aprovando as rotas reais pela NavMesh até os 11 interiores e `test_integration.gd` mantém as 1.079 verificações, o que sustenta a decisão de manter todo o mobiliário novo sem colisão.

## Evidência gráfica e custo

`tests/capture_visuals.gd` passou a imprimir também o que a câmera realmente paga por quadro. Cena de 30 agentes, mesma máquina, execução gráfica:

| Medida | Base | Depois | Variação |
|---|---|---|---|
| Objetos no quadro | 2.173–2.265 | 2.702–2.830 | +24% a +25% |
| Primitivas no quadro | 47.168–49.516 | 60.816–66.276 | +29% a +34% |
| Draw calls | 1.916–2.008 | 2.445–2.573 | +28% |
| FPS | 138–144 | 129–137 | −5% |

O `TIME_PROCESS` mediano oscilou entre 7 ms e 57 ms na mesma branch em execuções consecutivas, então não serve como comparação; os contadores de renderização e o FPS são as medidas usadas aqui. São métricas pontuais de um equipamento, não uma garantia.

O ganho de geometria é bem maior que os 25% que chegam ao quadro: quase todo o detalhe novo está fora do alcance de `DETAIL_RANGE` na maior parte do tempo e nenhum dele entra no passe de sombra.

## Limites

- Não houve sessão manual prolongada nesta entrega; o fluxo manual completo do critério de aceite continua sendo responsabilidade da revisão.
- Não foi medido desempenho em outras máquinas, nem em resoluções diferentes de 1280 × 800.
- O posto de combustível `SUNSET / FUEL` continua sobreposto ao quarteirão vizinho, como já estava antes desta mudança. As colunas novas da cobertura são decorativas e não corrigem essa sobreposição de layout.
- Nenhuma branch foi promovida: a integração em `develop` depende de revisão da equipe.
