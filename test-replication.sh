#!/bin/bash

echo "🧪 Testando Replicação PostgreSQL"
echo "================================="

# Função para executar SQL
execute_sql() {
    local server=$1
    local sql=$2
    local db=${3:-cnv_project}
    
    docker run --rm --network my_stack_webnet -e PGPASSWORD=cnv_password postgres:15 \
        psql -h $server -U cnv_user -d $db -c "$sql"
}

# Teste 1: Verificar conectividade
echo "📡 Teste 1: Verificando conectividade..."
echo "Primary:"
if docker run --rm --network my_stack_webnet postgres:15 pg_isready -h postgres-primary -p 5432; then
    echo "✅ Primary: ONLINE"
else
    echo "❌ Primary: OFFLINE"
fi

echo "Secondary:"
if docker run --rm --network my_stack_webnet postgres:15 pg_isready -h postgres-secondary -p 5432; then
    echo "✅ Secondary: ONLINE"
else
    echo "❌ Secondary: OFFLINE"
fi

echo "HAProxy:"
if docker run --rm --network my_stack_webnet postgres:15 pg_isready -h postgres-ha -p 5432; then
    echo "✅ HAProxy: ONLINE"
else
    echo "❌ HAProxy: OFFLINE"
fi

echo ""

# Teste 2: Verificar replicação
echo "📝 Teste 2: Verificando replicação..."

# Inserir dados no Primary
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
echo "Inserindo dados no Primary..."
execute_sql postgres-primary "INSERT INTO messages (message) VALUES ('Teste replicação $timestamp');"

echo "Aguardando replicação..."
sleep 5

# Verificar dados no Secondary
echo "Verificando dados no Secondary..."
result=$(execute_sql postgres-secondary "SELECT COUNT(*) FROM messages WHERE message LIKE '%Teste replicação%';" 2>/dev/null || echo "0")

if [ "$result" -gt "0" ]; then
    echo "✅ Replicação funcionando! Dados sincronizados."
else
    echo "❌ Replicação com problemas. Dados não sincronizados."
fi

echo ""

# Teste 3: Verificar status de replicação
echo "📊 Teste 3: Status de replicação..."
echo "Status no Primary:"
execute_sql postgres-primary "SELECT client_addr, state, sync_state FROM pg_stat_replication;" 2>/dev/null || echo "Sem replicas conectadas"

echo ""
echo "Status no Secondary:"
execute_sql postgres-secondary "SELECT pg_is_in_recovery();" 2>/dev/null || echo "Erro ao verificar status"

echo ""

# Teste 4: Teste de failover
echo "🔄 Teste 4: Simulando failover..."
echo "Colocando Primary offline..."
docker service scale my_stack_postgres-primary=0

echo "Aguardando failover..."
sleep 15

# Testar conexão via HAProxy (deve ir para Secondary)
echo "Testando conexão via HAProxy (deve usar Secondary)..."
if execute_sql postgres-ha "SELECT 'Failover test' as status;" >/dev/null 2>&1; then
    echo "✅ Failover funcionando! Secondary assumiu o controle."
else
    echo "❌ Failover com problemas."
fi

echo ""
echo "Restaurando Primary..."
docker service scale my_stack_postgres-primary=1

echo "Aguardando Primary voltar..."
sleep 30

echo ""
echo "🏁 Teste de replicação concluído!"
echo ""
echo "📊 Status final dos serviços:"
docker service ls | grep postgres
