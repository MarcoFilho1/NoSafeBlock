# Plano de Desenvolvimento — Zombie Survival Isométrico

## 1. Visão geral

Este projeto consiste no desenvolvimento de um jogo de sobrevivência contra zumbis com perspectiva isométrica, inspirado visualmente em **Project Zomboid**, porém com escopo e mecânicas significativamente simplificados.

O objetivo principal não é reproduzir as mecânicas complexas de sobrevivência de Project Zomboid, como fome, sede, doenças, sistema detalhado de ferimentos, crafting ou gerenciamento aprofundado de inventário.

A proposta é construir um jogo arcade de sobrevivência focado em:

- movimentação;
- combate;
- ondas de inimigos;
- agentes com comportamentos distintos;
- progressão de dificuldade;
- pontuação;
- tomada de decisão dos NPCs;
- interação do jogador com um pequeno ambiente 3D.

O jogo deve ser desenvolvido por uma equipe de **3 a 4 pessoas** em aproximadamente **3 dias**, portanto o projeto deve seguir uma estratégia de MVP rigorosa, priorizando funcionalidade, integração e estabilidade.

---

# 2. Objetivo acadêmico

O jogo será desenvolvido para uma disciplina de programação com agentes.

Por isso, a inteligência dos inimigos deve ser tratada como uma parte central do projeto.

Cada zumbi deve funcionar como um agente capaz de:

1. perceber informações do ambiente;
2. manter um estado interno;
3. tomar uma decisão;
4. executar uma ação;
5. reagir às ações do jogador;
6. alterar seu comportamento dependendo da situação.

Exemplo:

```text
PERCEPÇÃO
    ↓
Jogador está próximo?
    ↓
DECISÃO
    ↓
Patrulhar / Perseguir / Atacar
    ↓
AÇÃO
    ↓
Movimentar-se / Atacar
```

O sistema deve ser suficientemente simples para ser implementado no prazo, mas suficientemente claro para demonstrar conceitos de agentes durante a apresentação.

---

# 3. Conceito do jogo

## 3.1 Nome

**No Safe Block**

---

# 4. Gênero

- Survival arcade;
- ação;
- shooter isométrico;
- hordas;
- single-player com uma futura possibilidade de coop local ser adicionado posteriormente.

---

# 5. Perspectiva

O jogo utilizará uma perspectiva semelhante à de Project Zomboid:

- câmera elevada;
- ângulo inclinado;
- visão ampla do ambiente;
- mapa tridimensional;
- personagens tridimensionais;
- possibilidade de utilizar câmera ortográfica.

Recomendação:

```text
Mundo 3D
+
Modelos low-poly
+
Câmera ortográfica inclinada
```

Isso permite criar uma estética semelhante a jogos isométricos sem exigir sprites desenhados manualmente.

---

# 6. Direção visual

A estética deve priorizar velocidade de desenvolvimento.

Sugestões:

- low-poly;
- PS1 / PS2;
- pixelizado;
- texturas simples;
- iluminação básica;
- cores pouco saturadas;
- cenário pós-apocalíptico.

Não é necessário buscar realismo.

A limitação gráfica pode ser utilizada como parte da identidade visual do jogo.

---

# 7. Core loop

O loop principal do jogo deve ser:

```text
Início da partida
      ↓
Jogador entra no mapa
      ↓
Começa uma rodada
      ↓
Zumbis são criados
      ↓
Zumbis procuram o jogador
      ↓
Jogador combate os zumbis
      ↓
Zumbis são eliminados
      ↓
Jogador recebe pontos
      ↓
Rodada termina
      ↓
Dificuldade aumenta
      ↓
Próxima rodada
```

A partida termina quando:

```text
Vida do jogador <= 0
```

Resultado:

```text
GAME OVER
+
pontuação final
+
rodada alcançada
```

---

# 8. Escopo do MVP

O MVP deve conter somente as funcionalidades essenciais para que o jogo seja considerado completo.

## 8.1 Jogador

