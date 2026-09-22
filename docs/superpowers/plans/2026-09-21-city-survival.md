# City Survival Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar a expansão urbana aprovada, com exploração, barricadas, arsenal, progressão limitada e hordas com especiais e chefes.

**Architecture:** Preservar os módulos Godot existentes e introduzir catálogos de dados, estado de progressão por partida e componentes de interação/combate. Layout urbano fixo fornece geometria, interiores e pontos de interesse; Game conecta eventos sem concentrar a implementação das habilidades.

**Tech Stack:** Godot 4.6.1 standard, GDScript, renderer Compatibility, Windows desktop, testes SceneTree headless.

**Spec:** `docs/superpowers/specs/2026-09-21-city-survival-design.md` — aprovado pelo usuário em 2026-09-21.

## Global Constraints

- Preservar Godot 4.6.1, GDScript, desktop, câmera isométrica e arte procedural low-poly.
- A progressão é por partida e reinicia ao morrer.
- Duas armas carregadas, alternadas por 1/2 ou roda do mouse.
- Manter inicialmente o teto de 30 inimigos simultâneos, com fila de spawn.
- Comprar é uma interação no mundo e não pausa as hordas.
- Não há invulnerabilidade permanente, cura automática infinita ou melhorias infinitas.
- Não publicar ou integrar branches compartilhadas automaticamente; preservar alterações do usuário.

## Review Focus

1. Comprar com saldo exato, saldo insuficiente ou identificador inválido: a transação inteira ocorre uma única vez ou não altera nada (tarefa 2).
2. Trocar arma durante recarga e recomprar arma possuída: não duplicar munição, upgrades ou multiplicadores (tarefa 3).
3. Destruir/reconstruir entrada com atores próximos: não prender corpos ou deixar inimigos sem caminho (tarefa 4).
4. Invocar criaturas quando há 30 ativos ou morrer no mesmo frame: respeitar capacidade e não encerrar/travar a horda (tarefa 7).
5. Pausar/reiniciar durante aviso, explosão ou coleta: nenhum efeito continua ou vaza para a próxima partida (tarefas 5 e 8).

## Execução e ferramentas

O repositório atual está em `feature/expansao_de_dominio`; status inicial contém somente a especificação criada nesta conversa. Não há Godot nem bash disponíveis pelo PATH consultado. Antes da implementação, localizar a instalação local em diretórios de programas/downloads; se ausente, obter a edição standard oficial em diretório de ferramentas do workspace. Não substituir a engine silenciosamente por outra versão.

Usar a habilidade using-git-worktrees no início da execução para decidir isolamento preservando esta branch e os documentos. Git neste ambiente requer `git -c safe.directory=C:/Users/Lenovo/Desktop/Projetos/JOGO/NoSafeBlock ...`; não alterar configuração global por esse motivo.

Nos comandos abaixo, `$engineBin` é o caminho absoluto do executável Godot encontrado. Todas as suítes novas seguem o padrão existente: `extends SceneTree`, contador `failures`, `check(condition, message)` e `quit(1 if failures else 0)`. Testes com cena usam `call_deferred("run")` e aguardam frames de física. Cada bloco de verificação abaixo entra no método de teste correspondente; variáveis `game`, `player`, `enemy` e `world` são instâncias reais de cena, nunca simulações da física.

```powershell
& $engineBin --headless --path . --editor --import
& $engineBin --headless --path . --script tests/test_rules.gd
```

Entregas são sequenciais por dependência. Cada tarefa encerra com importação, sua suíte, revisão do diff e commit local dos arquivos explicitamente alterados. Não criar commits quando validação relevante falhar. O plano completo permanece um único escopo aprovado; as tarefas são fatias testáveis desse escopo.

## Tarefa 1: cidade explorável e câmera

**Arquivos:** criar `src/world/city_layout.gd`, `src/world/city_buildings.gd`, `tests/test_city.gd`; modificar `src/world/world.gd`, `src/world/props.gd`, `src/systems/game.gd`, `tests/test_integration.gd`.

