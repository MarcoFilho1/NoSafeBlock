# No Safe Block — decisões do MVP

Autoridade funcional: `plano_desenvolvimento_zombie_survival.md`.

## Escolhas

- Godot 4.6.1 standard, GDScript, renderer Compatibility, desktop com teclado e mouse.
- Uma única implementação. A equipe declarou não ter preferência entre Unity e Godot.
- Mundo 3D urbano de 180 × 180 unidades, câmera ortográfica acompanhando o jogador em perspectiva isométrica e arte original feita de primitivas low-poly. Sem downloads de assets ou plugins.
- WASD relativo à tela; mouse orienta arma; esquerdo dispara; direito concentra, reduz dispersão e velocidade, muda postura e retículo; R recarrega; Esc pausa; F1 mostra agentes.
- Arsenal: nove armas com duas vagas de equipamento, incluindo calibre 12, fuzil, plasma e eletricidade. Pistola inicial mantém reserva ilimitada; outras armas têm reserva limitada e compras de munição. Plasma causa dano em área e eletricidade encadeia para alvos expostos.
- Jogador: 100 HP inicial, colete e até três granadas; upgrades por partida com três níveis de vida, resistência, recarga e movimento, e duas melhorias de dano por arma. Colisões e animações procedurais permanecem.
- Inimigos: Errante, Corredor, Cuspidor, Demolidor, Gritador e Volátil; cada tipo possui silhueta, sinalização e habilidade próprias. Mantêm percepção, perseguição e ataques bloqueados por paredes.
- Hordas crescentes a partir de 5 inimigos, emissão escalonada e máximo de 30 vivos. Chefes chegam nas hordas 10, 20 e 30, repetindo Carrasco, Matriarca e Aberração; chefe e invocações contam para a conclusão da rodada.
- Cidade: cinco distritos, 11 interiores com saídas alternativas, estações de compra, minimapa e barricadas destrutíveis/reparáveis. Barricadas não disparam rebake da NavMesh e inimigos atacam a obstrução física quando necessário.
- Menu, HUD, pausa, Game Over, replay e retorno ao menu. Áudio sintetizado original, com mute. F1: estados, percepção, rota, alvo, distância, FPS e contagem.
- O loop completo inclui exploração, economia, defesa, armas, progressão limitada, inimigos especiais e chefes. Multiplayer, crafting, fome e sede permanecem fora desta entrega.

## Componentes e contratos

`Health` emite `changed` e `died` uma única vez. `Weapon` controla munição e tempo; `Player` coordena movimento, mira e raycast. `AgentBrain` decide estados sem depender da cena; `Enemy` executa percepção, navegação e ataque. `WaveDirector` controla contagem e spawn pendente; `Game` possui estado global, pontuação e ciclo de vida das cenas. `World` constrói cenário e malha de navegação uma vez. `HUD` só apresenta estado e emite intenções. `ActorVisual` e `Audio` são apresentação.

## Git Flow e colaboração

Base conferida: `origin/main` no commit `11d0892`; nenhuma outra branch remota em 2026-09-21. Criar `develop` dessa base e `feature/zombie-survival-mvp` de `develop`. Trabalhar em commits pequenos na feature; integração por PR para `develop`, seguida de validação e promoção para `main`. Não fazer merge ou push para branches compartilhadas automaticamente. O plano fornecido será versionado sem alterar seu conteúdo.

## Validação

Testes headless de vida, munição, cooldown, estados, hordas e spawns. Teste de integração com cena real para colisões, raycast, navegação, morte, reinício e 30 agentes. Importação do editor, execução gráfica e captura visual. Build macOS local executável; preset Windows disponível, validação Windows depende dessa plataforma. Registrar evidência e limitações em `docs/validation.md`.
