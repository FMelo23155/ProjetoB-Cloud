#!/bin/bash
set -e

# Script para configurar PostgreSQL Standby/Replica

echo "🔄 Configurando PostgreSQL Standby (Secondary)..."

# Aguardar o primary estar pronto
echo "⏳ Aguardando PostgreSQL Primary ficar disponível..."
until pg_isready -h postgres-primary -U postgres; do
  echo "Aguardando primary..."
  sleep 5
done

echo "✅ Primary disponível!"

# Se não existe backup base, criar um
if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
    echo "📥 Criando backup base do Primary..."
    
    # Limpar dados existentes
    rm -rf /var/lib/postgresql/data/*
    
    # Criar diretório de archive se não existir
    mkdir -p /var/lib/postgresql/data/archive
    
    # Fazer backup base
    PGPASSWORD=repl_password pg_basebackup \
        -h postgres-primary \
        -D /var/lib/postgresql/data \
        -U replicator \
        -R -W -v -P
    
    echo "✅ Backup base criado!"
    
    # Configurar como standby
    echo "📝 Configurando como standby..."
    
    # Adicionar configurações específicas do standby
    cat >> /var/lib/postgresql/data/postgresql.conf << EOF

# Configurações de Standby
hot_standby = on
max_standby_streaming_delay = 30s
max_standby_archive_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = on
EOF

    echo "✅ Standby configurado!"
fi

echo "🚀 Iniciando PostgreSQL Standby..."
rm -rf /var/lib/postgresql/data/*

# Fazer backup base do primary
echo "Fazendo backup base do Primary..."
PGPASSWORD=repl_password pg_basebackup -h postgres-primary -D /var/lib/postgresql/data -U replicator -v -P -R

# Configurar recovery para hot standby
echo "Configurando Hot Standby..."
echo "primary_conninfo = 'host=postgres-primary port=5432 user=replicator password=repl_password application_name=standby1'" > /var/lib/postgresql/data/recovery.signal

# Configurar postgresql.conf para hot standby
echo "hot_standby = on" >> /var/lib/postgresql/data/postgresql.conf
echo "max_standby_streaming_delay = 30s" >> /var/lib/postgresql/data/postgresql.conf
echo "wal_receiver_status_interval = 10s" >> /var/lib/postgresql/data/postgresql.conf

# Permitir conexões locais
echo "local all all trust" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

echo "Configuração do Secondary concluída!"