**Interfaces:** CityLayout fornece `static func definition() -> Dictionary`, com `bounds: Rect2`, `districts: Array[Dictionary]`, `buildings: Array[Dictionary]`, `stations: Array[Dictionary]`, `defenses: Array[Dictionary]`, `spawn_points: Array[Vector3]`. Building entries têm `id`, `position`, `size`, `kind`, `enterable`, `entrances: Array[Vector3]`. World mantém `camera`, `navigation_ready`, `spawn_points` e acrescenta `layout: Dictionary`, `follow_target: Node3D`, `reset_match() -> void`. CityBuildings fornece `static func build(parent: Node3D, definition: Dictionary) -> Node3D`.

- [ ] Criar teste do layout e verificar sua falha antes do módulo existir:
  ```gdscript
  var layout = load("res://src/world/city_layout.gd").definition()
  check(layout.bounds.size == Vector2(180, 180), "Área aprovada")
  check(layout.districts.size() == 5, "Cinco setores")
  var accessible = layout.buildings.filter(func(b): return b.enterable)
  check(accessible.size() >= 6, "Seis interiores")
  for building in accessible:
      check(building.entrances.size() >= 2, "Interiores com saídas alternativas")
  ```
- [ ] Construir ruas nos eixos -60, -30, 0, 30 e 60; limites em ±90. Usar blocos menores que os intervalos entre ruas, passeios, becos e praças. Centro no entorno de zero; residencial a noroeste; indústria a sudoeste; avenida a sudeste; quarentena a nordeste. Gerar posições por dados estáveis, sem randomização de colisões.
- [ ] Montar apartamentos, lojas, clínica, delegacia, lanchonete, posto, motel, galpões e laboratório; interiores com paredes segmentadas nas entradas e mobiliário que conserve passagem de 1,5 unidade. Adicionar ônibus, carros avariados, entulho, janelas partidas e luzes de emergência com poucos focos dinâmicos. Tetos/fachadas ocultadores usam material próprio com transparência ao interceptar a linha câmera–jogador; restaurar ao sair.
- [ ] Seguir o jogador sem mudar os vetores de movimento isométricos. Usar deslocamento de câmera `Vector3(22, 28, 22)` e tamanho ortográfico inicial 30, ajustável pela verificação visual. Para suavização independente de FPS:
  ```gdscript
  camera.global_position = camera.global_position.lerp(
      follow_target.global_position + Vector3(22, 28, 22),
      1.0 - exp(-8.0 * delta))
  ```
- [ ] Fazer bake somente de colisores estáticos; testar rotas reais de todas as entradas e amostra dos spawns ao centro via `NavigationServer3D.map_get_path`. Trocar coordenadas antigas de testes por um obstáculo explícito criado na fixture; preservar verificações de parede, cano e colisão.
- [ ] Executar `tests/test_city.gd` e `tests/test_integration.gd`, inspecionar câmera/interiores graficamente e registrar evidências antes do commit `feat: expand explorable city and follow camera`.

## Tarefa 2: catálogo, saldo e upgrades limitados

**Arquivos:** criar `src/data/weapon_catalog.gd`, `src/data/upgrade_catalog.gd`, `src/systems/progression.gd`, `tests/test_progression.gd`; modificar `src/systems/game.gd`.

**Interfaces:** WeaponCatalog `static func get_definition(id: String) -> Dictionary` retorna cópia ou `{}`; UpgradeCatalog `static func get_definition(id: String) -> Dictionary`. Progression é RefCounted com `balance: int`, `earned: int`, `levels: Dictionary`, `weapon_levels: Dictionary`; `award(amount: int) -> void`, `spend(amount: int) -> bool`, `buy_upgrade(id: String) -> bool`, `buy_weapon_upgrade(id: String) -> bool`, `modifier(id: String) -> float`. Game possui `progression`; `score` continua significando acumulado.

- [ ] Criar e executar teste que falha com ausência do componente:
  ```gdscript
  var p = load("res://src/systems/progression.gd").new()
  p.award(450)
  check(not p.spend(451) and p.balance == 450, "Compra insuficiente é atômica")
  check(p.spend(450) and p.balance == 0 and p.earned == 450, "Saldo separado")
  check(not p.spend(-10), "Custo negativo rejeitado")
  check(not p.buy_upgrade("invalid"), "ID inválido rejeitado")
  p.award(100000)
  for i in range(3):
      check(p.buy_upgrade("health"), "Nível permitido")
  var before = p.balance
  check(not p.buy_upgrade("health") and p.balance == before, "Teto não cobra")
  check(p.modifier("health") == 175.0, "Vida tem teto")
  ```
