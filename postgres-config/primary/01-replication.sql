-- Configurar PostgreSQL para replicação
-- Executado automaticamente na inicialização

-- Criar utilizador de replicação se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
        CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_password';
    END IF;
END
$$;

-- Configurar parâmetros de replicação
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET synchronous_commit = 'off';
ALTER SYSTEM SET hot_standby = 'on';

-- Recarregar configuração
SELECT pg_reload_conf();

-- Verificar configuração
SELECT name, setting FROM pg_settings WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots');
