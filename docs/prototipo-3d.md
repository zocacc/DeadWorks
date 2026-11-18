# Protótipo 3D de combate

## Objetivo

Validar câmera top-down oblíqua, movimentação independente da mira e combate contra hordas antes de investir em arte ou sistemas de fábrica. A cena inicial é `scenes/prototype3d/arena.tscn`. O antigo sandbox 2D permanece em `scenes/main.tscn` e pode ser aberto diretamente no editor.

## Jogar

Abra `project.godot` com Godot 4.7.2 no notebook e pressione F5. WASD move no plano horizontal em relação à câmera, Shift corre, Espaço esquiva, mouse mira, clique esquerdo dispara, scroll altera o zoom, Tab alterna perspectiva/ortográfica e R reinicia a arena. O HUD mostra vida, abates e número de zumbis vivos.

## Ajustes no Inspector

- `CameraRig`: inclinação inicial 55° abaixo do horizontal, distância 20, FOV 40°, suavização, limites e passo de zoom, projeção inicial.
- `Player`: velocidades, aceleração, desaceleração, esquiva, giro e vida máxima.
- `Weapon`: tiros por segundo, dano e alcance.
- `Zombie`: vida, velocidade, detecção, alcance, dano e intervalo do ataque.
- `ZombieSpawner`: quantidade inicial 20, máximo simultâneo 60, intervalo de nascimento e distância segura.

A arena mede 80 × 80 unidades. Personagens usam colisões físicas separadas dos modelos provisórios; os visuais humanoides usam modelos GLB estilizados com esqueleto e animações. O sobrevivente segura um rifle 3D com marcador no cano. O tiro é um raycast horizontal na altura do tronco, na direção calculada pelo cursor projetado no terreno; clarão e traçante saem do cano. As [fontes e licenças dos modelos](modelos-3d.md) estão documentadas separadamente.

## Verificar na VM

`bash tools/test-headless.sh` importa o projeto, executa os testes do sandbox 2D e do combate 3D, e inicializa a cena principal. Esses testes cobrem câmera, spawner, raio seguro, movimento relativo à câmera, tiro, cadência, dano, morte e HUD. O modo headless não permite julgar a composição visual nem a taxa de quadros; confira esses pontos no notebook.

Inventário, crafting, automação, construção, multiplayer e geração procedural ficam fora deste protótipo.
