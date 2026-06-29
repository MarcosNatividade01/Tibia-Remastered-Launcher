# Pacote para amigos

Este repositorio publico contem o launcher, scripts e documentacao. Para seus amigos jogarem igual no seu PC, gere um pacote local com servidor, site/API, banco limpo e, se voce tiver direito de redistribuicao, o client.

## Gerar pacote no seu PC

Abra PowerShell como Administrador e rode dentro da pasta do repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-FriendPackage.ps1
```

Isso gera um ZIP em:

```text
C:\tmp\TibiaRemastered-Packages
```

Por padrao o client completo nao entra no ZIP. Para incluir o client local de `C:\Users\%USERNAME%\Tibiafriends`, rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-FriendPackage.ps1 -IncludeClient
```

Inclua o client apenas se voce tiver direito de distribuir esses arquivos.

## Instalar no PC do amigo

1. Instale o XAMPP em `C:\xampp`.
2. Extraia o ZIP gerado.
3. Abra PowerShell como Administrador na pasta extraida.
4. Rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\Install-FriendPackage.ps1
```

5. Abra `Launcher\Start Launcher.bat`.
6. Clique em `Atualizar/Reparar`.
7. Clique em `Jogar`.

## O que fica de fora

O pacote exclui contas reais, personagens, banco real com dados, senhas, tokens, chaves, logs, backups, cache, minimap e arquivos temporarios.
