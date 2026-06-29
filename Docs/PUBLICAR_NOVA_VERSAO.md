# Tibia Remastered Launcher

Launcher/updater com verificacao por SHA256, backup antes de substituir arquivos e preservacao de UserData, Logs e Backup.

## Como abrir

Execute `Start Launcher.bat`.

## Como configurar GitHub

Edite `Config/launcher-config.json`:

- `remoteVersionUrl`: URL raw do `version.json` no GitHub ou Release.
- `remoteManifestUrl`: URL raw do `manifest.json`.
- `serverExe`: executavel do servidor local.
- `clientExe`: executavel do cliente local.

Exemplo raw GitHub:

`https://raw.githubusercontent.com/USUARIO/REPO/main/version.json`
`https://raw.githubusercontent.com/USUARIO/REPO/main/manifest.json`

Para arquivos grandes, publique em GitHub Releases e coloque as URLs de download no manifest.

## Gerar manifest

Use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Tools\Generate-Manifest.ps1 -Version "0.1.1" -RawBaseUrl "https://raw.githubusercontent.com/USUARIO/REPO/main"
```

O script ignora `UserData`, `Logs`, `Backup`, temporarios, cache, crash dumps e arquivos sensiveis.

## Publicar nova versao

1. Atualize arquivos publicaveis em `Client`, `Server`, `Data`, `Config`, `Launcher` ou `Docs`.
2. Gere o manifest.
3. Publique `manifest.json`, `version.json` e arquivos no GitHub.
4. Para arquivos grandes, use GitHub Releases e ajuste URLs no manifest.

## Como o update funciona

Para cada arquivo do manifest:

1. Calcula SHA256 local.
2. Compara com SHA256 remoto.
3. Baixa apenas se ausente ou diferente.
4. Valida SHA256 apos download.
5. Faz backup antes de substituir.
6. Se falhar, restaura backup automaticamente.

## Arquivos protegidos

Nunca sobrescreve automaticamente:

- UserData/
- Logs/
- Backup/
- banco real
- saves
- configs pessoais locais

## Reparar arquivos

Clique em `Atualizar/Reparar` no Launcher. Ele recalcula hashes e baixa arquivos corrompidos ou ausentes.

## Jogar

Clique em `Jogar`. O Launcher verifica update, inicia o servidor local, espera as portas configuradas e abre o cliente.

## Limitacoes

- O link do GitHub precisa ser configurado manualmente uma vez em `launcher-config.json`.
- Esta primeira versao usa PowerShell/WinForms para simplicidade e facil manutencao.
- O launcher nao instala MySQL/XAMPP/MyAAC; ele parte da estrutura local ja existente ou dos arquivos publicados no manifest.
