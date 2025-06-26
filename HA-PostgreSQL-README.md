# PostgreSQL High Availability Setup

## 🎯 Objetivo
Configuração de alta disponibilidade para PostgreSQL com failover automático usando Docker Swarm, HAProxy e streaming replication.

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Aplicação     │    │     HAProxy     │    │   PostgreSQL    │
│   (3 replicas)  │───▶│  (Load Balance) │───▶│   Primary       │
│                 │    │                 │    │   (Manager1)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │ Streaming
                                │                       │ Replication
                                │                       ▼
                                │            ┌─────────────────┐
                                └───────────▶│   PostgreSQL    │
                                             │   Secondary     │
                                             │   (worker01)    │
                                             └─────────────────┘
```

## 📦 Componentes

### 1. PostgreSQL Primary
- **Localização**: Manager1 (nó manager)
- **Função**: Servidor principal de escrita
- **Configuração**: Streaming replication habilitada
- **Porta**: 5432 (interna)

### 2. PostgreSQL Secondary
- **Localização**: worker01 (nó worker)
- **Função**: Hot standby para failover automático
- **Configuração**: Réplica do primary em tempo real
- **Porta**: 5432 (interna)

### 3. HAProxy
- **Localização**: Manager (nó manager)
- **Função**: Load balancer com failover automático
- **Porta**: 5432 (aplicação), 8404 (stats)
- **Algoritmo**: Prioridade (primary first, secondary backup)

## 🚀 Deploy

### 1. Executar o deploy
```bash
# Dar permissões de execução
chmod +x deploy-ha.sh

# Executar deploy
./deploy-ha.sh
```

### 2. Verificar status
```bash
# Ver serviços
docker service ls

# Ver detalhes dos serviços PostgreSQL
docker service ps my_stack_postgres-primary
docker service ps my_stack_postgres-secondary
docker service ps my_stack_postgres-ha

# Ver logs
docker service logs my_stack_postgres-primary
docker service logs my_stack_postgres-secondary
docker service logs my_stack_postgres-ha
```

## 🔍 Monitoramento

### 1. HAProxy Statistics
- **URL**: http://localhost:8404/stats
- **Info**: Estado dos servidores, conexões ativas, failovers

### 2. Status de Replicação
```bash
# No primary - verificar replicação
docker exec -it $(docker ps --filter "name=postgres-primary" --format "{{.ID}}" | head -1) \
    psql -U cnv_user -d cnv_project -c "SELECT * FROM pg_stat_replication;"

# Verificar lag de replicação
docker exec -it $(docker ps --filter "name=postgres-primary" --format "{{.ID}}" | head -1) \
    psql -U cnv_user -d cnv_project -c "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;"
```

### 3. Teste de Conexão
```bash
# Testar via HAProxy
docker exec -it $(docker ps --filter "name=postgres-ha" --format "{{.ID}}" | head -1) \
    pg_isready -h postgres-ha -p 5432 -U cnv_user

# Testar primary diretamente
docker exec -it $(docker ps --filter "name=postgres-primary" --format "{{.ID}}" | head -1) \
    pg_isready -h postgres-primary -p 5432 -U cnv_user

# Testar secondary diretamente
docker exec -it $(docker ps --filter "name=postgres-secondary" --format "{{.ID}}" | head -1) \
    pg_isready -h postgres-secondary -p 5432 -U cnv_user
```

## 🔄 Teste de Failover

### 1. Executar teste automático
```bash
chmod +x test-failover.sh
./test-failover.sh
```

### 2. Simular falha do primary
```bash
# Parar primary
docker service scale my_stack_postgres-primary=0

# Verificar se secondary assumiu
curl http://localhost:8404/stats

# Testar aplicação (deve continuar funcionando)
curl http://localhost
```

### 3. Restaurar primary
```bash
# Reiniciar primary
docker service scale my_stack_postgres-primary=1

