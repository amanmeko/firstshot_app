# API Debug Guide - FirstShot Login Issue

## Problem
Getting HTML response instead of JSON when trying to login, indicating the API endpoint might not be properly configured.

## Current Error
```
FormatException: SyntaxError: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

## Debug Steps

### 1. Check Laravel Routes
Verify that your Laravel routes are properly configured. Run this command in your Laravel project:

```bash
php artisan route:list | grep login
```

Expected output should include something like:
```
POST  | api/customer/login | customer.login
```

### 2. Test API Endpoints Manually

Test these endpoints with curl or Postman:

```bash
# Test 1: Basic endpoint check
curl -X GET https://firstshot.my/api/customer/login

# Test 2: POST with form data
curl -X POST https://firstshot.my/api/customer/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"mobile_no":"60123456789","password":"testpassword"}'

# Test 3: Check if API is accessible
curl -X GET https://firstshot.my/api/

# Test 4: Test with form-encoded data
curl -X POST https://firstshot.my/api/customer/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/json" \
  -d "mobile_no=60123456789&password=testpassword"
```

### 3. Laravel Backend Checklist

Ensure your Laravel backend has:

1. **Routes defined** in `routes/api.php`:
```php
Route::post('/customer/login', [AuthController::class, 'login']);
```

2. **CORS configured** in `config/cors.php`:
```php
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'], // Or your specific domain
'allowed_headers' => ['*'],
```

3. **Controller exists** and returns JSON:
```php
public function login(Request $request)
{
    // Your login logic
    return response()->json([
        'token' => $token,
        'user' => $user
    ]);
}
```

### 4. Common Issues and Solutions

#### Issue 1: 404 Not Found (HTML Error Page)
- **Cause**: Route doesn't exist
- **Solution**: Check `routes/api.php` and ensure route is defined

#### Issue 2: 500 Internal Server Error (HTML Error Page)  
- **Cause**: Server error, likely in controller
- **Solution**: Check Laravel logs at `storage/logs/laravel.log`

#### Issue 3: CORS Error
- **Cause**: Cross-origin request blocked
- **Solution**: Configure CORS properly or use Laravel Sanctum

#### Issue 4: Wrong Content-Type
- **Cause**: Server expects different content type
- **Solution**: Try both `application/json` and `application/x-www-form-urlencoded`

### 5. Flutter Debug Steps

Add this debug function to your Flutter app:

```dart
Future<void> debugApiCall() async {
  final endpoints = [
    'https://firstshot.my/api/customer/login',
    'https://firstshot.my/api/auth/login', 
    'https://firstshot.my/api/login',
  ];
  
  for (String endpoint in endpoints) {
    print('Testing: $endpoint');
    try {
      // Test GET first
      var response = await http.get(Uri.parse(endpoint));
      print('GET $endpoint: ${response.statusCode} - ${response.body.substring(0, 100)}');
      
      // Test POST
      response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'mobile_no': '60123456789', 'password': 'test'}),
      );
      print('POST $endpoint: ${response.statusCode} - ${response.body.substring(0, 100)}');
    } catch (e) {
      print('Error testing $endpoint: $e');
    }
  }
}
```

### 6. Quick Fix Options

If the issue persists, try these alternative endpoints:

1. **Option 1**: Use the original working endpoint from your existing code
2. **Option 2**: Create a new route specifically for mobile login
3. **Option 3**: Use Laravel Sanctum's built-in authentication endpoints

### 7. Expected Response Format

Your Laravel login should return:
```json
{
  "token": "your-sanctum-token-here",
  "user": {
    "id": 1,
    "customer_id": "#FS00001",
    "name": "John Doe",
    "email": "john@example.com",
    "mobile_no": "60123456789",
    // ... other user fields
  }
}
```

## Next Steps

1. Run the curl commands above to test your API
2. Check your Laravel logs for any errors
3. Verify your routes are properly configured
4. Test with the debug function in Flutter
5. Update the endpoint in the Flutter app based on what works