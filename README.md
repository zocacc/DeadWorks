# DeadWorks

Protótipo de combate **3D graybox** em **Godot 4.7.2**. A cena inicial testa câmera elevada, movimento independente da mira, tiro hitscan e hordas de zumbis. O [MVP 2D anterior](docs/mvp.md) continua preservado em `scenes/main.tscn`.

## Executar no PC

Atualize o clone pelo Git, abra `project.godot` no editor Godot 4.7.2 e pressione **F5**. O protótipo 3D é a cena principal. A [documentação do protótipo](docs/prototipo-3d.md) descreve os parâmetros configuráveis.

**WASD** move em relação à câmera; **mouse** mira; **clique esquerdo** dispara automaticamente; **Shift** corre; **Espaço** esquiva; **scroll** altera o zoom; **Tab** compara perspectiva e ortográfica; **R** reinicia.

## Desenvolvimento

Abra este diretório na VM pelo VS Code Remote SSH. Mantenha outro clone no Windows para o editor visual, usando **Godot 4.7.2** e Git LFS nos dois ambientes. Remote SSH não sincroniza esse clone local: use commits e `push`/`pull` pelo GitHub. Faça `pull` antes de alternar o ambiente de edição.

Na VM, execute:

```bash
bash tools/test-headless.sh
```

O script importa o projeto, testa o MVP 2D preservado e a física do protótipo 3D, e inicia a cena principal sem renderização. Ele aceita `GODOT_BIN=/caminho/para/godot` se o executável não estiver no `PATH`. O workflow do GitHub Actions executa os mesmos passos em push e pull request.

## Build Windows opcional

Para exportar sem abrir o editor, execute `bash tools/export-windows.sh` na VM quando o template Windows x64 estiver instalado. O script gera `.exe` e `.pck` em `builds/windows/`; não gera ZIP local. O GitHub Actions ainda publica os dois arquivos juntos como artefato para testes futuros.

## Estrutura

- `scenes/prototype3d/` e `scripts/prototype3d/`: arena, personagens, câmera, arma, spawner e HUD independentes.
- `scenes/main.tscn`, `scripts/world/` e `scripts/core/`: MVP 2D preservado e sua simulação.
- `tests/` e `tools/`: validação headless e comandos auxiliares.
- `assets/` e `data/`: sprites originais e futuras definições textuais.
- `docs/`: plano do MVP e notas do ambiente.

O protótipo 3D usa [modelos GLB CC0 com animações](docs/modelos-3d.md), versionados via Git LFS. O teste visual de iluminação, câmera e desempenho deve ser feito no notebook com GPU.