- [ ] Registrar as nove armas e preços da especificação. Campos: `id`, `name`, `price`, `capacity`, `reserve`, `damage`, `cadence`, `reload_time`, `pellets`, `spread`, `range`, `mode`, `move_multiplier`, `color`. Pistola: 12/ilimitada, 34 dano, 0,24 s cadência, 1,4 s recarga; pesada: 8/48, 75, 0,5, 1,8; SMG: 30/180, 22, 0,09, 1,8; calibre 12: 8/48, 18 por 8 pellets, 0,85, 2,6; fuzil: 30/150, 42, 0,14, 2,1; precisão: 5/35, 210, 1,1, 2,8; metralhadora: 75/225, 36, 0,11, 4,0 e movimento ×0,85; plasma: 12/48, 120, 0,65, 2,8; elétrico: 20/80, 85, 0,35, 2,5. Foco reduz dispersão, não remove abertura própria da espingarda.
- [ ] Implementar débito protegido e ganhos positivos:
  ```gdscript
  func spend(amount: int) -> bool:
      if amount < 0 or amount > balance:
          return false
      balance -= amount
      return true
  ```
  Upgrades custam 750/1500/3000 por atributo, com tetos da especificação; dano por arma custa 1500/3000. Calcular modificadores a partir do nível e da base, nunca do atributo já modificado. Horda concluída concede `100 + 25 * round_number`; mortes comuns mantêm os 10 pontos iniciais até ajuste documentado.
- [ ] Testar todos os quatro tetos, duas melhorias por arma, recompensa negativa e duas tentativas com saldo para apenas uma compra. Executar `tests/test_progression.gd` e `tests/test_rules.gd`; commit `feat: add match economy and capped upgrades`.

## Tarefa 3: arsenal equipado e disparos distintos

**Arquivos:** criar `src/player/loadout.gd`, `src/combat/combat_resolver.gd`, `tests/test_arsenal.gd`; modificar `src/player/weapon.gd`, `src/player/player.gd`, `src/visuals/actor_visual.gd`, `src/systems/audio.gd`.

**Interfaces:** Weapon `_init(id: String = "service_pistol")`, `id: String`, `definition: Dictionary`, `ammo`, `reserve`, `tick(delta)`, `fire() -> bool`, `reload() -> bool`, `refill() -> bool`. Loadout é RefCounted com `slots: Array`, `active_slot: int`, `equip(id: String) -> bool`, `select_slot(index: int) -> bool`, `current() -> RefCounted`; começa com pistola e slot vazio. Player mantém `weapon` como acesso à arma atual, e adiciona `loadout`. CombatResolver `static func fire(player: CharacterBody3D, target: Vector3) -> void`, `static func blast(world: World3D, center: Vector3, radius: float, damage: float, targets: Array) -> void`. Consome catálogo da tarefa 2 e `take_damage(amount)` existente.

- [ ] Criar teste e observar falha:
  ```gdscript
  var kit = load("res://src/player/loadout.gd").new()
  check(kit.equip("shotgun"), "Segunda arma")
  check(kit.slots.size() == 2, "Dois slots")
  check(not kit.equip("shotgun"), "Duplicata não reinicia munição")
  var gun = kit.current()
  gun.fire()
  gun.reload()
  var ammo_before = gun.ammo
  kit.select_slot(0)
  kit.select_slot(1)
  check(kit.current().ammo == ammo_before, "Troca não termina recarga")
  ```
