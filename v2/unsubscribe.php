<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED);

function callBdapps(string $url, array $requestData): array {
    $requestJson = json_encode($requestData);
    if ($requestJson === false) {
        return ['ok' => false, 'error' => 'Failed to encode request'];
    }

    $ch = curl_init();
    if ($ch === false) {
        return ['ok' => false, 'error' => 'Unable to initialize cURL'];
    }

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        "Content-Type: application/json",
        "Content-Length: " . strlen($requestJson)
    ));
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);

    $responseJson = curl_exec($ch);
    $curlError = curl_error($ch);

    if ($responseJson === false) {
        return ['ok' => false, 'error' => "cURL failed: $curlError"];
    }

    $response = json_decode($responseJson, true);
    if (!is_array($response)) {
        return ['ok' => false, 'error' => 'Invalid response', 'raw' => $responseJson];
    }

    return ['ok' => true, 'data' => $response, 'raw' => $responseJson];
}

$inputData = json_decode(file_get_contents('php://input'), true);
$rawMobile = trim($_POST['user_mobile'] ?? $_POST['subscriberId'] ?? $inputData['subscriberId'] ?? $inputData['user_mobile'] ?? '');

if ($rawMobile === '') {
    echo json_encode(['success' => false, 'error' => 'Mobile number required']);
    exit;
}

$digits = preg_replace('/\D+/', '', $rawMobile);
if (strlen($digits) === 13 && substr($digits, 0, 2) === '88') {
    $digits = substr($digits, 2);
}

if (strlen($digits) !== 11 || $digits[0] !== '0') {
    echo json_encode(['success' => false, 'error' => 'Invalid mobile format']);
    exit;
}

$subscriberId = 'tel:88' . $digits;
$appId = 'APP_139349';
$password = 'e566a55b54ba8447da0d36b2f0913489';

$requestData = array(
    'applicationId' => $appId,
    'password' => $password,
    'subscriberId' => $subscriberId,
    'version' => '1.0',
    'action' => '0', // 0 = Unsubscribe
);

$result = callBdapps('https://developer.bdapps.com/subscription/send', $requestData);

if (!$result['ok']) {
    echo json_encode([
        'success' => false,
        'error' => $result['error'],
        'subscriberId' => $subscriberId,
        'action' => '0',
    ]);
    exit;
}

$response = $result['data'];
$statusCode = strtoupper((string)($response['statusCode'] ?? ''));

// ---------------------------------------------------------------------
// DO NOT TRUST $statusCode ALONE. E1951 is ambiguous on BDApps's side —
// it can mean "already unregistered" (fine) OR "invalid address format"
// (the unsubscribe never actually happened). Previously this endpoint
// treated E1951 as automatic success, which is why the website could
// report "unsubscribed!" while BDApps still considered the number
// registered — the very next OTP request would come back E1351
// ("already registered") because nothing had actually changed.
//
// Fix: only trust an explicit, unambiguous success code from the
// unsubscribe call itself (S1000 / E1352). For every other code —
// including E1951 — go verify the REAL current status with a separate
// subscription-status check before telling the caller anything
// succeeded.
// ---------------------------------------------------------------------

$unambiguousSuccess = ($statusCode === 'S1000' || $statusCode === 'E1352');

$verifiedUnregistered = false;
$verifyStatusCode = null;

if (!$unambiguousSuccess) {
    // Ask BDApps directly: is this subscriberId actually registered
    // right now? Endpoint casing confirmed against the official SDK
    // (sdk_file.php uses lowercase 'getstatus' — this previously used
    // 'getStatus', which may have been hitting a different/incorrect
    // route depending on how strictly BDApps matches paths).
    $checkRequestData = array(
        'version' => '1.0',
        'applicationId' => $appId,
        'password' => $password,
        'subscriberId' => $subscriberId,
    );

    // BDApps processes subscription changes asynchronously — confirmed
    // by the existence of subscription_listener.php, a webhook BDApps
    // calls AFTER it finishes processing. Checking status immediately
    // can race against that and still see the old status. Retry a
    // couple of times with a short delay before giving up.
    for ($attempt = 0; $attempt < 3 && !$verifiedUnregistered; $attempt++) {
        if ($attempt > 0) {
            usleep(800000); // 0.8s between retries
        }

        $checkResult = callBdapps('https://developer.bdapps.com/subscription/getstatus', $checkRequestData);

        if ($checkResult['ok']) {
            $checkResponse = $checkResult['data'];
            $verifyStatusCode = strtoupper((string)($checkResponse['statusCode'] ?? ''));
            $checkSubStatus = strtoupper(trim((string)($checkResponse['subscriptionStatus'] ?? '')));

            // Per the getStatus contract, subscriptionStatus is reliably
            // REGISTERED or UNREGISTERED — trust this field directly
            // rather than inferring from a statusCode.
            $verifiedUnregistered = ($checkSubStatus === 'UNREGISTERED');
        }
    }
}

$success = $unambiguousSuccess || $verifiedUnregistered;

echo json_encode([
    'success' => $success,
    'subscriberId' => $subscriberId,
    'action' => '0',
    'version' => '1.0',
    'statusCode' => $response['statusCode'] ?? null,
    'statusDetail' => $response['statusDetail'] ?? null,
    'subscriptionStatus' => $success ? 'UNREGISTERED' : 'UNKNOWN',
    'verification' => array(
        'ranVerificationCheck' => !$unambiguousSuccess,
        'verifyStatusCode' => $verifyStatusCode,
    ),
    'rawResponse' => $result['raw'] ?? null,
]);

?>