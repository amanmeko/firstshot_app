<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PaymentController;

// Payment routes (exclude CSRF for external payment gateway)
Route::get('/payment/initiate/{sale}', [PaymentController::class, 'initiate'])->name('payment.initiate');
Route::match(['GET','POST'], '/payment/return', [PaymentController::class, 'handleReturn'])->name('payment.return');
Route::post('/payment/callback', [PaymentController::class, 'handleCallback'])->name('payment.callback');
Route::post('/payment/check-status', [PaymentController::class, 'checkStatus'])->name('payment.check-status');

// API routes for mobile app
Route::prefix('api')->group(function () {
    Route::get('/payment/initiate/{sale}', [PaymentController::class, 'initiate']);
    Route::post('/payment/check-status', [PaymentController::class, 'checkStatus']);
});