O jogador deve possuir:
- animações de movimentação;
- animações de rotação do personagem em direção ao cursor do mouse;
- vida;
- capacidade e animação ao receber dano;
- arma, com mecânica de munições, recarregar.;
- capacidade de concentrar pra melhorar a recisao ao atirar (importante: adicionar uma animação pra demonstrar que ele está de fato focado)
- capacidade de causar dano, com animação;
- morte, com animação;
- pontuação.

---

## 8.2 Movimento

Controle sugerido:

```text
W → cima
A → esquerda
S → baixo
D → direita
```

A movimentação deve ocorrer no plano horizontal do mapa.

A câmera não precisa girar.

---

# 9. Sistema de mira

A mira deve ser baseada na posição do mouse.

Fluxo:

```text
posição do mouse
      ↓
raycast para o chão
      ↓
obtém posição no mundo
      ↓
personagem olha para essa posição
```

O personagem deve rotacionar apenas no eixo vertical.

---

# 10. Sistema de tiro

O sistema de armas deve ser propositalmente simples.

## MVP

Inicialmente haverá apenas uma arma.

Sugestão:

**Pistola**

Características:

- dano fixo;
- cadência fixa;
- munição 9mm;
- com recarga;
- sem acessórios;
- sem recoil complexo;
- sem ADS;
- sem sistema balístico avançado.

Fluxo:

```text
Clique esquerdo
      ↓
arma pode disparar?
      ↓
gera tiro
      ↓
verifica colisão
      ↓
atingiu inimigo?
      ↓
aplica dano
```

O disparo poderá utilizar:

- raycast; ou
- projétil físico.

Para o prazo do projeto, **raycast é recomendado**.

---

# 11. Sistema de vida

## Jogador

Exemplo:

```text
Vida máxima: 100
```

Quando atacado:

```text
vida = vida - dano
```

Se:

```text
vida <= 0
```

então:

```text
Game Over
```

---

# 12. Agentes

Cada zumbi será um agente independente.

O agente deve possuir:

```text
Percepção
Estado
Decisão
Ação
```

---

# 13. Máquina de estados

A versão inicial pode utilizar uma Finite State Machine.

Estados:

```text
IDLE
PATROL
CHASE
ATTACK
DEAD
```

Fluxo básico:

```text
        ┌───────────┐
        │   IDLE    │
        └─────┬─────┘
              ↓
        ┌───────────┐
        │  PATROL   │
        └─────┬─────┘
              │ jogador detectado
              ↓
        ┌───────────┐
        │   CHASE   │
        └─────┬─────┘
              │ jogador próximo
              ↓
        ┌───────────┐
        │  ATTACK   │
        └─────┬─────┘
              │
              ↓
        ┌───────────┐
        │   DEAD    │
        └───────────┘
```

---

# 14. Percepção do agente

O zumbi deve conseguir perceber o jogador.

Uma implementação simples pode utilizar distância:

```text
distance(zombie, player) <= detectionRange
```

Se verdadeiro:

```text
state = CHASE
```

Exemplo:

```text
detectionRange = 10
attackRange = 1.5
```

---

# 15. Navegação

Os agentes devem conseguir navegar pelo mapa evitando obstáculos.

Opções recomendadas:

- NavMesh;
- sistema de navegação nativo da engine;
- A* simplificado.

Para um projeto de 3 dias, a recomendação é utilizar o sistema de navegação da própria engine.

---

# 16. Tipos de agentes

O MVP pode começar com apenas um agente.

Depois que o sistema estiver funcionando, novos comportamentos podem ser adicionados.

## 16.1 Walker

Comportamento simples.

Características:

- velocidade baixa;
- vida normal;
- dano normal.

Fluxo:

```text
detecta jogador
      ↓
persegue
      ↓
entra em alcance
      ↓
ataca
```

---

## 16.2 Runner

Opcional.

Características:

- velocidade alta;
- vida baixa;
- dano menor.

---

## 16.3 Tank

Opcional.

Características:

- velocidade baixa;
- vida alta;
- dano alto.

---

## 16.4 Flanker

Opcional e academicamente interessante.

Em vez de seguir diretamente para o jogador, o agente tenta aproximar-se por uma posição lateral.