- [ ] Generalizar capacidade/dano/cadência para instância. Usar reserva `-1` somente para pistola; recarga transfere `min(capacity-ammo, reserve)` ao terminar. Arma guardada mantém estado e só avança temporizadores se essa for a regra aplicada consistentemente; escolha inicial: todos os slots avançam em gameplay, nenhum em pausa.
- [ ] Implementar 1/2 e roda, terceiro item substituindo slot ativo; impedir duplicata e ID inválido antes de pagar. Dano final é `definition.damage * (1.0 + 0.2 * upgrade_level)`. Resolver cada pellet por raycast e conservar o teste corpo→cano que impede tiros através da parede. Plasma usa impacto explosivo de raio 3; elétrico encadeia até três alvos distintos a até 5 unidades, ×0,7 por salto, sempre com linha de visão.
- [ ] Dar silhueta/cor de cano, traçador e áudio distintos às famílias de armas. Recarga, dano, reserva e velocidade devem usar a arma atual, sem reconfigurar visual a cada frame desnecessariamente.
- [ ] Verificar reserva zero, recarga parcial, foco da espingarda, melhoria após alternância, tiro em parede e explosão/eletricidade bloqueadas por parede em `tests/test_arsenal.gd`; executar também regras e integração; commit `feat: implement nine weapon loadouts and combat modes`.

## Tarefa 4: estações, interiores defensáveis e barricadas

**Arquivos:** criar `src/world/interaction_station.gd`, `src/world/barricade.gd`, `src/systems/interactions.gd`, `tests/test_defenses.gd`; modificar World, Game, Player e Enemy nos arquivos existentes.

**Interfaces:** Station possui `offer: Dictionary`, `prompt(player, progression) -> String`, `interact(player, progression) -> bool`. Barricade estende StaticBody3D e possui `integrity: float`, `maximum: float = 300.0`, `repair_left: float`, `take_damage(amount: float) -> void`, `repair(progression) -> bool`, `reset_match() -> void`. Interactions `nearest(origin: Vector3, nodes: Array) -> Node`, limitado a 2,5 unidades e linha de visão. World fornece `interactables: Array[Node3D]`, preenchidos a partir do layout.

- [ ] Criar teste que falhe antes da implementação:
  ```gdscript
  var p = load("res://src/systems/progression.gd").new()
  p.award(500)
  var barrier = load("res://src/world/barricade.gd").new()
  root.add_child(barrier)
  check(barrier.repair(p), "Construção")
  var balance_before = p.balance
  check(not barrier.repair(p) and p.balance == balance_before, "Sem spam de reparo")
  barrier.take_damage(1000)
  await physics_frame
  check(barrier.integrity == 0 and barrier.collision_layer == 0, "Passagem liberada")
  ```
- [ ] Distribuir estações de armas, munição e upgrades por setor, com armas avançadas na indústria/quarentena. Interação por E apenas em PLAYING; indicar preço, falta de saldo, máximo e substituição do slot antes da ação. Escolher a estação elegível mais próxima, com desempate estável. Validar elegibilidade inteira antes do débito.
- [ ] Construção custa 100, reparo custa 50 para +100 integridade, intervalo 1 s; não cobrar se cheia ou ocupada por corpo. Visual mostra até três tábuas por integridade restante. Usar colisão de barricada na camada 8 (nomear layer 4 no projeto) e incluir em máscaras de corpo/tiro, excluindo do bake estático. Checar sobreposição física antes de reativar colisão.
- [ ] Inimigo mantém rota até o jogador, detecta barreira física na próxima direção e ataca o bloqueio até destruí-lo; não confundir parede estrutural com barricada. Atualizar mudanças de colisão de forma diferida quando necessário.
- [ ] Testar caminho real entrando por porta, dano/reparo, ausência de lucro, distância/parede na compra, reconstrução com ator ocupando vão e reset. Executar `tests/test_defenses.gd` e cidade; commit `feat: add world purchases and breakable defenses`.

## Tarefa 5: consumíveis, projéteis e efeitos com ciclo de vida

**Arquivos:** criar `src/combat/hazard.gd`, `src/combat/projectile.gd`, `src/world/pickup.gd`, `tests/test_effects.gd`; modificar Player, Health, Game, CombatResolver, Station.

**Interfaces:** Hazard é Node3D com `configure(kind: String, origin: Vector3, damage: float, radius: float, duration: float) -> void`, `active: bool`, `remaining: float`. Projectile possui `launch(origin: Vector3, direction: Vector3, speed: float, damage: float, lifetime: float) -> void`, `active: bool`. Pickup possui `kind: String`, `remaining: float`, `collect(player: CharacterBody3D) -> bool`. Health acrescenta `heal(amount: float) -> void`; Player acrescenta `armor: float`, `grenades: int`, `throw_grenade(target: Vector3) -> bool`. Game possui `effects: Node3D`, filho de MatchActors; todos os temporários pertencem a esse nó.

