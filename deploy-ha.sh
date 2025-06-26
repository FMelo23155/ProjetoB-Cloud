#!/bin/bash
set -e

echo "🚀 Iniciando deplo# Parar stack atual se existir
if docker stack ls | grep -q my_stack; then
    echo "🛑 Parando stack atual..."
    docker stack rm my_stack
    
    # Aguardar remoção completa
    echo "⏳ Aguardando remoção completa..."
    while docker stack ls 2>/dev/null | grep -q my_stack; do
        sleep 2
        echo -n "."
    done
    echo
    echo "✅ Stack anterior removido"
    
    # Remover volumes antigos para evitar conflitos
    echo "🗑️ Limpando volumes antigos..."
    docker volume rm postgres_primary_data postgres_secondary_data 2>/dev/null || true
    
    # Aguardar limpeza adicional
    sleep 10
fi High Availability PostgreSQL..."
echo "Data: $(date)"
echo

# Verificar se estamos no manager
if ! docker node ls &>/dev/null; then
    echo "❌ Erro: Execute este script no nó manager do Docker Swarm!"
    echo "   Use: vagrant ssh manager01"
    exit 1
fi

echo "✅ Docker Swarm detectado"

# Fazer backup do stack atual se existir
if docker stack ls | grep -q my_stack; then
    echo "⚠️  Stack existente detectado. Fazendo backup..."
    docker stack ps my_stack > backup-stack-$(date +%Y%m%d-%H%M%S).txt 2>/dev/null || true
    echo "📄 Backup criado"
fi

# Verificar arquivos de configuração necessários
echo "🔍 Verificando arquivos de configuração..."

if [ ! -f "stack.yml" ]; then
    echo "❌ Erro: Arquivo stack.yml não encontrado no diretório atual"
    echo "   Certifique-se de estar no diretório correto: /vagrant"
    exit 1
fi

if [ ! -f "haproxy-config/haproxy.cfg" ]; then
    echo "❌ Erro: Arquivo haproxy-config/haproxy.cfg não encontrado!"
    exit 1
fi

if [ ! -f "postgres-config/primary/01-replication.sql" ]; then
    echo "❌ Erro: Arquivo postgres-config/primary/01-replication.sql não encontrado!"
    exit 1
fi

echo "✅ Arquivos de configuração encontrados"

# Parar stack atual se existir
if docker stack ls | grep -q my_stack; then
    echo "� Parando stack atual..."
    docker stack rm my_stack
    
    # Aguardar remoção completa
    echo "⏳ Aguardando remoção completa..."
    while docker stack ls 2>/dev/null | grep -q my_stack; do
        sleep 2
        echo -n "."
    done
    echo
    echo "✅ Stack anterior removido"
    
    # Aguardar limpeza adicional
    sleep 10
fi

# Deploy da nova configuração
echo "🎯 Fazendo deploy da configuração HA..."
docker stack deploy -c stack.yml my_stack

echo "⏳ Aguardando serviços iniciarem..."
sleep 20

# Verificar status dos serviços
echo ""
echo "📊 Status dos serviços:"
docker service ls

echo ""
echo "🔍 Verificando saúde dos serviços PostgreSQL..."

# Aguardar PostgreSQL Primary
for i in {1..20}; do
    if docker service ps my_stack_postgres-primary 2>/dev/null | grep -q "Running"; then
        echo "✅ PostgreSQL Primary iniciado"
        break
    fi
    echo "⏳ Aguardando PostgreSQL Primary... ($i/20)"
    sleep 3
done

# Aguardar PostgreSQL Secondary
for i in {1..25}; do
    if docker service ps my_stack_postgres-secondary 2>/dev/null | grep -q "Running"; then
        echo "✅ PostgreSQL Secondary iniciado"
        break
    fi
    echo "⏳ Aguardando PostgreSQL Secondary... ($i/25)"
    sleep 3
done

# Aguardar HAProxy
for i in {1..15}; do
    if docker service ps my_stack_postgres-ha 2>/dev/null | grep -q "Running"; then
        echo "✅ HAProxy iniciado"
        break
    fi
    echo "⏳ Aguardando HAProxy... ($i/15)"
    sleep 3
done

echo ""
echo "🎉 Deploy HA PostgreSQL concluído!"
echo ""
echo "� Endpoints disponíveis:"
echo "   • Aplicação PHP: http://10.10.20.11"
echo "   • HAProxy Stats: http://10.10.20.11:8404/stats"
echo "   • PostgreSQL HA: 10.10.20.11:5432"
echo "   • WebSocket: ws://10.10.20.11:8888"
echo ""
echo "🔍 Comandos para monitorar:"
echo "   docker service ls"
echo "   docker service logs my_stack_postgres-ha -f"
echo "   docker service logs my_stack_postgres-primary -f"
echo "   docker service logs my_stack_postgres-secondary -f"
echo ""
echo "🧪 Para testar failover:"
echo "   ./test-failover.sh"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • A aplicação agora conecta via postgres-ha (HAProxy)"
echo "   • Em caso de falha do primary, o secondary assume automaticamente"
echo "   • Monitor os logs para verificar funcionamento da replicação"