Exemplo:

```text
posição alvo =
posição jogador
+
vetor lateral
```

O comportamento não precisa utilizar algoritmos avançados.

---

# 17. Prioridade dos agentes

Ordem de implementação:

```text
1. Walker
2. Runner
3. Tank
4. Flanker
```

O projeto NÃO deve atrasar para implementar os quatro.

Se apenas o Walker estiver funcionando corretamente, o jogo ainda deve permanecer jogável.

---

# 18. Sistema de combate dos inimigos

Quando:

```text
distância jogador <= attackRange
```

o agente entra no estado:

```text
ATTACK
```

O ataque deve possuir cooldown.

Exemplo:

```text
attackCooldown = 1 segundo
damage = 10
```

---

# 19. Sistema de hordas

O jogo será dividido em rounds.

Exemplo:

| Round | Zumbis |
|---|---:|
| 1 | 5 |
| 2 | 8 |
| 3 | 12 |
| 4 | 16 |
| 5 | 20 |

Uma fórmula simples pode ser utilizada:

```text
zombies = baseEnemies + round * multiplier
```

Exemplo:

```text
baseEnemies = 3
multiplier = 3
```

---

# 20. Spawn

Os inimigos devem aparecer em pontos específicos do mapa.

Exemplo:

```text
SpawnPoint
├── Norte
├── Sul
├── Leste
└── Oeste
```

O sistema seleciona aleatoriamente um ponto.

Regra:

O inimigo não deve aparecer muito próximo do jogador.

---

# 21. Sistema de pontuação

Cada inimigo eliminado concede pontos.

Exemplo:

| Inimigo | Pontos |
|---|---:|
| Walker | 10 |
| Runner | 15 |
| Tank | 30 |
| Flanker | 20 |

A interface deve mostrar:

```text
Score: 320
Round: 4
HP: 75
```

---

# 22. Progressão de dificuldade

A dificuldade deve aumentar progressivamente.

Pode ocorrer por:

- maior número de zumbis;
- maior velocidade;
- maior vida;
- maior dano;
- novos tipos de inimigos.

Prioridade:

```text
quantidade
>
velocidade
>
tipos
```

---

# 23. Mapa

O mapa deve ser pequeno.

Não construir uma cidade inteira.

Exemplo:

```text
┌─────────────────────────────┐
│ CASA        RUA       LOJA  │
│ ┌───┐                 ┌───┐ │
│ │   │       CARRO     │   │ │
│ └───┘                 └───┘ │
│                             │
│          PLAYER             │
│                             │
│ ÁRVORE             BARREIRA │
│                             │
│ ┌──────┐       ┌────────┐   │
│ │POSTO │       │GALPÃO  │   │
│ └──────┘       └────────┘   │
└─────────────────────────────┘
```

O mapa deve conter:

- obstáculos;
- prédios simples;
- ruas;
- objetos decorativos;
- pontos de spawn.

---

# 24. Interface

O HUD mínimo deve mostrar:

```text
HP
Round
Score
```

Opcional:

```text
Enemies Remaining
```

---

# 25. Telas

## Menu

Deve possuir:

```text
PLAY
QUIT
```

Opcional:

```text
SETTINGS
```

---

## Game Over

Deve exibir:

```text
GAME OVER

Score: XXXX
Round: XX

[TRY AGAIN]
[MENU]
```

---

# 26. Áudio

Áudios básicos:

- disparo;
- dano;
- morte do inimigo;
- ataque;
- música ambiente.

Não deve possuir prioridade superior à funcionalidade.

---

# 27. Arquitetura sugerida

Uma possível organização:

```text
GameManager
│
├── Player
│   ├── PlayerMovement
│   ├── PlayerAim
│   ├── PlayerCombat
│   └── PlayerHealth
│
├── Enemy
│   ├── EnemyAgent
│   ├── EnemyMovement
│   ├── EnemyCombat
│   └── EnemyHealth
│
├── WaveManager
│
├── SpawnManager
│
├── UIManager
│
└── ScoreManager
```

---