# Verificar se voltou ao estado normal
docker service ps my_stack_postgres-primary
```

## 🛠️ Configuração da Aplicação

### 1. Conexão via HA
A aplicação agora conecta via `postgres-ha:5432` em vez de `postgres:5432`.

### 2. Configuração PHP com Retry
```php
// Usar nova classe DatabaseHA
require_once 'db-ha.php';

$dbHA = new DatabaseHA();
$pdo = $dbHA->getConnection();

// Ou usar função de compatibilidade
$pdo = getDbConnection();
```

### 3. Variáveis de Ambiente
```bash
DB_HOST=postgres-ha
DB_PORT=5432
DB_NAME=cnv_project
DB_USER=cnv_user
DB_PASS=cnv_password
```

## 🚨 Troubleshooting

### 1. Primary não inicia
```bash
# Verificar logs
docker service logs my_stack_postgres-primary

# Verificar se porta está ocupada
docker ps --filter "publish=5432"

# Verificar volume
docker volume ls | grep postgres
```

### 2. Secondary não replica
```bash
# Verificar logs do secondary
docker service logs my_stack_postgres-secondary

# Verificar conectividade
docker exec -it $(docker ps --filter "name=postgres-secondary" --format "{{.ID}}" | head -1) \
    pg_isready -h postgres-primary -p 5432

# Verificar usuário de replicação
docker exec -it $(docker ps --filter "name=postgres-primary" --format "{{.ID}}" | head -1) \
    psql -U cnv_user -d cnv_project -c "SELECT * FROM pg_user WHERE usename = 'replicator';"
```

### 3. HAProxy não conecta
```bash
# Verificar configuração
docker exec -it $(docker ps --filter "name=postgres-ha" --format "{{.ID}}" | head -1) \
    cat /usr/local/etc/haproxy/haproxy.cfg

# Verificar logs
docker service logs my_stack_postgres-ha

# Testar portas
docker exec -it $(docker ps --filter "name=postgres-ha" --format "{{.ID}}" | head -1) \
    nc -zv postgres-primary 5432
```

## 📊 Monitoramento de Performance

### 1. Métricas PostgreSQL
```sql
-- Verificar conexões ativas
SELECT count(*) FROM pg_stat_activity;

-- Verificar lag de replicação
SELECT client_addr, state, 
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as lag
FROM pg_stat_replication;

-- Verificar queries lentas
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC LIMIT 10;
```

### 2. Métricas HAProxy
- **Stats URL**: http://localhost:8404/stats
- **Health Check**: http://localhost:8405/health
- **Logs**: `docker service logs my_stack_postgres-ha`

## 🔐 Segurança

### 1. Senhas
- **PostgreSQL**: cnv_password
- **Replicação**: repl_password
- **Alterar em produção**: Modificar variáveis de ambiente

### 2. Rede
- **Comunicação interna**: Rede overlay `webnet`
- **Exposição externa**: Apenas porta 5432 via HAProxy

### 3. Volumes
- **Primary**: `postgres_primary_data`
- **Secondary**: `postgres_secondary_data`
- **Backup**: Implementar rotina de backup regular

## 🎯 Benefícios

✅ **Alta Disponibilidade**: Failover automático em caso de falha
✅ **Zero Downtime**: Aplicação continua funcionando durante failover
✅ **Dados Sincronizados**: Streaming replication em tempo real
✅ **Monitoramento**: Interface web para acompanhar status
✅ **Compatibilidade**: Funciona com código PHP existente
✅ **Escalabilidade**: Pode adicionar mais réplicas conforme necessário

## 📋 Checklist Pós-Deploy

- [ ] Todos os serviços estão running
- [ ] HAProxy stats acessível (http://localhost:8404/stats)
- [ ] Aplicação conecta via postgres-ha
- [ ] Replicação funcionando (verificar pg_stat_replication)
- [ ] Teste de failover executado com sucesso
- [ ] Logs sem erros críticos
- [ ] Backup strategy implementada
- [ ] Monitoramento configurado
