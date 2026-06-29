# Instalacao para amigos

## Requisitos

- Windows 10 ou 11 64-bit
- XAMPP instalado em `C:\xampp`
- Arquivos do servidor em `C:\otserv`
- Arquivos do client em `C:\Users\SEU_USUARIO\Tibiafriends`

## Passo a passo

1. Baixe o ZIP do GitHub.
2. Extraia para `C:\TibiaRemastered`.
3. Confirme que existe `C:\xampp\mysql\bin\mysqld.exe`.
4. Confirme que existe `C:\xampp\apache\bin\httpd.exe`.
5. Confirme que existe `C:\otserv\crystalserver.exe`.
6. Confirme que existe `C:\Users\SEU_USUARIO\Tibiafriends\bin\client-local.exe`.
7. Execute `Start Launcher.bat`.
8. Clique em `Jogar`.

## Se aparecer "Connection refused"

Verifique se as portas estao abertas:

```powershell
netstat -ano | findstr /R ":80 :3306 :7171 :7172"
```

O launcher deve iniciar automaticamente:

- Apache na porta `80`
- MySQL na porta `3306`
- Crystal Server nas portas `7171` e `7172`

## Se os sprites sumirem

Feche o client e abra novamente pelo launcher atualizado. O launcher usa `QSG_RENDER_LOOP=basic` e nao forca renderizacao software.
