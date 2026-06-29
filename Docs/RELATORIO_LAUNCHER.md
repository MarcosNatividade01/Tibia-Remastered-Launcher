# Relatorio - Launcher Profissional com Auto-Update

## Resumo

Foi criada uma primeira versao funcional do Launcher/Updater em PowerShell com interface WinForms simples, verificacao por SHA256, download por manifest remoto, backup antes de substituir arquivos, restauracao automatica em falha e preservacao de pastas protegidas.

## Arquivos criados

- Start Launcher.bat
- Launcher/Launcher.ps1
- Launcher/Tools/Generate-Manifest.ps1
- Config/launcher-config.json
- version.json
- manifest.json
- README.md
- Docs/PUBLICAR_NOVA_VERSAO.md
- Docs/RELATORIO_LAUNCHER.md
- .gitignore

## Estrutura criada

- Launcher/
- Client/
- Server/
- Data/
- Config/
- Database_Template/
- UserData/Database/
- UserData/Config/
- UserData/Saves/
- Logs/
- Backup/
- Docs/

## Como abrir

Execute:

Start Launcher.bat

## Como configurar GitHub

Edite:

Config/launcher-config.json

Preencha:

- remoteVersionUrl
- remoteManifestUrl

Exemplo:

https://raw.githubusercontent.com/USUARIO/REPO/main/version.json
https://raw.githubusercontent.com/USUARIO/REPO/main/manifest.json

Para arquivos grandes, use GitHub Releases e coloque a URL direta no campo `url` de cada arquivo no manifest.

## Como gerar manifest

Execute dentro da pasta Tibia Remastered:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Tools\Generate-Manifest.ps1 -Version "0.1.1" -RawBaseUrl "https://raw.githubusercontent.com/USUARIO/REPO/main"

## Como publicar nova versao

1. Atualize arquivos publicaveis.
2. Rode Generate-Manifest.ps1 com a nova versao.
3. Publique version.json, manifest.json e arquivos no GitHub.
4. Para arquivos grandes, publique em Releases.
5. Abra o launcher em outra maquina e clique Atualizar/Reparar.

## Como outro jogador instala

O jogador baixa apenas um pacote inicial contendo o Launcher e a configuracao. Depois executa Start Launcher.bat. O launcher baixa/repara os arquivos pelo manifest remoto.

## Como o update verifica arquivos

Para cada arquivo do manifest:

1. Verifica se existe localmente.
2. Calcula SHA256 local.
3. Compara com SHA256 remoto.
4. Baixa se ausente ou diferente.
5. Valida SHA256 apos download.
6. Faz backup antes de substituir.
7. Restaura backup se falhar.

## Arquivos protegidos

O launcher preserva:

- UserData/
- Logs/
- Backup/

O .gitignore tambem protege banco real, saves, logs, crash dumps, cache, tokens e arquivos temporarios.

## Como restaurar backup

Backups ficam em:

Backup/update_YYYY-MM-DD_HH-MM-SS/

Se um update falhar, o launcher restaura automaticamente. Para restauracao manual, copie o conteudo do backup desejado de volta para a raiz do projeto.

## Testes realizados

- Self-test do launcher: OK.
- Gerador de manifest: OK.
- Download por manifest via HTTP local: OK.
- Reparo de arquivo corrompido: OK.
- Preservacao de UserData: OK.
- Backup antes de substituir arquivo corrompido: OK.
- Caminho do servidor configurado existe: OK.
- Caminho do cliente configurado existe: OK.

## Testes pendentes

- GitHub real indisponivel: depende do repositorio remoto configurado.
- Download interrompido em rede real: depende do repositorio remoto configurado.
- Funcionamento em outro computador: depende de pacote publicado no GitHub/Releases.
- Botao Jogar abrindo cliente em sessao real: a logica esta implementada e os paths existem, mas nao abri o cliente agora para nao interromper seu uso.

## Limitacoes conhecidas

- Primeira versao usa PowerShell/WinForms, nao um executavel compilado.
- Links GitHub ainda precisam ser preenchidos.
- Nao instala XAMPP/MyAAC/MySQL automaticamente.
- Banco real deve ficar em UserData/Database para nao ser sobrescrito.

## Melhorias futuras recomendadas

- Criar executavel .NET/WPF assinado.
- Download com progresso por arquivo em tempo real.
- Suporte a GitHub Releases API.
- Canal stable/beta.
- Auto-update do proprio launcher com etapa segura separada.
- Tela de configuracoes mais completa.
