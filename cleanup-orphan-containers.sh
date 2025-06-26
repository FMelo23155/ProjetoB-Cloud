#!/bin/bash

echo "🧹 Limpando containers órfãos..."

# Para todos os containers não gerenciados pelo Swarm
echo "📋 Containers não gerenciados pelo Swarm:"
docker ps -a --filter "label!=com.docker.swarm.service.name" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -v "CONTAINER ID"

# Remove containers órfãos
echo "🗑️ Removendo containers órfãos..."
docker ps -a --filter "label!=com.docker.swarm.service.name" -q | xargs -r docker rm -f

# Limpa imagens não utilizadas
echo "🖼️ Limpando imagens não utilizadas..."
docker image prune -f

# Limpa volumes não utilizados
echo "💾 Limpando volumes não utilizados..."
docker volume prune -f

# Limpa networks não utilizadas
echo "🌐 Limpando networks não utilizadas..."
docker network prune -f

echo "✅ Limpeza concluída!"

# Verifica se há containers rodando fora do Swarm
echo ""
echo "🔍 Containers ativos após limpeza:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Labels}}"
