# Script para reiniciar o Portainer quando ocorrer timeout
# Executar este script quando o Portainer apresentar timeout

Write-Host "🔄 Reiniciando Portainer..." -ForegroundColor Yellow
Write-Host "Data: $(Get-Date)" -ForegroundColor Gray

# Navegar para o diretório do projeto
Set-Location "c:\Users\aluno23155\Desktop\CNV-ProjetoB-main"

# Verificar se as VMs estão rodando
Write-Host "📋 Verificando status das VMs..." -ForegroundColor Cyan
vagrant status

# Verificar se o Portainer está rodando
Write-Host "🔍 Verificando serviços do Portainer..." -ForegroundColor Cyan
vagrant ssh manager01 -c "docker service ls | grep portainer"

# Reiniciar o serviço do Portainer
Write-Host "🔄 Reiniciando serviço do Portainer..." -ForegroundColor Yellow
vagrant ssh manager01 -c "docker service update --force portainer_portainer"

# Aguardar alguns segundos
Start-Sleep 10

# Verificar se o serviço está rodando
Write-Host "✅ Verificando status após reinicialização..." -ForegroundColor Green
vagrant ssh manager01 -c "docker service ps portainer_portainer"

Write-Host ""
Write-Host "🌐 Portainer deve estar disponível em:" -ForegroundColor Green
Write-Host "   • http://10.10.20.11:9000" -ForegroundColor White
Write-Host "   • https://10.10.20.11:9443" -ForegroundColor White
Write-Host ""
Write-Host "💡 Dica: O Portainer pode fazer timeout por segurança após períodos de inatividade." -ForegroundColor Yellow
Write-Host "   Execute este script sempre que necessário." -ForegroundColor Yellow
