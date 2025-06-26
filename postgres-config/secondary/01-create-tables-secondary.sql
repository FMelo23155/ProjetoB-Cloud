-- Script para criar as tabelas necessárias no PostgreSQL Secondary
-- Executado após a replicação ser estabelecida

-- Criar tabela de mensagens se não existir
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criar tabela para o handler de sessões PHP personalizado
CREATE TABLE IF NOT EXISTS php_sessions (
    sess_id VARCHAR(128) PRIMARY KEY,
    sess_data TEXT,
    sess_time INTEGER NOT NULL
);

-- Criar tabela de sessões se não existir (para sessões PHP)
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    data TEXT,
    last_access TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criar tabela de uploads se não existir (para imagens)
CREATE TABLE IF NOT EXISTS uploads (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados de exemplo se a tabela estiver vazia
INSERT INTO messages (message) 
SELECT 'FAILOVER: Sistema rodando no Secondary PostgreSQL!'
WHERE NOT EXISTS (SELECT 1 FROM messages);

INSERT INTO messages (message) 
SELECT 'Secondary assumiu após falha do Primary - ' || current_timestamp
WHERE (SELECT COUNT(*) FROM messages) = 1;
