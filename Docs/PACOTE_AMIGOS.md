# Pacote portatil para amigos

Este repositorio publico contem o launcher, scripts e documentacao. Para seus amigos jogarem sem instalar XAMPP, gere um pacote portatil no seu PC.

## Gerar pacote completo

Abra PowerShell como Administrador e rode dentro da pasta do repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-FriendPackage.ps1 -IncludeClient
```

Isso gera um ZIP em:

```text
C:\tmp\TibiaRemastered-Packages
```

## Como o amigo joga

1. Extrai o ZIP em uma pasta simples, por exemplo `C:\TibiaRemastered-Friends`.
2. Abre `Start Launcher.bat`.
3. Clica em `Jogar`.

O pacote leva um runtime portatil em `Runtime\xampp`, entao nao precisa instalar XAMPP. O launcher inicia MySQL, Apache/PHP, servidor e client automaticamente. Na primeira execucao ele cria/importa um banco limpo local.

## O que fica de fora

O pacote exclui contas reais, personagens reais, banco real com dados, senhas, tokens, chaves, logs, backups, cache, minimap e arquivos temporarios.

## Observacao

Client/assets completos devem ser distribuidos apenas quando voce tiver direito de redistribuicao. O GitHub publico fica com launcher/scripts; o ZIP completo gerado localmente e o arquivo que voce envia aos amigos.
