-- Script rápido para criar tabelas no Secondary
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

-- Inserir dados de exemplo
INSERT INTO messages (message) VALUES ('FAILOVER: Sistema funcionando no PostgreSQL Secondary!') ON CONFLICT DO NOTHING;
INSERT INTO messages (message) VALUES ('Teste de alta disponibilidade com HAProxy realizado com sucesso!') ON CONFLICT DO NOTHING;
