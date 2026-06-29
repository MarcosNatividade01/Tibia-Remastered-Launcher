# Tibia Remastered Launcher

Launcher publico do Tibia Remastered para preparar atualizacoes, iniciar MySQL, Apache, servidor local e abrir o client.

## Para jogar

Baixe o pacote pronto na pagina de Releases:

https://github.com/MarcosNatividade01/Tibia-Remastered-Launcher/releases/latest

Use o arquivo `TibiaRemastered-Friends-*.zip`. Extraia o ZIP, abra `Start Launcher.bat` e clique em `Jogar`.

Se baixar pelo botao `Code > Download ZIP`, abra `Start Launcher.bat`; ele baixa automaticamente o pacote jogavel da Release. Para baixar direto, use a pagina de Releases.

## Gerar novo pacote portatil

Para gerar um pacote atualizado a partir desta maquina:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-FriendPackage.ps1 -IncludeClient
```

Isso cria um ZIP em `C:\tmp\TibiaRemastered-Packages`.

Veja o guia completo em `Docs\PACOTE_AMIGOS.md`.

## Caminhos usados pelo launcher

- MySQL: `C:\xampp\mysql\bin\mysqld.exe`
- Apache: `C:\xampp\apache\bin\httpd.exe`
- Servidor: `C:\otserv\crystalserver.exe`
- Client: `C:\Users\%USERNAME%\Tibiafriends\bin\client-local.exe`

## Portas locais

- Apache/MyAAC: `80`
- MySQL: `3306`
- Login: `7171`
- Game: `7172`

## O que este repositorio contem

- Launcher
- Auto-update
- Manifest
- Documentacao
- Scripts de verificacao
- Estrutura base

## O que nao entra no GitHub

Por seguranca e privacidade, nao versionamos:

- Contas reais
- Personagens reais
- Banco de dados real
- Senhas
- Tokens
- Chaves
- Logs
- Backups
- Cache
- Saves

## Observacao sobre client e assets

Os arquivos completos do client e assets devem ser distribuidos apenas se voce tiver direito de redistribuicao. Este repositorio publico foi preparado para o launcher e estrutura segura.

