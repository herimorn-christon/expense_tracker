<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'http://localhost:3000',
        'http://localhost:3001',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:3001',
    ],
    'allowed_origins_patterns' => [
        'http://localhost:*',
        'http://127.0.0.1:*',
    ],
    'allowed_headers' => [
        '*',
        'Authorization',
        'Content-Type',
        'X-Requested-With',
        'Accept',
        'Origin',
    ],
    'exposed_headers' => [
        'Authorization',
        'Content-Type',
    ],

    'max_age' => 86400, // 24 hours

    'supports_credentials' => true,

];
