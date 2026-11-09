<?php
// Liveness: is Apache/PHP alive? Deliberately does NOT touch the database.
http_response_code(200);
echo "ok";
