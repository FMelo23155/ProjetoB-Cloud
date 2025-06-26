#!/bin/bash

echo "🔍 Status PostgreSQL High Availability"
echo "======================================"
echo "Data: $(date)"
echo

# Verificar se o stack está rodando
if ! docker stack ls | grep -q my_stack; then
    echo "❌ Stack my_stack não está rodando"
    echo "   Execute: ./deploy-ha.sh"
    exit 1
fi

echo "📊 Status dos Serviços:"
echo "======================"
docker service ls --filter "name=my_stack" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"

echo ""
echo "🔍 Detalhes dos Serviços PostgreSQL:"
echo "===================================="
echo "Primary:"
docker service ps my_stack_postgres-primary --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}"

echo ""
echo "Secondary:"
docker service ps my_stack_postgres-secondary --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}"

echo ""
echo "HAProxy:"
docker service ps my_stack_postgres-ha --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}"

echo ""
echo "🧪 Teste de Conexão:"
echo "===================="
if docker run --rm --network my_stack_webnet postgres:15 \
   psql -h postgres-ha -U cnv_user -d cnv_project \
   -c "SELECT 'PostgreSQL HA funcionando! - ' || current_timestamp;" 2>/dev/null; then
    echo "✅ Conexão com PostgreSQL HA: SUCESSO"
else
    echo "❌ Conexão com PostgreSQL HA: FALHA"
fi

echo ""
echo "📊 HAProxy Statistics:"
echo "====================="
echo "URL: http://10.10.20.11:8404/stats"
echo ""
curl -s http://10.10.20.11:8404/stats 2>/dev/null | grep -E "(postgres-primary|postgres-secondary)" | 
while read line; do
    if echo "$line" | grep -q "UP"; then
        echo "✅ $(echo "$line" | grep -o 'postgres-[^<]*') - UP"
    else
        echo "❌ $(echo "$line" | grep -o 'postgres-[^<]*') - DOWN"
    fi
done || echo "⚠️  Não foi possível obter estatísticas HAProxy"

echo ""
echo "🔗 Endpoints:"
echo "============"
echo "• Aplicação: http://10.10.20.11"
echo "• HAProxy Stats: http://10.10.20.11:8404/stats"
echo "• PostgreSQL HA: 10.10.20.11:5432"
echo ""
echo "📋 Comandos úteis:"
echo "=================="
echo "• Ver logs HAProxy: docker service logs my_stack_postgres-ha -f"
echo "• Ver logs Primary: docker service logs my_stack_postgres-primary -f"
echo "• Ver logs Secondary: docker service logs my_stack_postgres-secondary -f"
echo "• Testar failover: ./test-failover.sh"