# 28. Responsabilidades dos componentes

## GameManager

Responsável por:

- estado global da partida;
- início da partida;
- game over;
- restart.

---

## WaveManager

Responsável por:

- rodada atual;
- quantidade de inimigos;
- início de novas hordas;
- identificação do fim da rodada.

---

## SpawnManager

Responsável por:

- pontos de spawn;
- criação de inimigos;
- seleção do tipo de inimigo.

---

## EnemyAgent

Responsável por:

- percepção;
- estado;
- tomada de decisão;
- alteração de comportamento.

---

## PlayerCombat

Responsável por:

- disparo;
- cooldown;
- raycast;
- dano.

---

# 29. Organização do código

Evitar scripts extremamente grandes.

Preferir componentes especializados.

Exemplo inadequado:

```text
Player.cs
3000 linhas
```

Melhor:

```text
PlayerMovement
PlayerCombat
PlayerHealth
PlayerAim
```

---

# 30. Estrutura de pastas sugerida

```text
Assets/
│
├── Scripts/
│   ├── Player/
│   ├── Enemy/
│   ├── Managers/
│   └── UI/
│
├── Prefabs/
│   ├── Player/
│   ├── Enemies/
│   └── Environment/
│
├── Models/
├── Materials/
├── Audio/
├── Scenes/
└── UI/
```

---

# 31. Divisão da equipe

## Equipe com 4 pessoas

### Pessoa 1 — Player

Responsável por:

- movimento;
- rotação;
- tiro;
- dano;
- vida.

---

### Pessoa 2 — Agentes

Responsável por:

- FSM;
- percepção;
- perseguição;
- pathfinding;
- ataque;
- tipos de agentes.

---

### Pessoa 3 — Sistemas

Responsável por:

- WaveManager;
- SpawnManager;
- pontuação;
- game over;
- HUD.

---

### Pessoa 4 — Mundo e integração

Responsável por:

- mapa;
- assets;
- iluminação;
- menu;
- efeitos;
- áudio;
- integração.

---

# 32. Divisão com 3 pessoas

## Pessoa 1

```text
Player
+
armas
+
vida
```

## Pessoa 2

```text
agentes
+
IA
+
pathfinding
```

## Pessoa 3

```text
waves
+
spawn
+
UI
+
mapa
```

Todos devem participar da integração e testes.

---

# 33. Cronograma

## Dia 1 — Fundação

Meta:

> Ter uma versão extremamente simples, mas jogável.

### Implementar

- projeto da engine;
- Git;
- cena principal;
- jogador;
- movimentação;
- câmera;
- mira;
- tiro;
- primeiro zumbi;
- perseguição;
- dano;
- morte.

Resultado esperado:

```text
Player consegue andar
+
Player consegue atirar
+
Zombie consegue perseguir
+
Player consegue matar Zombie
```

---

# 34. Dia 2 — Gameplay

Implementar:

- spawn;
- rounds;
- múltiplos inimigos;
- pontuação;
- HUD;
- vida do jogador;
- game over;
- mapa;
- obstáculos;
- navegação.

Resultado esperado:

```text
Partida completa jogável
```

Nesse momento o projeto já deve poder ser entregue.

---

# 35. Dia 3 — Polimento

Somente depois do MVP funcionar.

Possibilidades:

- Runner;
- Tank;
- Flanker;
- shotgun;
- efeitos;
- partículas;
- sangue;
- áudio;
- melhorar mapa;
- menu;
- animações;
- balanceamento.

A prioridade do dia 3 deve ser:

```text
BUGS
>
ESTABILIDADE
>
POLIMENTO
>
NOVAS FEATURES
```

---

# 36. Estratégia de Git

Sugestão:

```text
main
develop
```

Branches:

```text
feature/player-movement
feature/player-combat
feature/enemy-agent
feature/wave-system
feature/map
```

Fluxo:

```text
feature
   ↓
develop
   ↓
testes
   ↓
main
```

Não trabalhar diretamente na `main`.

---

# 37. Commits

Utilizar commits pequenos.

Exemplos:

