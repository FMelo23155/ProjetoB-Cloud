#!/bin/bash
set -e

echo "Configurando PostgreSQL Secondary (Hot Standby)..."

# Aguardar primary estar disponível
echo "Aguardando PostgreSQL Primary estar disponível..."
until pg_isready -h postgres-primary -p 5432 -U postgres; do
  echo "Tentando conectar ao Primary..."
  sleep 5
done

echo "Primary disponível! Iniciando configuração do Secondary..."

# Limpar dados existentes
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