- [ ] Escrever testes reais de pausa e reinício para um Hazard configurado:
  ```gdscript
  game.set_paused(true)
  var before = hazard.remaining
  await frames(10)
  check(hazard.remaining == before, "Ácido congelado em pausa")
  game.start_game()
  await frames(2)
  check(not is_instance_valid(hazard), "Efeito antigo removido")
  check(game.player.grenades <= 3, "Estoque limitado")
  ```
- [ ] Implementar efeitos com tick condicionado por gameplay ativo, sem timers globais que causem dano após morte/restart. Projétil usa teste de segmento anterior→seguinte para não atravessar paredes em frames longos. Dano de área chama CombatResolver e respeita oclusão.
- [ ] Kit cura até 50 por 250 pontos, sem cobrar se vida cheia. Colete absorve dano até 50 pontos de proteção, reparável por 400, sem cobrar quando cheio; resistência reduz dano antes da absorção. Granada custa 200, estoque máximo três, lançada por G, detona após 1,2 s com raio 4 e dano 150. Compra/uso não pode ressuscitar jogador morto.
- [ ] Drops por morte: munição 8%, cura 5%, demais sem item; expiram em 20 s de gameplay e coleta ocorre uma única vez a 1,5 unidade. Testar expiração, coleta duplicada, cura limitada, granada sem estoque, máscara de colisão e efeitos pausados.
- [ ] Executar `tests/test_effects.gd`, controles e integração; commit `feat: add consumables and pausable combat effects`.

## Tarefa 6: seis tipos de inimigos e composição das hordas

**Arquivos:** criar `src/data/enemy_catalog.gd`, `src/enemies/enemy_abilities.gd`, `tests/test_enemies.gd`; modificar Enemy, AgentBrain, ActorVisual e WaveDirector.

**Interfaces:** EnemyCatalog `static func get_definition(id: String) -> Dictionary`; Enemy acrescenta `kind: String = "walker"`, `configure(kind_id: String, round_number: int) -> void`, `abilities: Node`, `damage_multiplier: float`. EnemyAbilities possui `tick(delta: float) -> void`, `phase: String`, `phase_left: float`, `owner_enemy: CharacterBody3D`; consome Hazard e Projectile. WaveDirector acrescenta `enemy_kind(roll: float) -> String`, `spawn_interval() -> float`; mantém contadores e contratos antigos.

- [ ] Escrever teste determinístico da disponibilidade:
  ```gdscript
  var waves = load("res://src/systems/wave_director.gd").new()
  waves.start_next()
  for roll in [0.0, 0.25, 0.5, 0.75, 0.999]:
      check(waves.enemy_kind(roll) == "walker", "Horda 1 sem especiais")
  waves.round_number = 5
  for i in range(100):
      check(waves.enemy_kind(i / 100.0) in ["walker", "runner", "spitter"], "Desbloqueio respeitado")
  ```
- [ ] Introduzir tipos nas hordas 1/3/5/7/9/12. Peso total de especiais cresce até 65%, distribuído entre tipos liberados; restante walker. Intervalo de spawn `max(0.25, 0.65 - 0.012 * (round_number - 1))`. Crescimento de vida/dano é moderado, documentado em catálogo; velocidade de perseguição no máximo 4,3, exceto investida temporária anunciada.
- [ ] Cuspidor anuncia por 0,8 s e cospe projétil que deixa ácido por 4 s; demolidor trava direção por 1 s, investe por até 0,7 s e recupera por 1,2 s; gritador anuncia 1 s, fortalece dano de aliados em raio 8 por 4 s, sem empilhamento; volátil anuncia 1,2 s antes de explodir em raio 3. Corredor é mais rápido/frágil e errante preserva ataque simples. Invulnerabilidade não faz parte dos buffs.
- [ ] Usar silhueta e antecipação visual distintas. Todos os ataques avançam apenas com Enemy ativo. Investida colide e termina na parede; ataques à distância exigem linha de visão no disparo. Buffs expiram e não mantêm referências a mortos.
- [ ] Exercitar cada habilidade, esquiva saindo da área, impacto em parede, buff sem empilhamento e dano superior de demolidor em barreira. Executar `tests/test_enemies.gd`, regras e efeitos; commit `feat: add distinct zombie abilities and wave composition`.

