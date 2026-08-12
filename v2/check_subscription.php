<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ---------------------------------------------------------------------
// FIX: the Flutter app sends a raw JSON body (Dio with
// contentType: 'application/json'), so $_POST is ALWAYS empty here —
// PHP only populates $_POST for form-urlencoded/multipart bodies.
// The app also sends the key 'subscriberId' (already formatted as
// tel:88...), not 'user_mobile' as a bare number. Both of those meant
// this endpoint could never actually receive the phone number from
// the app and always failed with "Invalid mobile number format".
//
// This now reads php://input as JSON first, and accepts either an
// already-formatted subscriberId OR a raw mobile number under a few
// common key names, falling back to $_POST for any legacy/form-based
// callers.
// ---------------------------------------------------------------------
$inputData = json_decode(file_get_contents('php://input'), true);
if (!is_array($inputData)) {
    $inputData = [];
}

$rawSubscriberId = trim($inputData['subscriberId'] ?? $_POST['subscriberId'] ?? '');
$rawMobile = trim($inputData['user_mobile'] ?? $inputData['userMobile'] ?? $_POST['user_mobile'] ?? '');

if ($rawSubscriberId !== '') {
    // Already formatted as tel:88XXXXXXXXXXX — just extract the digits.
    $digits = preg_replace('/\D+/', '', $rawSubscriberId);
} else {
    $digits = preg_replace('/\D+/', '', $rawMobile);
}

// Accept 018xxxxxxxx, 88018xxxxxxxx, or 8818xxxxxxxx and normalize to 018xxxxxxxx
if (strpos($digits, '880') === 0 && strlen($digits) === 13) {
    $digits = '0' . substr($digits, 3);
} elseif (strpos($digits, '88') === 0 && strlen($digits) === 12) {
    $digits = '0' . substr($digits, 2);
}

// Validate Bangladesh mobile number
if (!preg_match('/^01[3-9][0-9]{8}$/', $digits)) {
    echo json_encode([
        'error' => 'Invalid mobile number format',
        'providedSubscriberId' => $rawSubscriberId,
        'providedNumber' => $rawMobile,
    ]);
    exit;
}

// bdapps subscriberId format
$subscriberId = 'tel:88' . $digits;

$requestData = [
    'version' => '1.0',
    'applicationId' => 'APP_139349',
    'password' => 'e566a55b54ba8447da0d36b2f0913489',
    'subscriberId' => $subscriberId,
];

$requestJson = json_encode($requestData);

// BDApps subscription status API (casing confirmed against official SDK's sdk_file.php)
$url = 'https://developer.bdapps.com/subscription/getstatus';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen($requestJson),
]);

$responseJson = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($responseJson === false) {
    echo json_encode([
        'error' => 'cURL failed',
        'details' => $curlError,
    ]);
    exit;
}

$response = json_decode($responseJson, true);
if (!is_array($response)) {
    echo json_encode(['error' => 'Invalid response']);
    exit;
}

$status = strtoupper(trim($response['subscriptionStatus'] ?? ''));

// Per getStatus contract, subscription status is REGISTERED or UNREGISTERED.
$isSubscribed = ($status === 'REGISTERED');

echo json_encode([
    'subscriptionStatus' => $status,
    'isSubscribed' => $isSubscribed,
    'statusCode' => $response['statusCode'] ?? null,
    'statusDetail' => $response['statusDetail'] ?? null,
    'version' => $response['version'] ?? null,
    'subscriberId' => $subscriberId
]);
?>