```text
feat: add player movement
feat: implement zombie chase state
feat: add wave manager
fix: prevent zombie attack spam
fix: stop enemies after player death
```

---

# 38. Requisitos funcionais

## RF01 — Movimento

O jogador deve conseguir movimentar-se pelo mapa.

### Critério de aceite

Ao pressionar WASD, o personagem deve movimentar-se na direção esperada.

---

## RF02 — Mira

O personagem deve olhar em direção à posição do cursor. E ao pressionar o botão direito do mouse o personagem deve "focar" e o cursor deve ficar com um "símbolo" de mira. Pra demonstrar que a mira está funcionando

### Critério de aceite

Mover o mouse ao redor do personagem deve alterar sua direção. Ao apertar o botão direito do mouse o personagem deve "focar" e o cursor deve ficar com um "símbolo" de mira. Pra demonstrar que a mira está funcionando, o personagem deve ficar com a arma apontada para o local de onde o tiro vai sair

---

## RF03 — Disparo

O jogador deve conseguir realizar disparos, consumindo sua munição disponível.

### Critério de aceite

Ao clicar, um disparo deve ser processado respeitando o cooldown, cadencia e munição disponível da arma.

---

## RF04 — Dano

Inimigos atingidos devem perder vida.

### Critério de aceite

Após receber dano suficiente, o inimigo deve morrer.

---

## RF05 — Percepção

O zumbi deve detectar o jogador.

### Critério de aceite

Entrar no raio de percepção deve alterar o agente para CHASE.

---

## RF06 — Perseguição

O inimigo deve conseguir perseguir o jogador.

### Critério de aceite

O agente deve reduzir a distância até o jogador enquanto estiver em CHASE.

---

## RF07 — Ataque

O inimigo deve atacar quando estiver suficientemente próximo.

### Critério de aceite

O HP do jogador deve diminuir respeitando um cooldown.

---

## RF08 — Morte do jogador

O jogador deve morrer quando HP chegar a zero.

---

## RF09 — Waves

O jogo deve criar rodadas sucessivas.

---

## RF10 — Pontuação

Eliminar inimigos deve aumentar a pontuação.

---

## RF11 — Game Over

Ao morrer, o jogador deve visualizar a tela de fim de jogo.

---

# 39. Requisitos não funcionais

## RNF01 — Performance

O jogo deve permanecer jogável com múltiplos inimigos simultâneos.

Meta inicial:

```text
20 agentes ativos
```

Isso pode ser reduzido dependendo do hardware e da engine.

---

## RNF02 — Clareza visual

O jogador deve distinguir:

- personagem;
- inimigos;
- obstáculos;
- projéteis ou direção dos tiros.

---

## RNF03 — Responsividade

Movimento e disparo devem responder imediatamente aos comandos.

---

## RNF04 — Estabilidade

O jogo não deve apresentar erros críticos durante uma partida normal.

---

# 40. Testes

Os testes devem ser divididos em testes funcionais e testes de integração.

---

# 41. Teste de movimentação

### Procedimento

1. iniciar partida;
2. pressionar W;
3. pressionar A;
4. pressionar S;
5. pressionar D.

### Resultado esperado

O personagem se move corretamente em todas as direções.

---

# 42. Teste de colisão

### Procedimento

1. mover personagem em direção a uma parede.

### Resultado esperado

O personagem não atravessa o objeto.

---

# 43. Teste de mira

### Procedimento

1. mover o cursor ao redor do personagem.

### Resultado esperado

O personagem acompanha corretamente a direção do cursor.

---

# 44. Teste de disparo

### Procedimento

1. clicar repetidamente.

### Resultado esperado

A arma respeita a cadência configurada.

---

# 45. Teste de dano

### Procedimento

1. disparar contra um zumbi.

### Resultado esperado

A vida do zumbi diminui.

---

# 46. Teste de morte do inimigo

### Procedimento

1. causar dano suficiente.

### Resultado esperado

O inimigo:

- entra no estado DEAD;
- deixa de atacar;
- deixa de movimentar;
- concede pontos;
- é removido.

---

