<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CustomerAuthController;
use App\Http\Controllers\Api\CoachController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\FriendshipController;
use App\Http\Controllers\Api\BookingApiController;

Route::prefix('auth')->group(function () {
    // Public routes
    Route::post('/otp-login', [CustomerAuthController::class, 'otpLogin']);
    Route::post('/register', [CustomerAuthController::class, 'register']);
    Route::post('/login', [CustomerAuthController::class, 'login']);
    Route::post('/login/mobile', [CustomerAuthController::class, 'login_mobile']);
    
    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/profile', [CustomerAuthController::class, 'profile']);
        Route::put('/profile', [CustomerAuthController::class, 'update']);
        Route::delete('/profile', [CustomerAuthController::class, 'destroy']);
        Route::post('/logout', [CustomerAuthController::class, 'logout']);
    });
});

// Public routes for coaches, products, events, and courses
Route::get('/coaches', [CoachController::class, 'index'])->name('api.coaches.index');
Route::get('/products', [ProductController::class, 'index'])->name('api.products.index');
Route::get('/events', [EventController::class, 'index'])->name('api.events.index');
Route::get('/courses', [CourseController::class, 'index'])->name('api.courses.index');

// Friendship routes (authenticated)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/friends/send/{receiverId}', [FriendshipController::class, 'sendRequest']);
    Route::post('/friends/accept/{senderId}', [FriendshipController::class, 'acceptRequest']);
    Route::post('/friends/reject/{senderId}', [FriendshipController::class, 'rejectRequest']);
    Route::get('/friends', [FriendshipController::class, 'listFriends']);
    Route::get('/friends/pending', [FriendshipController::class, 'pendingRequests']);
    Route::get('/users/search', [CustomerAuthController::class, 'searchUsers']);
});

// Booking routes (authenticated)
Route::middleware('auth:sanctum')->group(function () {
    // Promo code validation
    Route::post('/bookings/validate-promo', [BookingApiController::class, 'validatePromoCode']);
    
    // Get available time slots (BOTH versions must come BEFORE {booking} routes)
    Route::get('/bookings/available-times', [BookingApiController::class, 'getAvailableTimes']);
    Route::get('/bookings/available-times-v2', [BookingApiController::class, 'getAvailableTimesV2']);
    
    // Get customer bookings
    Route::get('/bookings/customer', [BookingApiController::class, 'getCustomerBookings']);
    
    // CRUD operations (these must come AFTER the specific routes)
    Route::post('/bookings', [BookingApiController::class, 'store']);
    Route::get('/bookings/{booking}', [BookingApiController::class, 'show']);
    Route::put('/bookings/{booking}', [BookingApiController::class, 'update']);
    Route::delete('/bookings/{booking}', [BookingApiController::class, 'destroy']);
    
    Route::get('/courts', [BookingApiController::class, 'getCourts']);
});