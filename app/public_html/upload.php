<?php
include '_dotenv.php';
require '../vendor/autoload.php';
require '../config/cloudinary.php';

use Cloudinary\Configuration\Configuration;
use Cloudinary\Api\Upload\UploadApi;
use Cloudinary\Api\Admin\AdminApi;

// Configurar Cloudinary
Configuration::instance([
    'cloud' => [
        'cloud_name' => $cloudinary_config['cloud_name'],
        'api_key' => $cloudinary_config['api_key'],
        'api_secret' => $cloudinary_config['api_secret']
    ]
]);

// Test connectivity before proceeding
function testCloudinaryConnectivity() {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://api.cloudinary.com/v1_1/demo/image/list');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return ['success' => $result !== false, 'error' => $error, 'http_code' => $httpCode];
}

$upload = new UploadApi();
$admin = new AdminApi();

// Function to handle file upload
function handleFileUpload($upload)
{
    if (isset($_POST['submit'])) {
        // First test connectivity
        $connectivityTest = testCloudinaryConnectivity();
        if (!$connectivityTest['success']) {
            return '<div class="alert alert-danger">
                <strong>Connection Error:</strong> Cannot connect to Cloudinary servers.<br>
                <small>Error: ' . htmlspecialchars($connectivityTest['error']) . '</small><br>
                <small>Please check your network connection and DNS settings.</small><br>
                <a href="test_connectivity.php" class="btn btn-sm btn-outline-info mt-2">Run Connectivity Test</a>
            </div>';
        }
        
        if ($_FILES['image']['error'] == UPLOAD_ERR_OK) {
            $file = $_FILES['image']['tmp_name'];
            $fileName = basename($_FILES['image']['name']);
            $fileType = pathinfo($fileName, PATHINFO_EXTENSION);

            if ($fileType === 'jpg' || $fileType === 'jpeg' || $fileType === 'png') {
                try {
                    $result = $upload->upload($file, [
                        'folder' => 'cnv-projeto',
                        'public_id' => uniqid('img_'),
                        'transformation' => [
                            'quality' => 'auto',
                            'fetch_format' => 'auto'
                        ]
                    ]);

                    if ($result) {
                        return '<div class="alert alert-success">Image uploaded successfully!</div>';
                    } else {
                        return '<div class="alert alert-danger">Sorry, there was an error uploading your file.</div>';
                    }
                } catch (Exception $e) {
                    $errorMsg = $e->getMessage();
                    $additionalInfo = '';
                    
                    // Provide specific help for common errors
                    if (strpos($errorMsg, 'Could not resolve host') !== false) {
                        $additionalInfo = '<br><small><strong>DNS Resolution Error:</strong> Your Docker container cannot resolve external hostnames. Please check your network configuration.</small>';
                    } elseif (strpos($errorMsg, 'Connection timed out') !== false) {
                        $additionalInfo = '<br><small><strong>Timeout Error:</strong> The connection to Cloudinary timed out. Please check your internet connection.</small>';
                    } elseif (strpos($errorMsg, 'SSL') !== false) {
                        $additionalInfo = '<br><small><strong>SSL Error:</strong> There was an SSL/TLS connection problem.</small>';
                    }
                    
                    return '<div class="alert alert-danger">
                        <strong>Error uploading file:</strong> ' . htmlspecialchars($errorMsg) . $additionalInfo . '<br>
                        <a href="test_connectivity.php" class="btn btn-sm btn-outline-info mt-2">Run Connectivity Test</a>
                    </div>';
                }
            } else {
                return '<div class="alert alert-danger">Please upload a JPG, JPEG, or PNG image.</div>';
            }
        } else {
            return '<div class="alert alert-danger">Error uploading file.</div>';
        }
    }
}

// Function to handle clear gallery button click
function handleClearGallery($admin)
{
    if (isset($_POST['clear'])) {
        try {
            $files_list = $admin->assets([
                'type' => 'upload',
                'prefix' => 'cnv-projeto/',
                'max_results' => 100
            ]);

            foreach ($files_list['resources'] as $resource) {
                $upload = new UploadApi();
                $upload->destroy($resource['public_id']);
            }

            return '<div class="alert alert-success">Gallery cleared successfully!</div>';
        } catch (Exception $e) {
            return '<div class="alert alert-danger">Error clearing gallery: ' . $e->getMessage() . '</div>';
        }
    }
}

