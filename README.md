# DeadWorks

Sandbox **2D isométrico** em **Godot 4.7.2**: coleta, automação e sobrevivência contra zumbis. O [MVP](docs/mvp.md) usa uma arena fixa para testar as mecânicas; geração procedural fica para depois.

## Como jogar

Mova-se com **WASD** ou setas nas direções da tela. Pressione **E** perto de uma pilha para coletar sucata. Construa um **processador** (`1`), duas **esteiras** (`3`) apontando da saída do processador para a **montadora** (`2`), e abasteça o processador com `E`. Use **R** para girar a direção da peça selecionada e clique no losango da célula para posicionar. Espere o material atravessar as esteiras e a montadora produzir; pressione `E` perto dela para retirar os kits. Escolha **barricada** (`4`) e clique para construí-la com um kit.

**Espaço** ataca zumbis à frente do personagem. Clique direito ou Esc cancela a construção. Se a vida chegar a zero, **Enter** reinicia. Máquinas ativas atraem zumbis e aceleram sua chegada.

## Desenvolvimento

Abra este diretório na VM pelo VS Code Remote SSH. Mantenha outro clone no Windows para o editor visual, usando **Godot 4.7.2** e Git LFS nos dois ambientes. Remote SSH não sincroniza esse clone local: use commits e `push`/`pull` pelo GitHub. Faça `pull` antes de alternar o ambiente de edição.

Na VM, execute:

```bash
bash tools/test-headless.sh
```

O script importa o projeto, testa a simulação e inicia a cena sem renderização. Ele aceita `GODOT_BIN=/caminho/para/godot` se o executável não estiver no `PATH`. O workflow do GitHub Actions executa os mesmos passos em push e pull request.

## Testar no Windows

Para abrir no editor Godot, baixe o snapshot local `DeadWorks-MVP-test.zip` da raiz da VM, importe `project.godot` com Godot 4.7.2 e pressione F5. Esse ZIP é ignorado pelo Git.

Para jogar sem instalar a Godot, use o build portátil local `builds/windows/DeadWorks-Windows-x64.zip`: extraia os dois arquivos na mesma pasta e execute `DeadWorks.exe`. O GitHub Actions gera o mesmo par `DeadWorks.exe` + `DeadWorks.pck` e o disponibiliza em **Actions → execução → Artifacts → DeadWorks-Windows-x64** depois que este workflow for enviado ao GitHub. O artefato é um ZIP portátil, não um instalador com assistente.

Uma exportação local pode ser refeita com `bash tools/export-windows.sh` quando o template Windows x64 da Godot 4.7.2 estiver instalado.

## Estrutura

- `scenes/` e `scripts/world/`: cena, entrada, câmera, interface e desenho.
- `scripts/core/`: regras de simulação testáveis sem renderização.
- `tests/` e `tools/`: validação headless e comandos auxiliares.
- `assets/` e `data/`: sprites originais e futuras definições textuais.
- `docs/`: plano do MVP e notas do ambiente.

O personagem, o zumbi e o processador usam sprites originais; chão, sucata, esteiras, montadora e barricadas usam desenho isométrico nativo da Godot. O editor visual e o teste de jogabilidade continuam no notebook.
