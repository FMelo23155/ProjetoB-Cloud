# Script para verificar e configurar o Portainer no Docker Swarm
# Este script garante que o Portainer esteja sempre disponível

Write-Host "🚀 Configurando Portainer no Docker Swarm..." -ForegroundColor Green
Write-Host "Data: $(Get-Date)" -ForegroundColor Gray

# Navegar para o diretório do projeto
Set-Location "c:\Users\aluno23155\Desktop\CNV-ProjetoB-main"

# Verificar se o Docker Swarm está ativo
Write-Host "🔍 Verificando Docker Swarm..." -ForegroundColor Cyan
$swarmStatus = vagrant ssh manager01 -c "docker info --format '{{.Swarm.LocalNodeState}}'" 2>$null

if ($swarmStatus -ne "active") {
    Write-Host "❌ Docker Swarm não está ativo!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker Swarm ativo" -ForegroundColor Green

# Verificar se o Portainer já está instalado
Write-Host "🔍 Verificando se Portainer está instalado..." -ForegroundColor Cyan
$portainerExists = vagrant ssh manager01 -c "docker stack ls | grep portainer" 2>$null

if ($portainerExists) {
    Write-Host "✅ Portainer já está instalado" -ForegroundColor Green
    Write-Host "🔄 Reiniciando Portainer..." -ForegroundColor Yellow
    vagrant ssh manager01 -c "docker service update --force portainer_portainer"
} else {
    Write-Host "📥 Instalando Portainer..." -ForegroundColor Yellow
    
    # Baixar e instalar Portainer
    vagrant ssh manager01 -c "curl -L https://downloads.portainer.io/ce2-19/portainer-agent-stack.yml -o portainer-agent-stack.yml"
    vagrant ssh manager01 -c "docker stack deploy -c portainer-agent-stack.yml portainer"
    
    Write-Host "✅ Portainer instalado com sucesso!" -ForegroundColor Green
}

# Aguardar serviços subirem
Write-Host "⏳ Aguardando serviços iniciarem..." -ForegroundColor Yellow
Start-Sleep 15

# Verificar status final
Write-Host "📊 Status final dos serviços:" -ForegroundColor Cyan
vagrant ssh manager01 -c "docker service ls"

Write-Host ""
Write-Host "🎉 Configuração concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Acesse o Portainer em:" -ForegroundColor Green
Write-Host "   • HTTP:  http://10.10.20.11:9000" -ForegroundColor White
Write-Host "   • HTTPS: https://10.10.20.11:9443" -ForegroundColor White
Write-Host ""
Write-Host "📝 Outros serviços disponíveis:" -ForegroundColor Cyan
Write-Host "   • Aplicação: http://10.10.20.11" -ForegroundColor White
Write-Host "   • HAProxy Stats: http://10.10.20.11:8404/stats" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Nota: Se o Portainer apresentar timeout, execute:" -ForegroundColor Yellow
Write-Host "   .\restart-portainer.ps1" -ForegroundColor White
