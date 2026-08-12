<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json; charset=utf-8'); 

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}
header('Content-Type: application/json; charset=utf-8');

// ---------------------------------------------------------------------
// FIX: the Flutter app sends a raw JSON body (Dio with
// contentType: 'application/json'), so $_POST is ALWAYS empty here —
// PHP only populates $_POST for form-urlencoded/multipart bodies. The
// app also sends the key 'userMobile' (camelCase), not 'user_mobile'.
// Both meant this endpoint could never actually receive the phone
// number from the app.
//
// This now reads php://input as JSON first, accepting a few common
// key spellings, and falls back to $_POST for any legacy/form-based
// callers (e.g. the website, if it posts as a normal form).
// ---------------------------------------------------------------------
$inputData = json_decode(file_get_contents('php://input'), true);
if (!is_array($inputData)) {
    $inputData = [];
}

$rawMobile = trim(
    $inputData['userMobile']
    ?? $inputData['user_mobile']
    ?? $inputData['subscriberId']
    ?? $_POST['user_mobile']
    ?? $_POST['userMobile']
    ?? ''
);

$digits = preg_replace('/\D+/', '', $rawMobile);

// Accept 018xxxxxxxx, 88018xxxxxxxx, or 8818xxxxxxxx and normalize to 018xxxxxxxx
if (strpos($digits, '880') === 0 && strlen($digits) === 13) {
    $digits = '0' . substr($digits, 3);
} elseif (strpos($digits, '88') === 0 && strlen($digits) === 12) {
    $digits = '0' . substr($digits, 2);
}

// Validate Bangladesh mobile number
if (!preg_match('/^01[3-9][0-9]{8}$/', $digits)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid mobile number format',
        'referenceNo' => null,
        'providedNumber' => $rawMobile,
    ]);
    exit;
}

// bdapps subscriberId format
$user_mobile = 'tel:88' . $digits;

// Debug log
file_put_contents('user_number.txt', $user_mobile . PHP_EOL, FILE_APPEND);

// Request data
$requestData = [
    'applicationId' => 'APP_139349',
    'password' => 'e566a55b54ba8447da0d36b2f0913489',
    'subscriberId' => $user_mobile,
    'applicationHash' => 'MindQuiz', // was leftover placeholder "Quiz Shell"
    'applicationMetaData' => [
        'client' => 'MOBILEAPP',
        'device' => 'Generic Android Device', // was leftover "Samsung S10"
        'os' => 'android', // was leftover "android 8" (hardcoded OS version)
        'appCode' => 'com.mindquest.quiz_application_app' // TODO: confirm real package name
    ]
];

$requestJson = json_encode($requestData);

// Log the request for debugging
file_put_contents('otp_request.txt', date('Y-m-d H:i:s') . " | Request: " . $requestJson . "\n", FILE_APPEND);

$url = 'https://developer.bdapps.com/subscription/otp/request';
$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen($requestJson)
]);

$responseJson = curl_exec($ch);

if ($responseJson === false) {
    echo json_encode([
        'success' => false,
        'message' => 'cURL error: ' . curl_error($ch),
        'referenceNo' => null
    ]);
    curl_close($ch);
    exit;
}

$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// Log the raw response for debugging
file_put_contents('otp_response.txt', date('Y-m-d H:i:s') . " | HTTP $httpCode | " . $responseJson . "\n", FILE_APPEND);

// Check if response looks like HTML (error page)
if (stripos($responseJson, '<html') !== false || stripos($responseJson, '<!DOCTYPE') !== false) {
    echo json_encode([
        'success' => false,
        'message' => 'Server returned HTML instead of JSON. HTTP code: ' . $httpCode,
        'referenceNo' => null,
        'rawResponse' => substr($responseJson, 0, 500) // First 500 chars
    ]);
    exit;
}

$response = json_decode($responseJson, true);

if (!is_array($response)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid JSON in response',
        'raw' => substr($responseJson, 0, 500), // Show first 500 chars
        'referenceNo' => null,
        'httpCode' => $httpCode
    ]);
    exit;
}

$referenceNo = isset($response['referenceNo']) ? trim((string)$response['referenceNo']) : '';
$statusCode = isset($response['statusCode']) ? (string)$response['statusCode'] : '';
$statusDetail = isset($response['statusDetail']) ? (string)$response['statusDetail'] : '';
$version = isset($response['version']) ? (string)$response['version'] : '';

if ($referenceNo !== '') {
    echo json_encode([
        'success' => true,
        'referenceNo' => $referenceNo,
        'statusCode' => $statusCode,
        'statusDetail' => $statusDetail,
        'version' => $version
    ]);
    exit;
}

echo json_encode([
    'success' => false,
    'message' => $statusDetail !== '' ? $statusDetail : 'OTP reference not returned',
    'referenceNo' => null,
    'statusCode' => $statusCode,
    'statusDetail' => $statusDetail,
    'version' => $version,
    'subscriberId' => $user_mobile
]);