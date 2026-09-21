# No Safe Block Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** entregar o MVP desktop jogável descrito no plano original.

**Architecture:** componentes Godot pequenos, regras determinísticas desacopladas da apresentação. Cena principal coordena mundo, player, agentes e HUD por sinais.

**Tech Stack:** Godot 4.6.1 standard e GDScript; sem plugins.

**Spec:** `docs/design.md` e `plano_desenvolvimento_zombie_survival.md`.

## Global Constraints

- Apenas feature branch baseada em develop; nenhum commit em main.
- Um Walker funcional antes de opcionais; mapa pequeno e 3D real.
- Munição, recarga, foco e animações fazem parte do MVP.
- Morte encerra efeitos de gameplay; restart limpa todo estado da partida.

## Review Focus

- Tiros através de paredes: integração deve provar oclusão.
- Perda de foco/pausa segurando botões: nenhuma ação deve continuar.
- Spawn próximo e inimigos presos: validar distância e caminhos de todos os pontos.
- Última morte com spawn pendente: não iniciar horda antes de concluir emissão.
- Restart repetido: vida, pontuação, munição, agentes e timers retornam ao início.

### Task 1: Regras e fundação

Files: `project.godot`, `src/core/health.gd`, `src/player/weapon.gd`, `src/enemies/agent_brain.gd`, `src/systems/wave_director.gd`, `tests/test_rules.gd`.

Interfaces: `Health.damage(amount)`, `Weapon.fire()/reload()/tick(delta)`, `AgentBrain.decide(distance, alive, alerted)`, `WaveDirector.start_next()/register_spawn()/register_kill()/is_clear()`.

- [x] Testar morte única, dano negativo ignorado, recarga parcial, spam de disparos, limite de munição, estados e horda pendente usando SceneTree headless.
- [x] Executar `godot --headless --path . --script tests/test_rules.gd`; primeiro falha por componentes ausentes.
- [x] Implementar regras e rodar até saída 0 sem erros.
- [x] Commit `feat: add tested survival rules and Godot project`.

### Task 2: Mundo, jogador e agentes

Files: `scenes/main.tscn`, `src/world/world.gd`, `src/world/props.gd`, `src/player/player.gd`, `src/enemies/enemy.gd`, `src/visuals/actor_visual.gd`, `tests/test_integration.gd`.

Interfaces: `World.spawn_points`, `World.navigation_ready`; `Player.health/weapon`, `Player.shoot_at(target)`; `Enemy.setup(player)`, `Enemy.health/brain`, `Enemy.eliminated(points)`.

- [x] Testar cena real: movimento bloqueado em parede, tiro bloqueado por prédio, tiro causa morte e pontuação única, agente contorna obstáculo e alcança jogador.
- [x] Implementar mundo low-poly, CharacterBody3D, física, mira, foco, animações e NavMesh.
- [x] Rodar testes de regras e integração; importar projeto no editor sem erros.
- [x] Commit `feat: add isometric world player combat and navigating Walker agents`.

### Task 3: Partida completa e apresentação

Files: `src/systems/game.gd`, `src/ui/hud.gd`, `src/ui/reticle.gd`, `src/systems/audio.gd`, `tests/test_integration.gd`.

Interfaces: `Game.start_game()/show_menu()/set_paused(value)`, `Game.state/player/enemies/score/waves`; `HUD` emite `play_requested/menu_requested/resume_requested/quit_requested`; `Audio.play_cue(kind)`.

- [x] Testar início, hordas, spawn seguro, pausa, morte, reinício repetido e 30 agentes reais.
- [x] Implementar menu, HUD, retículo, game over, áudio e F1.
- [x] Executar jogo graficamente e verificar controles e legibilidade.
- [x] Commit `feat: complete survival waves menus audio and gameplay regression coverage`.

### Task 4: Entrega e revisão

Files: `README.md`, `CONTRIBUTING.md`, `export_presets.cfg`, `.github/workflows/validate.yml`, `docs/validation.md`.

- [x] Rodar testes headless e build macOS; abrir executável gerado.
- [x] Documentar uso, instalação, responsabilidades, contratos, Git Flow e resultados reais.
- [x] Revisão independente da branch, corrigir achados importantes com regressões.
- [x] `git diff --check`; commits finais; registrar status de integração sem afirmar merge não realizado.

## Registro de execução

- Engine escolhida como decisão delegada pelo usuário: Godot/GDScript, uma implementação apenas. Trocar de engine exigiria nova implementação; escolha documentada antes do código.
- Trabalho no checkout atual em feature branch: não havia alterações rastreadas de colegas; o plano não rastreado foi preservado e versionado integralmente. Nenhuma worktree adicional ou merge automático.
- Fundações, mundo e loop entregues em commits separados. Os testes reais de integração exigem a cena e o coordenador juntos; sua suíte acompanha o commit do loop.
- Revisão independente: dois achados funcionais reproduzidos, corrigidos e cobertos por testes; telemetria de patrulha também corrigida. Resultado e limitações em `docs/validation.md`.
- Integração em develop e publicação remota dependem da revisão/aprovação da equipe; não fazem parte dos commits locais de implementação.
