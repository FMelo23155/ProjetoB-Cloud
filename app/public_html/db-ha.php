<?php
// Configuração de conexão com alta disponibilidade

class DatabaseHA {
    private $config;
    private $pdo;
    private $maxRetries = 3;
    private $retryDelay = 1; // segundos
    
    public function __construct() {
        $this->config = [
            'host' => $_ENV['DB_HOST'] ?? 'postgres-ha',
            'port' => $_ENV['DB_PORT'] ?? '5432',
            'database' => $_ENV['DB_NAME'] ?? 'cnv_project',
            'username' => $_ENV['DB_USER'] ?? 'cnv_user',
            'password' => $_ENV['DB_PASS'] ?? 'cnv_password'
        ];
    }
    
    public function connect() {
        $attempts = 0;
        $lastException = null;
        
        while ($attempts < $this->maxRetries) {
            try {
                $dsn = sprintf(
                    "pgsql:host=%s;port=%s;dbname=%s",
                    $this->config['host'],
                    $this->config['port'],
                    $this->config['database']
                );
                
                $this->pdo = new PDO($dsn, $this->config['username'], $this->config['password'], [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_TIMEOUT => 5, // 5 segundos timeout
                    PDO::ATTR_PERSISTENT => false,
                    // Configurações para failover
                    PDO::ATTR_EMULATE_PREPARES => false
                ]);
                
                // Testar conexão
                $this->pdo->query('SELECT 1');
                
                // Log successful connection
                error_log(sprintf(
                    "[%s] Conexão PostgreSQL estabelecida com sucesso via %s (tentativa %d/%d)",
                    date('Y-m-d H:i:s'),
                    $this->config['host'],
                    $attempts + 1,
                    $this->maxRetries
                ));
                
                return $this->pdo;
                
            } catch (PDOException $e) {
                $lastException = $e;
                $attempts++;
                
                error_log(sprintf(
                    "[%s] Falha na conexão PostgreSQL (tentativa %d/%d): %s",
                    date('Y-m-d H:i:s'),
                    $attempts,
                    $this->maxRetries,
                    $e->getMessage()
                ));
                
                if ($attempts < $this->maxRetries) {
                    sleep($this->retryDelay);
                    $this->retryDelay *= 2; // Exponential backoff
                }
            }
        }
        
        // Se chegou até aqui, todas as tentativas falharam
        throw new Exception(sprintf(
            "Falha ao conectar com PostgreSQL após %d tentativas. Último erro: %s",
            $this->maxRetries,
            $lastException ? $lastException->getMessage() : 'Erro desconhecido'
        ));
    }
    
    public function getConnection() {
        if (!$this->pdo) {
            return $this->connect();
        }
        
        // Verificar se conexão ainda está ativa
        try {
            $this->pdo->query('SELECT 1');
            return $this->pdo;
        } catch (PDOException $e) {
            error_log(sprintf(
                "[%s] Conexão PostgreSQL perdida, reconectando: %s",
                date('Y-m-d H:i:s'),
                $e->getMessage()
            ));
            
            $this->pdo = null;
            return $this->connect();
        }
    }
    
    public function executeQuery($sql, $params = []) {
        $attempts = 0;
        $lastException = null;
        
        while ($attempts < $this->maxRetries) {
            try {
                $pdo = $this->getConnection();
                $stmt = $pdo->prepare($sql);
                $stmt->execute($params);
                return $stmt;
                
            } catch (PDOException $e) {
                $lastException = $e;
                $attempts++;
                
                error_log(sprintf(
                    "[%s] Falha na execução da query (tentativa %d/%d): %s",
                    date('Y-m-d H:i:s'),
                    $attempts,
                    $this->maxRetries,
                    $e->getMessage()
                ));
                
                // Forçar reconexão na próxima tentativa
                $this->pdo = null;
                
                if ($attempts < $this->maxRetries) {
                    sleep($this->retryDelay);
                }
            }
        }
        
        throw new Exception(sprintf(
            "Falha ao executar query após %d tentativas. Último erro: %s",
            $this->maxRetries,
            $lastException ? $lastException->getMessage() : 'Erro desconhecido'
        ));
    }
    
    public function beginTransaction() {
        return $this->getConnection()->beginTransaction();
    }
    
    public function commit() {
        return $this->getConnection()->commit();
    }
    
    public function rollback() {
        return $this->getConnection()->rollback();
    }
    
    public function lastInsertId() {
        return $this->getConnection()->lastInsertId();
    }
    
    public function getServerInfo() {
        try {
            $stmt = $this->executeQuery("SELECT version() as version, current_database() as database, current_user as user, inet_server_addr() as server_ip");
            return $stmt->fetch();
        } catch (Exception $e) {
            return ['error' => $e->getMessage()];
        }
    }
}

// Função de compatibilidade para código existente
function connectToDatabase($db_host = null, $db_port = null, $db_name = null, $db_user = null, $db_pass = null) {
    $dbHA = new DatabaseHA();
    return $dbHA->getConnection();
}

// Instância global para compatibilidade
$dbHA = new DatabaseHA();

// Função para obter conexão com retry automático
function getDbConnection() {
    global $dbHA;
    return $dbHA->getConnection();
}

// Função para executar queries com retry
function executeDbQuery($sql, $params = []) {
    global $dbHA;
    return $dbHA->executeQuery($sql, $params);
}

// Log de inicialização
error_log(sprintf(
    "[%s] Sistema de Alta Disponibilidade PostgreSQL inicializado - Target: %s:%s",
    date('Y-m-d H:i:s'),
    $_ENV['DB_HOST'] ?? 'postgres-ha',
    $_ENV['DB_PORT'] ?? '5432'
));
?>
