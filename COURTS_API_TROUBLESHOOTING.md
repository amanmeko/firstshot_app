# Courts API Fetch Error - Troubleshooting Guide

## Problem Description
You're experiencing a "fetch courts client exception fail to fetch url" error when trying to load courts data in your FirstShot Flutter app.

## Root Causes & Solutions

### 1. Network Connectivity Issues

**Symptoms:**
- SocketException errors
- Connection timeout errors
- "Unable to connect to server" messages

**Solutions:**
- Check your internet connection
- Verify you're not behind a restrictive firewall
- Try switching between WiFi and mobile data
- Check if the server is accessible from your network

**Test Command:**
```bash
# Test basic connectivity
ping firstshot.my

# Test HTTP connectivity
curl -v https://firstshot.my/api/auth/courts
```

### 2. API Endpoint Configuration

**Current Configuration:**
```dart
static const String baseUrl = 'https://firstshot.my/api/auth';
// Endpoint: $baseUrl/courts
// Full URL: https://firstshot.my/api/auth/courts
```

**Potential Issues:**
- Wrong base URL
- Missing or incorrect API path
- Server not running on expected port

**Alternative URLs to Test:**
```
https://firstshot.my/api/courts
https://firstshot.my/courts
http://firstshot.my/api/auth/courts
http://localhost:8000/api/auth/courts (if testing locally)
```

### 3. Server Status & Configuration

**Check Server Status:**
```bash
# Test if server is responding
curl -I https://firstshot.my/api/auth/courts

# Check response headers
curl -v https://firstshot.my/api/auth/courts
```

**Common Server Issues:**
- Laravel backend not running
- Wrong route configuration in `routes/api.php`
- CORS configuration issues
- SSL certificate problems

### 4. Laravel Backend Verification

**Check Routes:**
```bash
# In your Laravel project directory
php artisan route:list | grep courts
```

**Expected Output:**
```
GET|HEAD | api/courts | courts.index | App\Http\Controllers\Api\BookingApiController@getCourts
```

**Check Controller:**
Verify `app/Http/Controllers/Api/BookingApiController.php` exists and has:
```php
public function getCourts()
{
    try {
        $courts = PickleballCourt::all()->map(function ($court) {
            // Court mapping logic
        });
        return response()->json($courts);
    } catch (\Exception $e) {
        \Log::error('Error retrieving courts: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'Failed to fetch courts: ' . $e->getMessage()
        ], 500);
    }
}
```

### 5. CORS Configuration

**Check `config/cors.php`:**
```php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'], // Or your specific domain
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

### 6. Flutter App Debugging

**Enhanced Error Logging Added:**
The `BookingService.getCourts()` method now includes:
- Detailed request logging
- Response status and headers logging
- Specific error categorization
- Timeout handling (30 seconds)

**Debug Page Added:**
Navigate to Settings → Network Debug to access comprehensive network diagnostics.

**Access Debug Page:**
```dart
Navigator.pushNamed(context, '/debug-network');
```

### 7. Step-by-Step Debugging Process

#### Step 1: Check Console Logs
Look for these debug messages in your Flutter console:
```
🔍 Fetching courts from: https://firstshot.my/api/auth/courts
🔑 Headers: [Content-Type, Accept, Authorization]
📡 Courts API Response Status: [status_code]
📄 Response Headers: [headers]
📄 Response Body Length: [length]
```

#### Step 2: Test API Manually
```bash
# Test the exact endpoint your app is calling
curl -X GET "https://firstshot.my/api/auth/courts" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

#### Step 3: Check Server Logs
```bash
# In your Laravel project
tail -f storage/logs/laravel.log
```

#### Step 4: Verify Database
```bash
# Check if courts table has data
php artisan tinker
>>> App\Models\PickleballCourt::count();
```

### 8. Common Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `SocketException` | Network connectivity | Check internet connection |
| `HandshakeException` | SSL/TLS issues | Verify SSL certificate |
| `TimeoutException` | Server slow response | Increase timeout or check server |
| `FormatException` | Invalid JSON response | Check server response format |
| `401 Unauthorized` | Authentication required | Check auth token |
| `404 Not Found` | Route doesn't exist | Verify Laravel routes |
| `500 Internal Server Error` | Server error | Check Laravel logs |

### 9. Testing Tools Provided

#### Flutter Debug Page
- Navigate to Settings → Network Debug
- Tests multiple URL variations
- Provides detailed error information
- Shows response headers and body

#### Shell Script
```bash
./test_api_connectivity.sh
```
Tests:
- Internet connectivity
- DNS resolution
- Multiple endpoint variations
- HTTP response codes

#### Network Utils Class
```dart
import 'utils/network_utils.dart';

// Test API connectivity
final diagnostics = await NetworkUtils.getNetworkDiagnostics();

// Test specific URL
final result = await NetworkUtils.testApiConnectivity();
```

### 10. Quick Fixes to Try

1. **Restart the app** - Clear any cached connections
2. **Check internet connection** - Switch networks if needed
3. **Verify server is running** - Check if Laravel backend is active
4. **Test with different URLs** - Try HTTP vs HTTPS, different paths
5. **Check authentication** - Ensure user is logged in with valid token
6. **Clear app cache** - Remove and reinstall app if needed

### 11. When to Contact Support

Contact your backend developer if:
- All network tests pass but API still fails
- Server logs show application errors
- Database queries are failing
- CORS configuration issues persist
- SSL certificate problems

### 12. Prevention Measures

- Implement retry logic with exponential backoff
- Add offline mode with cached data
- Use health check endpoints
- Monitor API response times
- Implement proper error boundaries in UI

## Next Steps

1. **Run the debug page** in your Flutter app
2. **Execute the shell script** when you have internet access
3. **Check Laravel backend** logs and configuration
4. **Verify network connectivity** from your device
5. **Test API endpoints** manually with curl/Postman

## Support

If you continue to experience issues after following this guide:
1. Collect debug information from the Flutter app
2. Run the connectivity tests
3. Check server logs
4. Contact your backend development team with the collected information