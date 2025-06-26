#!/bin/bash
# Script para sincronizar tabelas entre Primary e Secondary via HAProxy

echo "=== Sincronização de Tabelas PostgreSQL HA ==="

# Primeiro, vamos escalar o Primary para 0 para forçar conexão ao Secondary
echo "1. Escalando Primary para 0 para conectar ao Secondary..."
docker service scale my_stack_postgres-primary=0

# Aguardar alguns segundos para o failover
echo "2. Aguardando failover..."
sleep 10

# Criar um container temporário para executar comandos SQL
echo "3. Criando tabelas no Secondary via HAProxy..."
docker run --rm --network my_stack_webnet \
  -e PGPASSWORD=cnv_password \
  postgres:15 \
  psql -h postgres-ha -p 5432 -U cnv_user -d cnv_project \
  -c "
  CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      message TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  CREATE TABLE IF NOT EXISTS php_sessions (
      sess_id VARCHAR(128) PRIMARY KEY,
      sess_data TEXT,
      sess_time INTEGER NOT NULL
  );
  
  CREATE TABLE IF NOT EXISTS sessions (
      id VARCHAR(128) PRIMARY KEY,
      data TEXT,
      last_access TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  CREATE TABLE IF NOT EXISTS uploads (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) NOT NULL,
      original_name VARCHAR(255) NOT NULL,
      file_path VARCHAR(500) NOT NULL,
      file_size INT,
      mime_type VARCHAR(100),
      uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  INSERT INTO messages (message) VALUES 
  ('SECONDARY: PostgreSQL backup funcionando com HAProxy!'),
  ('Sistema de Alta Disponibilidade testado com sucesso!')
  ON CONFLICT DO NOTHING;
  "

echo "4. Restaurando Primary..."
docker service scale my_stack_postgres-primary=1

echo "5. Aguardando Primary estabilizar..."
sleep 15

echo "=== Sincronização concluída! ==="
echo "Teste o failover com: docker service scale my_stack_postgres-primary=0"
