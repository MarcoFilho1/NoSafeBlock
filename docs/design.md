# No Safe Block — decisões do MVP

Autoridade funcional: `plano_desenvolvimento_zombie_survival.md`.

## Escolhas

- Godot 4.6.1 standard, GDScript, renderer Compatibility, desktop com teclado e mouse.
- Uma única implementação. A equipe declarou não ter preferência entre Unity e Godot.
- Mundo 3D pequeno, câmera ortográfica fixa em perspectiva isométrica, arte original feita de primitivas low-poly. Sem downloads de assets ou plugins.
- WASD relativo à tela; mouse orienta arma; esquerdo dispara; direito concentra, reduz dispersão e velocidade, muda postura e retículo; R recarrega; Esc pausa; F1 mostra agentes.
- Pistola: 12 tiros, recarga de 1,4 s, reserva ilimitada explicitamente indicada na interface, 34 de dano, intervalo de 0,24 s. Sem acessórios.
- Jogador: 100 HP; colisões físicas; animações procedurais de andar, focar, tiro, dano e morte.
- Walker: 68 HP, 10 pontos, ataque de 10 a cada 1 s; IDLE, PATROL, CHASE, ATTACK, DEAD. Percepção por distância e audição de tiros. Caminho via NavigationAgent3D/NavMesh; obstáculos bloqueiam movimento e tiros.
- Hordas crescentes a partir de 5 inimigos, emissão escalonada, máximo de 30 vivos, spawns distantes do jogador. Intervalo entre hordas e game over interrompem ações.
- Menu, HUD, pausa, Game Over, replay e retorno ao menu. Áudio sintetizado original, com mute. F1: estados, percepção, rota, alvo, distância, FPS e contagem.
- Primeiro entregar Walker e loop completo. Outros tipos, armas, upgrades, multiplayer e sistemas de sobrevivência ficam fora desta entrega.

## Componentes e contratos

`Health` emite `changed` e `died` uma única vez. `Weapon` controla munição e tempo; `Player` coordena movimento, mira e raycast. `AgentBrain` decide estados sem depender da cena; `Enemy` executa percepção, navegação e ataque. `WaveDirector` controla contagem e spawn pendente; `Game` possui estado global, pontuação e ciclo de vida das cenas. `World` constrói cenário e malha de navegação uma vez. `HUD` só apresenta estado e emite intenções. `ActorVisual` e `Audio` são apresentação.

## Git Flow e colaboração

Base conferida: `origin/main` no commit `11d0892`; nenhuma outra branch remota em 2026-09-21. Criar `develop` dessa base e `feature/zombie-survival-mvp` de `develop`. Trabalhar em commits pequenos na feature; integração por PR para `develop`, seguida de validação e promoção para `main`. Não fazer merge ou push para branches compartilhadas automaticamente. O plano fornecido será versionado sem alterar seu conteúdo.

## Validação

Testes headless de vida, munição, cooldown, estados, hordas e spawns. Teste de integração com cena real para colisões, raycast, navegação, morte, reinício e 30 agentes. Importação do editor, execução gráfica e captura visual. Build macOS local executável; preset Windows disponível, validação Windows depende dessa plataforma. Registrar evidência e limitações em `docs/validation.md`.
