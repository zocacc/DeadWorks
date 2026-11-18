# Ambiente de desenvolvimento

- Versão de referência: Godot 4.7.2 padrão, com GDScript. Não requer .NET, C++, Xvfb ou GPU na VM.
- Godot `4.7.2-2` e Git LFS `3.8.1-1` estão instalados pelos repositórios oficiais do Arch. `godot` e `git-lfs` resolvem para `/usr/bin/`. As cópias verificadas usadas antes da instalação ainda estão guardadas em `~/.local/share/deadworks/`, mas não estão no `PATH`.
- O clone local do Windows deve usar Godot 4.7.2 e Git LFS. GitHub é o ponto de sincronização dos dois clones. `.godot/` e `builds/` são caches locais e não devem ser enviados.
- `bash tools/test-headless.sh` é o teste da VM e da CI. O projeto já tem `export_presets.cfg`; o template Windows x64 da Godot 4.7.2 está instalado localmente. `bash tools/export-windows.sh` gera `builds/windows/DeadWorks.exe` e `DeadWorks.pck`.
- O workflow baixa e verifica o template oficial da Godot, guarda apenas os arquivos Windows no cache do Actions e publica os dois arquivos como artefato `DeadWorks-Windows-x64`. Eles formam um build portátil e precisam ficar juntos. A execução remota do workflow depende de commit e push; o Windows gráfico ainda precisa ser testado no notebook.
- A importação headless da Godot 4.7.2 apresentou falha intermitente (`SIGSEGV`) nesta VM. O projeto define `editor/import/use_multiple_threads=false`; quatro importações sequenciais e a execução completa do teste passaram após esse ajuste. Se a falha voltar, verificar a versão da Godot e o processo de importação antes de tratar uma falha de CI como falha do jogo.
- Monitorar recursos com `htop`, `free -h` e `df -h / /home`. Manter builds e arquivos temporários do projeto em `/home`; a partição Docker já é separada.
- Os testes atuais validam produção, esteiras, dano e detecção. Gameplay, apresentação, áudio e desempenho gráfico precisam ser conferidos no notebook.
