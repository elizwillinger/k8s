<?php
// Readiness: can this pod serve real traffic? Requires a working DB connection.
mysqli_report(MYSQLI_REPORT_OFF);
$link = mysqli_init();
mysqli_options($link, MYSQLI_OPT_CONNECT_TIMEOUT, 2);
$ok = @mysqli_real_connect($link, getenv('DB_HOST'), getenv('DB_USER'), getenv('DB_PASSWORD'), getenv('DB_NAME'));
if (!$ok) {
    http_response_code(503);
    echo "db unavailable";
    exit;
}
mysqli_close($link);
echo "ok";
