<?php
echo "<h2>Network Connectivity Test</h2>";

// Test DNS resolution
echo "<h3>DNS Resolution Test</h3>";
$hosts = ['api.cloudinary.com', 'google.com', 'github.com'];

foreach ($hosts as $host) {
    $ip = gethostbyname($host);
    if ($ip !== $host) {
        echo "<p style='color: green;'>✓ $host resolves to: $ip</p>";
    } else {
        echo "<p style='color: red;'>✗ Failed to resolve: $host</p>";
    }
}

// Test HTTP connectivity
echo "<h3>HTTP Connectivity Test</h3>";

function testHttpConnection($url) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (compatible; PHP Test)');
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($result === false) {
        return ['success' => false, 'error' => $error, 'http_code' => $httpCode];
    } else {
        return ['success' => true, 'http_code' => $httpCode, 'response_length' => strlen($result)];
    }
}

$testUrls = [
    'https://api.cloudinary.com/v1_1/demo/image/list',
    'https://google.com',
    'https://httpbin.org/get'
];

foreach ($testUrls as $url) {
    $result = testHttpConnection($url);
    if ($result['success']) {
        echo "<p style='color: green;'>✓ $url - HTTP {$result['http_code']} - Response: {$result['response_length']} bytes</p>";
    } else {
        echo "<p style='color: red;'>✗ $url - Error: {$result['error']}</p>";
    }
}

// Test Cloudinary configuration
echo "<h3>Cloudinary Configuration Test</h3>";
require '../config/cloudinary.php';

echo "<p><strong>Cloud Name:</strong> " . htmlspecialchars($cloudinary_config['cloud_name']) . "</p>";
echo "<p><strong>API Key:</strong> " . htmlspecialchars($cloudinary_config['api_key']) . "</p>";
echo "<p><strong>API Secret:</strong> " . (strlen($cloudinary_config['api_secret']) > 0 ? str_repeat('*', strlen($cloudinary_config['api_secret'])) : 'NOT SET') . "</p>";

// Test Cloudinary SDK
echo "<h3>Cloudinary SDK Test</h3>";
try {
    require '../vendor/autoload.php';
    use Cloudinary\Configuration\Configuration;
    use Cloudinary\Api\Admin\AdminApi;
    
    Configuration::instance([
        'cloud' => [
            'cloud_name' => $cloudinary_config['cloud_name'],
            'api_key' => $cloudinary_config['api_key'],
            'api_secret' => $cloudinary_config['api_secret']
        ]
    ]);
    
    $admin = new AdminApi();
    $result = $admin->ping();
    
    if ($result && isset($result['status']) && $result['status'] === 'ok') {
        echo "<p style='color: green;'>✓ Cloudinary API connection successful!</p>";
        echo "<pre>" . json_encode($result, JSON_PRETTY_PRINT) . "</pre>";
    } else {
        echo "<p style='color: orange;'>⚠ Cloudinary API responded but status unclear</p>";
        echo "<pre>" . json_encode($result, JSON_PRETTY_PRINT) . "</pre>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Cloudinary API test failed: " . htmlspecialchars($e->getMessage()) . "</p>";
}

// Environment info
echo "<h3>Environment Information</h3>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>cURL Version:</strong> " . curl_version()['version'] . "</p>";
echo "<p><strong>OpenSSL Version:</strong> " . curl_version()['ssl_version'] . "</p>";

// Network interfaces (if available)
if (function_exists('shell_exec')) {
    echo "<h3>Network Configuration</h3>";
    $ifconfig = shell_exec('ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Network info not available"');
    echo "<pre>" . htmlspecialchars($ifconfig) . "</pre>";
    
    $dns = shell_exec('cat /etc/resolv.conf 2>/dev/null || echo "DNS info not available"');
    echo "<h4>DNS Configuration</h4>";
    echo "<pre>" . htmlspecialchars($dns) . "</pre>";
}
?>
