<?php

$envFile = dirname(__DIR__) . '/.env';

if (file_exists($envFile)) {
    $variables = parse_ini_file($envFile, false, INI_SCANNER_RAW);

    if ($variables !== false) {
        foreach ($variables as $key => $value) {
            if (getenv($key) === false) {
                putenv("$key=$value");
            }
        }
    }
}