# 47. Teste de percepção

### Procedimento

1. permanecer fora do raio do zumbi;
2. aproximar-se.

### Resultado esperado

O estado deve mudar de:

```text
IDLE/PATROL
```

para:

```text
CHASE
```

---

# 48. Teste de perseguição

### Procedimento

1. entrar no raio;
2. movimentar-se pelo mapa.

### Resultado esperado

O zumbi acompanha o jogador utilizando a navegação disponível.

---

# 49. Teste de ataque

### Procedimento

1. aproximar-se do zumbi.

### Resultado esperado

O inimigo causa dano apenas dentro do alcance e respeita o cooldown.

---

# 50. Teste de navegação

### Procedimento

Colocar um obstáculo entre:

```text
Zombie → Obstáculo → Player
```

### Resultado esperado

O zumbi deve tentar contornar o obstáculo.

---

# 51. Teste de waves

### Procedimento

1. eliminar todos os inimigos.

### Resultado esperado

Após um pequeno intervalo, uma nova rodada deve começar.

---

# 52. Teste de dificuldade

### Procedimento

Jogar múltiplas rodadas.

### Resultado esperado

A quantidade ou dificuldade dos inimigos aumenta.

---

# 53. Teste de pontuação

### Procedimento

Eliminar um inimigo.

### Resultado esperado

A pontuação aumenta corretamente.

---

# 54. Teste de morte do jogador

### Procedimento

Receber dano até HP = 0.

### Resultado esperado

- movimento bloqueado;
- ataques bloqueados;
- inimigos deixam de causar efeitos relevantes;
- tela Game Over aparece.

---

# 55. Teste de reinício

### Procedimento

Na tela Game Over:

```text
TRY AGAIN
```

### Resultado esperado

Uma nova partida deve iniciar sem manter dados incorretos da partida anterior.

---

# 56. Teste de carga

### Procedimento

Criar aproximadamente:

```text
10
20
30
```

agentes.

### Avaliar

- FPS;
- navegação;
- colisões;
- travamentos;
- uso excessivo de CPU.

---

# 57. Definição de pronto

Uma funcionalidade somente é considerada concluída quando:

- implementada;
- integrada;
- testada;
- sem erros críticos conhecidos;
- funcionando na branch principal de desenvolvimento.

---

# 58. Definition of Done do MVP

O MVP está pronto quando for possível:

```text
1. abrir o jogo;
2. iniciar partida;
3. movimentar o personagem;
4. mirar;
5. disparar;
6. encontrar inimigos;
7. ser perseguido;
8. receber dano;
9. matar inimigos;
10. receber pontos;
11. completar uma rodada;
12. iniciar a próxima;
13. morrer;
14. visualizar Game Over;
15. reiniciar a partida.
```

Se esses quinze itens funcionarem, o projeto pode ser considerado entregável.

---

# 59. Features opcionais

Só devem ser implementadas depois do MVP.

## Prioridade 1

- tipos diferentes de zumbi;
- efeitos;
- sons;
- melhorias gráficas.

## Prioridade 2

- armas diferentes;
- pickups;
- upgrades.

## Prioridade 3

- sistema simples de compras;
- objetos interativos;
- portas;
- barricadas.

## Fora do escopo inicial

- multiplayer online;
- sistema complexo de inventário;
- crafting;
- fome;
- sede;
- doenças;
- construção;
- veículos;
- mapa gigante;
- geração procedural;
- campanha;
- sistema complexo de loot.

---

# 60. Possível sistema de upgrades

Se houver tempo:

Ao terminar uma rodada:

```text
Escolha 1 upgrade
```

Exemplos:

```text
+20% dano
+10% velocidade
+20 HP
-15% cooldown
```

Esse sistema adiciona progressão sem grande complexidade.

---

# 61. Possível sistema de armas

Depois da pistola:

```text
Pistola
Shotgun
Rifle
RayGun (Inspirada no Cod Zombies)
Uma Arma que Dispara Laser (Em linhareta)
```


---

# 62. Telemetria para apresentação

Para tornar o comportamento dos agentes evidente durante a apresentação, pode existir um modo de debug.

