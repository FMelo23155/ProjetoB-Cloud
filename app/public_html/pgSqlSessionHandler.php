<?php
class PgSqlSessionHandler implements SessionHandlerInterface {
    private $pdo;

    public function __construct($pdo) {
        $this->pdo = $pdo;
    }

    public function open($savePath, $sessionName) : bool{
        return true;
    }

    public function close() : bool{
        return true;
    }

    public function read($id) : string{
        $stmt = $this->pdo->prepare("SELECT sess_data FROM php_sessions WHERE sess_id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_STR);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ? $row['sess_data'] : '';
    }

    public function write($id, $data) : bool{
        $time = time();
        $stmt = $this->pdo->prepare("INSERT INTO php_sessions (sess_id, sess_data, sess_time) VALUES (:id, :data, :time) ON CONFLICT (sess_id) DO UPDATE SET sess_data = :data, sess_time = :time");
        $stmt->bindParam(':id', $id, PDO::PARAM_STR);
        $stmt->bindParam(':data', $data, PDO::PARAM_STR);
        $stmt->bindParam(':time', $time, PDO::PARAM_INT);
        return $stmt->execute();
    }

    public function destroy($id) : bool{
        $stmt = $this->pdo->prepare("DELETE FROM php_sessions WHERE sess_id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_STR);
        return $stmt->execute();
    }

    public function gc($maxlifetime) : int|false{
        $old = time() - $maxlifetime;
        $stmt = $this->pdo->prepare("DELETE FROM php_sessions WHERE sess_time < :old");
        $stmt->bindParam(':old', $old, PDO::PARAM_INT);
        if ($stmt->execute()) {
            return $stmt->rowCount();
        }
        return false;
    }
}