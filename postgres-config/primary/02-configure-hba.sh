#!/bin/bash
# Script executado após a inicialização do PostgreSQL Primary

echo "Configurando pg_hba.conf para replicação..."

# Adicionar configurações de acesso para replicação
echo "host replication replicator 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

# Recarregar configuração
psql -U postgres -c "SELECT pg_reload_conf();"

echo "Configuração do Primary concluída!"
