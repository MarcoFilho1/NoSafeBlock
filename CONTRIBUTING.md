# Colaboração e Git Flow

## Branches

- `main`: versões estáveis aprovadas pela equipe.
- `develop`: integração e testes antes da promoção para `main`.
- `feature/<assunto>`: novas funcionalidades, sempre a partir de `develop` atualizado.
- `fix/<assunto>`: correções para `develop`.
- `release/<versão>`: estabilização de uma entrega, quando a equipe precisar.
- `hotfix/<assunto>`: correção urgente de uma versão em `main`; integrar também em `develop`.

Não desenvolver ou fazer commits diretamente em `main`. Não empilhar features independentes sobre branches pessoais de colegas. Não fazer force-push em branches compartilhadas.

## Inicialização deste repositório

O remoto inicialmente continha somente `main` em `11d0892`. Nesta entrega, `develop` foi criada localmente nesse commit; `feature/zombie-survival-mvp` foi criada a partir dela. A publicação inicial de `develop` e o PR da feature devem ser coordenados pelo mantenedor. Nenhum merge é implicitamente aprovado por um teste automatizado.

Depois que `origin/develop` existir, o fluxo normal é:

```sh
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch -c feature/nome-da-funcionalidade
```

Antes de começar, confira `git status`, `git branch -vv` e combine a responsabilidade dos arquivos. Preserve alterações alheias; não execute resets ou limpezas destrutivas para trocar de branch.

## Commits e pull requests

1. Faça commits pequenos: `feat:`, `fix:`, `test:`, `docs:` ou `ci:`.
2. Adicione arquivos explicitamente (`git add -- caminho`); não versione `.godot/`, executáveis, caches ou diretórios temporários.
3. Versione arquivos `.gd.uid`: são IDs de recursos gerados pelo Godot e necessários à estabilidade das referências.
4. Rode importação, `bash scripts/test.sh` e `git diff --check`.
5. Abra o PR com base em `develop`, informando problema, comportamento, teste e limitações.
6. Peça revisão de outra pessoa. Resolver conflitos e testar novamente é responsabilidade da feature.
7. Apenas após revisão e aprovação da equipe integre em `develop`.
8. A promoção de `develop` para `main` usa um PR separado e deve validar a build executável e uma partida completa.

No GitHub, recomenda-se o mantenedor proteger `main` e `develop`, exigir revisão e o check `gameplay`. Essas proteções são recomendações documentadas, não configurações aplicadas por esta entrega.

## Fronteiras de trabalho

| Frente | Dono dos arquivos | Contratos que precisam ser combinados |
|---|---|---|
| Jogador | `src/player/`, `src/core/health.gd` | `died`, `shot_fired`, `cue_requested`, `take_damage()` |
| Agentes | `src/enemies/` | `setup(player)`, `eliminated(points)`, `take_damage()`, `set_debug()` |
| Sistemas | `src/systems/` | ciclo de partida, `WaveDirector`, spawn e pontuação |
| Mundo / apresentação | `src/world/`, `src/visuals/`, `src/ui/` | spawn points, câmera, sinais do HUD |

Mudanças em contratos compartilhados devem ser combinadas antes da implementação. Só o coordenador de integração deve editar `src/systems/game.gd` enquanto outros colaboradores alteram as interfaces consumidas por ele.

## Critério de aceite

Implementação e teste na feature não equivalem à definição de pronto do plano original. A funcionalidade só está integrada quando aprovada em `develop`. O fluxo manual precisa cobrir: iniciar, WASD, mirar/focar, disparar/recarregar, contornar paredes, matar, pontuar, passar de horda, receber dano, morrer, reiniciar e voltar ao menu. Para mudanças em agentes, usar F1 e testar 20–30 inimigos.
