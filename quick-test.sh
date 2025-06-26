#!/bin/bash

echo "🔍 === VERIFICAÇÃO RÁPIDA DE HA ==="
echo "Data: $(date)"
echo

# Verificar se estamos no manager
if ! docker node ls &>/dev/null; then
    echo "❌ Execute este script no manager: vagrant ssh manager01"
    exit 1
fi

echo "✅ Docker Swarm OK"

# Verificar status dos serviços
echo "📊 Status dos serviços PostgreSQL:"
echo "================================="
docker service ls | grep -E "(postgres|redis|php|server-ws)" | while read line; do
    if echo "$line" | grep -q "1/1\|3/3"; then
        echo "✅ $line"
    else
        echo "⚠️  $line"
    fi
done

echo ""
echo "🌐 Testando aplicação web:"
if curl -s -o /dev/null -w "%{http_code}" http://10.10.20.11/ | grep -q "200"; then
    echo "✅ Aplicação web: OK (http://10.10.20.11)"
else
    echo "❌ Aplicação web: FALHA"
fi

echo ""
echo "📊 HAProxy Stats:"
echo "=================="
echo "URL: http://10.10.20.11:8404/stats"

# Verificar HAProxy stats
if curl -s http://10.10.20.11:8404/stats > /dev/null 2>&1; then
    echo "✅ HAProxy Stats: ACESSÍVEL"
    
    # Extrair status dos servidores PostgreSQL
    if curl -s http://10.10.20.11:8404/stats | grep -q "postgres-primary.*UP"; then
        echo "✅ PostgreSQL Primary: UP"
    else
        echo "❌ PostgreSQL Primary: DOWN"
    fi
    
    if curl -s http://10.10.20.11:8404/stats | grep -q "postgres-secondary.*UP"; then
        echo "✅ PostgreSQL Secondary: UP"
    else
        echo "⚠️  PostgreSQL Secondary: DOWN (normal se ainda estiver configurando)"
    fi
else
    echo "❌ HAProxy Stats: INACESSÍVEL"
fi

echo ""
echo "🎯 Próximos passos:"
echo "=================="
echo "1. Se tudo estiver OK, teste o failover:"
echo "   ./test-failover.sh"
echo ""
echo "2. Para monitorar logs:"
echo "   docker service logs my_stack_postgres-ha -f"
echo ""
echo "3. Para simular falha:"
echo "   docker service scale my_stack_postgres-primary=0"
echo "   (Restaurar: docker service scale my_stack_postgres-primary=1)"