Exemplo acima do zumbi:

```text
Walker #12
State: CHASE
Target: Player
Distance: 4.7
```

Também pode ser mostrada a área de percepção.

Essa feature possui alto valor acadêmico e baixo custo de implementação.

---

# 63. Modo debug recomendado

Ativado por uma tecla:

```text
F1
```

Exibir:

- estado atual;
- raio de percepção;
- rota;
- alvo;
- FPS;
- quantidade de agentes.

Isso ajuda muito na demonstração do projeto.

---

# 64. Riscos

## Risco 1 — Escopo excessivo

Mitigação:

Não iniciar features opcionais antes do MVP.

---

## Risco 2 — Pathfinding

Agentes podem travar.

Mitigação:

- mapa simples;
- corredores largos;
- poucos obstáculos complexos;
- usar navegação nativa da engine.

---

## Risco 3 — Git

Conflitos podem atrasar o projeto.

Mitigação:

Separar responsabilidades e arquivos.

---

## Risco 4 — Assets

Perder tempo procurando modelos.

Mitigação:

Usar primitivas ou assets gratuitos inicialmente.

---

## Risco 5 — Performance

Muitos agentes podem reduzir FPS.

Mitigação:

Limitar quantidade simultânea.

---

## Risco 6 — Feature creep

Adicionar constantemente novas ideias.

Mitigação:

Aplicar a regra:

> Se o MVP ainda não está completo, a feature não entra.

---

# 65. Resultado esperado

Ao final do projeto, deve existir um jogo curto, funcional e demonstrável no qual o jogador controla um sobrevivente em um pequeno cenário tridimensional visto por uma câmera isométrica.

Durante a partida:

1. hordas de zumbis surgem;
2. cada zumbi executa comportamento autônomo;
3. os agentes detectam e perseguem o jogador;
4. o jogador utiliza uma arma para eliminá-los;
5. inimigos conseguem causar dano;
6. o jogador recebe pontos;
7. novas hordas aumentam a dificuldade;
8. a partida termina com a morte do jogador.

O projeto deve demonstrar claramente a aplicação de conceitos relacionados a agentes por meio da percepção, tomada de decisão, execução de ações e mudança de estados dos inimigos.

---

# 66. Critério de sucesso

O projeto será considerado bem-sucedido se, ao final dos três dias:

- o jogo puder ser iniciado sem intervenção dos desenvolvedores;
- o core loop estiver completo;
- os agentes apresentarem comportamento observável;
- não houver bugs que impeçam a partida;
- uma sessão de alguns minutos puder ser jogada do início ao Game Over;
- os conceitos de agentes puderem ser explicados utilizando a própria implementação.

A quantidade de features não será o principal indicador de sucesso.

A prioridade é:

```text
JOGO COMPLETO E SIMPLES
>
JOGO AMBICIOSO E INCOMPLETO
```

---

# 67. Checklist final

## Gameplay

- [ ] Player movimenta
- [ ] Player mira
- [ ] Player atira
- [ ] Player recebe dano
- [ ] Player morre
- [ ] Zombie detecta Player
- [ ] Zombie persegue Player
- [ ] Zombie ataca
- [ ] Zombie recebe dano
- [ ] Zombie morre

## Sistemas

- [ ] Spawn funciona
- [ ] Waves funcionam
- [ ] Score funciona
- [ ] HUD funciona
- [ ] Game Over funciona
- [ ] Restart funciona

## Mundo

- [ ] Mapa possui colisões
- [ ] Navegação funciona
- [ ] Spawn points estão posicionados
- [ ] Obstáculos não bloqueiam permanentemente agentes

## Testes

- [ ] Movimento testado
- [ ] Combate testado
- [ ] IA testada
- [ ] Waves testadas
- [ ] Game Over testado
- [ ] Reinício testado
- [ ] Performance testada

## Entrega

- [ ] Build executável
- [ ] README
- [ ] Controles documentados
- [ ] Equipe identificada
- [ ] Vídeo ou screenshots, se necessário
- [ ] Código no repositório
