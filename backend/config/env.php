<?php

/**
 * Baca nilai dari backend/.env
 * Format baris: KEY=VALUE
 * Abaikan baris kosong dan baris yang diawali dengan #
 */
function env($key, $default = null) {
    $envFile = __DIR__ . '/../.env';

    if (!file_exists($envFile)) {
        return $default;
    }

    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || strpos($line, '#') === 0) {
            continue;
        }

        if (strpos($line, '=') !== false) {
            list($k, $v) = explode('=', $line, 2);
            $k = trim($k);
            $v = trim($v);
            if ($k === $key) {
                return $v;
            }
        }
    }

    return $default;
}
