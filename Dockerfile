FROM mcr.microsoft.com/powershell:lts-debian-10

COPY . .

EXPOSE 8080
ENTRYPOINT ["pwsh", "server.ps1"]