## Tarefa 7: chefes e contabilidade de hordas

**Arquivos:** criar `src/enemies/boss_abilities.gd`, `tests/test_bosses.gd`; modificar EnemyCatalog, Enemy, WaveDirector, Game e ActorVisual.

**Interfaces:** WaveDirector acrescenta `boss_kind() -> String`, `boss_pending: bool`, `register_boss_spawn() -> bool`, `register_summon() -> bool`. `pending` conta somente fila comum; `alive` inclui comuns, chefe e invocações. `is_clear()` exige `pending == 0`, `alive == 0`, `not boss_pending`. BossAbilities usa o mesmo `tick(delta)` e estado de fase de EnemyAbilities. Game `spawn_enemy(point: Vector3, kind: String = "walker") -> CharacterBody3D` preserva chamadas de teste; registro de vagas ocorre no diretor antes de criar ator, e invocação obedece ao mesmo caminho.

- [ ] Criar teste da periodicidade e da vaga obrigatória:
  ```gdscript
  var waves = load("res://src/systems/wave_director.gd").new()
  waves.round_number = 9
  waves.start_next()
  check(waves.boss_kind() == "executioner" and waves.boss_pending, "Chefe na 10")
  waves.pending = 0
  check(not waves.is_clear(), "Chefe pendente bloqueia conclusão")
  waves.alive = 30
  check(not waves.register_summon(), "Invocação respeita teto")
  waves.alive = 0
  check(waves.register_boss_spawn(), "Reserva do chefe")
  check(not waves.register_boss_spawn(), "Chefe único")
  waves.register_kill()
  check(waves.is_clear(), "Rodada termina após chefe")
  ```
- [ ] Definir ciclo 10 Carrasco, 20 Matriarca, 30 Aberração, 40 Carrasco. Priorizar spawn do chefe no início da rodada especial; se não houver local seguro, manter pendente sem consumir contagem. Spawn comum usa pontos navegáveis a 14–32 unidades do jogador, verificados sem colisão/ocupação e preferindo fora da visão; nunca relaxar a distância mínima para forçar spawn.
- [ ] Carrasco alterna investida e golpe radial com 1 s de antecipação e 1,5 s de recuperação; Matriarca alterna saraivada de ácido e até quatro invocações por habilidade a cada 12 s; Aberração anuncia linha por 1,2 s antes de feixe bloqueado por parede e marca três áreas antes de descarga. Metade da vida acelera seu ciclo em 20%, sem remover antecipação mínima. Restringir invocações de Matriarca a oito ainda vivas, além do teto global.
- [ ] Recompensa de chefe 1000 + 50 por horda, emitida uma única vez. Testar morte duplicada, invocação no limite, morte do chefe com crias vivas, falha de spawn e sequência 1–50 com contabilidade consistente. Hordas especiais ainda têm inimigos comuns.
- [ ] Executar `tests/test_bosses.gd`, inimigos e integração; commit `feat: add recurring bosses and safe wave accounting`.

## Tarefa 8: HUD, acabamento e validação completa

**Arquivos:** criar `src/ui/minimap.gd`, `tests/test_expansion.gd`, `scripts/test.ps1`; modificar HUD, Reticle, Game, `tests/test_ui.gd`, `tests/test_controls.gd`, `tests/test_presentation.gd`, `tests/capture_visuals.gd`, `scripts/test.sh`, README, `docs/design.md`, `docs/validation.md`.

**Interfaces:** Minimap é Control com `update_map(layout: Dictionary, player_position: Vector3, discovered: Array) -> void`. HUD mantém `update_game(game)` e acrescenta indicadores derivados de Game/Player/Progression, sem debitar compras. World reset limpa descoberta e barricadas; Game reset recria progressão, equipamento e temporários e redefine alvo da câmera.

- [ ] Escrever verificações de ciclo completo:
  ```gdscript
  game.start_game()
  check(game.progression.balance == 0, "Saldo inicial")
  game.progression.award(10000)
  game.progression.buy_upgrade("health")
  game.set_paused(true)
  check(game.state == "PAUSED", "Pausa preservada")
  game.start_game()
  check(game.progression.balance == 0, "Reinício limpa saldo")
  check(game.progression.modifier("health") == 100.0, "Reinício limpa melhorias")
  check(game.player.loadout.current().id == "service_pistol", "Arma inicial restaurada")
  ```
