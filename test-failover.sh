#!/bin/bash
set -e

echo "🧪 Teste de Failover PostgreSQL High Availability"
echo "================================================"
echo "Data: $(date)"
echo

# Função para testar conexão
test_connection() {
    local desc=$1
    echo -n "🔍 Testando $desc... "
    
    if docker run --rm --network my_stack_webnet postgres:15 \
        psql -h postgres-ha -U cnv_user -d cnv_project \
        -c "SELECT 'Connection OK - ' || current_timestamp;" &>/dev/null; then
        echo "✅ SUCESSO"
        return 0
    else
        echo "❌ FALHA"
        return 1
    fi
}

# Função para verificar HAProxy stats
check_haproxy_stats() {
    echo "📊 Status HAProxy:"
    curl -s http://10.10.20.11:8404/stats 2>/dev/null | grep -E "(postgres-primary|postgres-secondary)" | 
    while read line; do
        if echo "$line" | grep -q "UP"; then
            echo "   ✅ $(echo "$line" | grep -o 'postgres-[^<]*')"
        else
            echo "   ❌ $(echo "$line" | grep -o 'postgres-[^<]*')"
        fi
    done || echo "   ⚠️  Não foi possível obter estatísticas"
}

# Função para inserir dados de teste
insert_test_data() {
    local message=$1
    echo "📝 Inserindo dados de teste: $message"
    
    docker run --rm --network my_stack_webnet postgres:15 \
        psql -h postgres-ha -U cnv_user -d cnv_project \
        -c "
        CREATE TABLE IF NOT EXISTS test_failover (
            id SERIAL PRIMARY KEY,
            timestamp TIMESTAMP DEFAULT NOW(),
            message TEXT
        );
        INSERT INTO test_failover (message) VALUES ('$message - $(date)');
        " &>/dev/null || echo "   ⚠️  Erro ao inserir dados"
}

# Função para contar registros
count_records() {
    echo -n "📊 Total de registros: "
    docker run --rm --network my_stack_webnet postgres:15 \
        psql -h postgres-ha -U cnv_user -d cnv_project \
        -c "SELECT COUNT(*) FROM test_failover;" -t 2>/dev/null | tr -d ' ' || echo "Erro"
}

echo "1️⃣ ESTADO INICIAL:"
echo "=================="
test_connection "Conexão inicial"
check_haproxy_stats
insert_test_data "Dados antes do failover"
count_records

echo ""
echo "2️⃣ SIMULANDO FALHA DO PRIMARY:"
echo "==============================="
echo "🛑 Parando PostgreSQL Primary..."
docker service scale my_stack_postgres-primary=0

echo "⏳ Aguardando detecção de falha (30 segundos)..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo

echo ""
echo "3️⃣ ESTADO APÓS FALHA:"
echo "====================="
test_connection "Conexão após falha"
check_haproxy_stats
insert_test_data "Dados durante failover"
count_records

echo ""
echo "4️⃣ RESTAURANDO PRIMARY:"
echo "======================="
echo "🔄 Reiniciando PostgreSQL Primary..."
docker service scale my_stack_postgres-primary=1

echo "⏳ Aguardando recuperação (60 segundos)..."
for i in {1..60}; do
    echo -n "."
    sleep 1
done
echo

echo ""
echo "5️⃣ ESTADO FINAL:"
echo "================"
test_connection "Conexão final"
check_haproxy_stats
insert_test_data "Dados após recuperação"
count_records

echo ""
echo "📋 RESUMO DO TESTE:"
echo "=================="
echo "✅ Teste de failover concluído!"
echo ""
echo "📊 Verificar dados inseridos:"
echo "docker run --rm --network my_stack_webnet postgres:15 \\"
echo "  psql -h postgres-ha -U cnv_user -d cnv_project \\"
echo "  -c \"SELECT * FROM test_failover ORDER BY timestamp;\""
echo ""
echo "🔍 Monitorar logs:"
echo "docker service logs my_stack_postgres-ha -f"
