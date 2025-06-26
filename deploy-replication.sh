#!/bin/bash

echo "🚀 Deploy PostgreSQL com Streaming Replication"
echo "=============================================="

# Parar stack atual
echo "🛑 Parando stack atual..."
docker stack rm my_stack 2>/dev/null || true
sleep 30

# Limpar containers órfãos
echo "🧹 Limpando containers órfãos..."
chmod +x cleanup-orphan-containers.sh
./cleanup-orphan-containers.sh

# Criar volumes nomeados se não existirem
echo "💾 Criando volumes de dados..."
docker volume create postgres_primary_data 2>/dev/null || true
docker volume create postgres_secondary_data 2>/dev/null || true

# Verificar se os arquivos de configuração existem
echo "📋 Verificando configurações..."
if [ ! -f "postgres-config/primary/postgresql.conf" ]; then
    echo "❌ Arquivo postgresql.conf não encontrado!"
    exit 1
fi

if [ ! -f "postgres-config/primary/pg_hba.conf" ]; then
    echo "❌ Arquivo pg_hba.conf não encontrado!"
    exit 1
fi

if [ ! -f "postgres-config/secondary/setup-replica.sh" ]; then
    echo "❌ Script setup-replica.sh não encontrado!"
    exit 1
fi

# Tornar scripts executáveis
chmod +x postgres-config/secondary/setup-replica.sh

echo "✅ Configurações verificadas!"

# Deploy do stack
echo "🚀 Fazendo deploy do stack..."
docker stack deploy -c stack.yml my_stack

# Aguardar serviços subirem
echo "⏳ Aguardando serviços iniciarem..."
sleep 60

# Verificar status
echo "📊 Status dos serviços:"
docker service ls

echo ""
echo "🔍 Verificando logs do Primary:"
docker service logs my_stack_postgres-primary --tail 5

echo ""
echo "🔍 Verificando logs do Secondary:"
docker service logs my_stack_postgres-secondary --tail 5

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "🌐 Acesse:"
echo "   • Aplicação: http://10.10.20.11"
echo "   • HAProxy Stats: http://10.10.20.11:8404/stats"
echo "   • Portainer: http://10.10.20.11:9000"
echo ""
echo "🧪 Para testar replicação:"
echo "   • Inserir dados no Primary"
echo "   • Verificar se aparecem no Secondary"
echo "   • Simular falha: docker service scale my_stack_postgres-primary=0"
echo "   • Verificar failover automático"
