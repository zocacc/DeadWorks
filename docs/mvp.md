# DeadWorks — definição do MVP

## Objetivo

Entregar um sandbox 2D isométrico que prove a ligação entre sobrevivência, automação e ameaça zumbi. O mapa inicial é uma arena fixa de 2048×1152 unidades de simulação, com grade de 32 unidades exibida em losangos de 64×32 pixels e câmera seguindo o jogador. O mundo aberto procedural será avaliado depois. Não há vitória formal nem save no MVP.

## Ciclo jogável

1. Explorar a arena, coletar sucata e sobreviver aos zumbis.
2. Construir um processador, uma montadora e esteiras direcionais.
3. Abastecer o processador manualmente. Ele transforma sucata em material intermediário.
4. Transportar o material pelas esteiras até a montadora. A montadora produz kits de barricada.
5. Retirar os kits, construir barricadas e defender o jogador e as máquinas com ataque corpo a corpo.
6. Continuar produzindo. Pilhas de sucata esgotadas voltam a ficar disponíveis, permitindo repetir o ciclo na mesma sessão.

Máquinas em operação geram ruído visível, atraem zumbis próximos e aceleram o surgimento de novos inimigos. Uma entrada vazia ou uma rota de esteiras interrompida pausa a produção correspondente. Zumbis atacam o jogador, máquinas ruidosas e barricadas que bloqueiam seu caminho.

## Controles e leitura do estado

- WASD/setas: mover nas direções da tela; `E`: coletar, abastecer processador ou retirar kits; `Espaço`: ataque corpo a corpo.
- `1`: processador; `2`: montadora; `3`: esteira; `4`: barricada. Clique esquerdo constrói; `R` gira a direção do processador ou da esteira; clique direito ou Esc cancela.
- Enter reinicia após a morte. A interface mostra vida, sucata, kits, abates, máquinas ativas e o modo de construção.

## Critérios de conclusão

- É possível produzir e usar pelo menos dois kits de barricada na mesma sessão sem reiniciar.
- Desconectar a linha de esteiras retém o material; completar a linha permite que ele chegue à montadora, sem perda ou duplicação.
- Operar máquinas altera a ameaça observável; zumbis atacam, barricadas absorvem dano e podem ser destruídas; o jogador pode matar zumbis e morrer.
- A cadeia de produção, o dano e a escolha de alvo passam nos testes headless; a cena abre na VM sem GPU. O teste visual e de jogabilidade deve ser feito no notebook.
- A seleção por mouse corresponde à célula isométrica exibida; o personagem se orienta em oito direções e responde visualmente ao movimento, ataque, coleta e dano.

## Limites aceitos

Sem fome, sede, armas de fogo, torres, energia, braços, divisores de esteira, receitas alternativas, saves, mundo procedural, multiplayer ou arte final. A simulação permanece em coordenadas ortogonais, separada da projeção isométrica e da entrada. O próximo marco deve conectar melhor automação e sobrevivência por meio de itens produzidos pela fábrica.
