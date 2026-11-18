# Modelos do protótipo 3D

O sobrevivente usa um personagem SWAT de proporções humanas, com mãos, rosto e roupa definidos. O zumbi usa o modelo Hoodie Character do mesmo conjunto de animações, com pele e roupa dessaturadas para representar infecção. Ambos são estilizados em low poly; esta etapa melhora a silhueta e a leitura do combate, sem buscar fotorrealismo.

O rifle é um modelo 3D de arma longa inspirado em um fuzil de assalto. A animação `Idle_Gun` posiciona os braços do sobrevivente para segurar a arma. O rifle acompanha a posição da mão direita pelo `BoneAttachment3D` e mantém a orientação da mira; um marcador no cano posiciona clarão e traçante. O raycast de dano permanece no eixo central da mira para que o tiro funcione durante o giro do personagem.

Os modelos visuais ficam em `assets/` e não alteram as cápsulas de colisão nem a lógica de dano. Caminhada, corrida, disparo, reação ao dano e morte usam as animações importadas. A direção de tiro e a orientação do personagem continuam independentes da câmera.

## Fontes e licenças

Os arquivos GLB abaixo foram baixados das páginas individuais do Poly Pizza, que os identificam como **Public Domain (CC0)**:

| Arquivo | Criador | Fonte |
| --- | --- | --- |
| `assets/characters/survivor_swat.glb` | Quaternius | [SWAT](https://poly.pizza/m/Btfn3G5Xv4) |
| `assets/characters/zombie_hoodie.glb` | Quaternius | [Hoodie Character](https://poly.pizza/m/gKLBoRsyKe) |
| `assets/weapons/rifle.glb` | Quaternius | [Assault Rifle](https://poly.pizza/m/Bgvuu4CUMV) |

Os GLB são versionados via Git LFS. No clone Windows, instale o Git LFS e rode `git lfs pull` antes de abrir o projeto no Godot.

## Teste visual no notebook

Abra o projeto no Godot 4.7.2, pressione F5 e confira o rifle nas duas mãos, o alinhamento do cano e a leitura dos zumbis a diferentes níveis de zoom. A VM sem GPU valida importação, scripts, animações e colisões em modo headless, mas não substitui este teste de composição visual.
