<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

require_once __DIR__ . '/../vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->safeLoad(); // Use safeLoad instead of load to avoid errors if .env doesn't exist

// Use environment variables with fallback to .env file
$badge = $_ENV['BADGE'] ?? getenv('BADGE') ?? 'primary';
$deploy_date = $_ENV['DEPLOY_DATE'] ?? getenv('DEPLOY_DATE') ?? date('c');
$db_host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?? 'localhost';
$db_port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?? '5432';
$db_user = $_ENV['DB_USER'] ?? getenv('DB_USER') ?? 'user';
$db_pass = $_ENV['DB_PASS'] ?? getenv('DB_PASS') ?? 'password';
$db_name = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?? 'database';
$ws_host = $_ENV['WS_HOST'] ?? getenv('WS_HOST') ?? 'localhost';
$ws_port = $_ENV['WS_PORT'] ?? getenv('WS_PORT') ?? '8888';
// Use the $badge variable in your page
?>