- [ ] Mostrar saldo e pontuação separados, nome/slot/munição/reserva da arma, colete/granadas, aviso de interação com preço/efeito/substituição, upgrades MÁXIMO e barra de chefe. Minimap projeta XZ para o retângulo usando `(Vector2(x,z) - bounds.position) / bounds.size`, mostra cinco setores e estações descobertas a até 15 unidades. Não bloquear tiro com painéis passivos. Atualizar ajuda para E, G, 1/2 e roda.
- [ ] Testar layout de HUD em 1280×800 e 960×600; títulos não podem sobrepor mira/barra de chefe. Validar perda de foco, clique ao retomar, game over e retorno ao menu com efeitos e ofertas visíveis. Adaptar snapshots/expectativas textuais à gameplay final sem enfraquecer asserções de segurança.
- [ ] Criar runner PowerShell nativo e atualizar bash para as suítes `rules presentation ui controls integration city progression arsenal defenses effects enemies bosses expansion`. Rodar cada processo com captura de stdout/stderr, falhar em exit code diferente de zero ou `SCRIPT ERROR:|ERROR:|WARNING:`. Exemplo do núcleo:
  ```powershell
  $suiteOutput = & $engineBin --headless --path . --script "tests/test_${suite}.gd" 2>&1
  $suiteExitCode = $LASTEXITCODE
  $suiteOutput | Set-Content -LiteralPath $suiteLog
  if ($suiteExitCode -ne 0 -or ($suiteOutput -match 'SCRIPT ERROR:|ERROR:|WARNING:')) {
      throw "Falha na suite $suite; ver log $suiteLog"
  }
  ```
- [ ] Executar importação e todas as suítes uma vez após a integração; corrigir falhas pela habilidade systematic-debugging e repetir apenas verificações afetadas mais regressão pertinente. Capturar graficamente todos os setores, interior, barricada, plasma/elétrico e os três chefes. Medir FPS e tempo de bake no ambiente disponível com 30 ativos; registrar resolução, renderer, máquina disponível e limitações.
- [ ] Atualizar documentação removendo declarações obsoletas de Walker/pistola/mapa pequeno e registrando economia, limites e comandos reais. Exportar Windows se templates 4.6.1 estiverem disponíveis; testar a build se exportada. Registrar separadamente execução da engine, teste gráfico e build, sem tratar um como evidência do outro.
- [ ] Fazer revisão final independente conforme método escolhido, resolver achados, executar `git diff --check`, e commit `feat: finish city survival interface and validation`. Relatar ao usuário alterações, testes realmente executados e qualquer limitação restante.

## Autorrevisão do plano

- [x] Cobertura: cidade/câmera/interiores/atmosfera (1); economia/limites (2); nove armas (3); compras/barricadas (4); itens/drops/pausa de efeitos (5); seis inimigos (6); três chefes/escala/spawns (7); minimapa/HUD/reset/documentação/desempenho/build (8).
- [x] Contratos preservam chamadas existentes com argumentos padrão; novos módulos têm consumidor identificado.
- [x] Os cinco riscos de Review Focus possuem testes nas tarefas responsáveis.
- [x] Plano distingue parâmetros de balanceamento iniciais de resultados ainda não medidos.
- [x] Nenhuma etapa de implementação foi marcada como executada antes da revisão do usuário.

## Estado da entrega

As oito fatias foram implementadas na branch `feature/city-survival`. A validação local cobre 15 suítes headless, captura gráfica e revisão independente. A entrega continua sem merge ou publicação; a integração depende da revisão da equipe.

## Método de execução para escolha do usuário

Recomendação: execução nesta sessão pelo agente principal, seguida de revisão independente final, pois as oito tarefas compartilham interfaces e navegação/combate precisam ser validados juntos. Alternativa: um implementador e um revisor independentes por tarefa, com maior custo de contexto e revisão intermediária mais frequente. A implementação começa após revisão deste plano e escolha do método, conforme writing-plans.