// Function to delete an individual image
function deleteImage($imagePublicId)
{
    if (isset($_POST['delete'])) {
        try {
            $upload = new UploadApi();
            $result = $upload->destroy($imagePublicId);
            
            if ($result['result'] === 'ok') {
                return '<div class="alert alert-success">Image deleted successfully!</div>';
            } else {
                return '<div class="alert alert-danger">Error deleting image.</div>';
            }
        } catch (Exception $e) {
            return '<div class="alert alert-danger">Error deleting image: ' . $e->getMessage() . '</div>';
        }
    }
}

$uploadMessage = handleFileUpload($upload);
$clearMessage = handleClearGallery($admin);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CNV - Project B</title>
    <!-- Load Bootstrap 5.3 CSS from a local copy -->
    <link rel="stylesheet" href="css/bootstrap.min.css">
    <!-- Load custom CSS -->
    <link rel="stylesheet" href="css/site.css">
</head>
<body class="d-flex flex-column">
    <?php include 'partials/navbar.php'; ?>

    <!-- Begin page content -->
    <main class="flex-shrink-0">
        <div class="container mt-5">
            <h1 class="text-center">Image Upload - Cloudinary</h1>
            
            <!-- Connectivity test link -->
            <div class="text-center mb-3">
                <a href="test_connectivity.php" class="btn btn-outline-info btn-sm">
                    <i class="fas fa-network-wired"></i> Test Network Connectivity
                </a>
            </div>

            <!-- Display upload, clear gallery, and delete image messages -->
            <?php echo $uploadMessage; ?>
            <?php echo $clearMessage; ?>
            <?php echo isset($_POST['delete']) ? deleteImage($_POST['delete']) : ''; ?>

            <div class="row">
                <div class="col-md-6">
                    <!-- Display file upload form -->
                    <form method="POST" enctype="multipart/form-data">
                        <div class="input-group mb-3">
                            <input type="file" class="form-control" name="image" accept=".jpg, .jpeg, .png">
                            <button type="submit" class="btn btn-primary" name="submit">Upload</button>
                        </div>
                    </form>
                </div>
                <div class="col-md-6">
                    <!-- Display clear gallery button -->
                    <form method="POST">
                        <div class="form-group mt-md-4">
                            <button type="submit" class="btn btn-danger" name="clear">Clear Gallery</button>
                        </div>
                    </form>
                </div>
            </div>

            <hr>

            <!-- Display image gallery with delete buttons -->
            <div class="row">
                <?php
                function listImagesFromCloudinary($admin) {
                    try {
                        $files_list = $admin->assets([
                            'type' => 'upload',
                            'prefix' => 'cnv-projeto/',
                            'max_results' => 50
                        ]);
                        
                        $images = [];
                        foreach ($files_list['resources'] as $resource) {
                            $images[] = [
                                'public_id' => $resource['public_id'],
                                'url' => $resource['secure_url'],
                                'size' => $resource['bytes'],
                                'created' => $resource['created_at']
                            ];
                        }
                        return $images;
                    } catch (Exception $e) {
                        return [];
                    }
                }

                $images = listImagesFromCloudinary($admin);

                if (count($images) > 0) {
                    foreach ($images as $image) {
                        echo '<div class="col-md-4 mb-3">';
                        echo '<div class="card">';
                        echo '<img src="' . htmlspecialchars($image['url']) . '" class="card-img-top" style="height: 200px; object-fit: cover;">';
                        echo '<div class="card-body">';
                        echo '<h6 class="card-title">' . basename($image['public_id']) . '</h6>';
                        echo '<p class="card-text">';
                        echo '<small class="text-muted">';
                        echo 'Size: ' . number_format($image['size'] / 1024, 2) . ' KB<br>';
                        echo 'Date: ' . date('d/m/Y H:i', strtotime($image['created']));
                        echo '</small>';
                        echo '</p>';
                        echo '<div class="btn-group w-100">';
                        echo '<a href="' . htmlspecialchars($image['url']) . '" target="_blank" class="btn btn-sm btn-outline-primary">View</a>';
                        echo '<form method="POST" style="display: inline;">';
                        echo '<input type="hidden" name="delete" value="' . htmlspecialchars($image['public_id']) . '">';
                        echo '<button type="submit" class="btn btn-sm btn-outline-danger" onclick="return confirm(\'Delete this image?\')">Delete</button>';
                        echo '</form>';
                        echo '</div>';
                        echo '</div>';
                        echo '</div>';
                        echo '</div>';
                    }
                } else {
                    echo '<div class="col-12">';
                    echo '<p class="text-center text-muted">No images found. Upload your first image!</p>';
                    echo '</div>';
                }
                ?>
            </div>
        </div>
    </main>
    <?php include 'partials/footer.php'; ?>
    <!-- Load Bootstrap 5.3 JS from a local copy -->
    <script src="js/bootstrap.bundle.min.js"></script>
</body>
</html>
