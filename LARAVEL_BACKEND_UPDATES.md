# Laravel Backend Updates Required

Based on your Flutter app's friend management system, you need to add these endpoints to your Laravel backend:

## 1. Add User Search Endpoint

Add this route to your `routes/api.php` inside the `auth` middleware group:

```php
Route::middleware('auth:sanctum')->group(function () {
    // ... existing routes ...
    Route::get('/users/search', [CustomerAuthController::class, 'searchUsers']);
});
```

## 2. Add searchUsers Method to CustomerAuthController

Add this method to your `CustomerAuthController`:

```php
public function searchUsers(Request $request)
{
    $query = $request->get('q');
    
    if (empty($query)) {
        return response()->json(['users' => []]);
    }
    
    $currentUser = Auth::user();
    
    $users = Customer::where('id', '!=', $currentUser->id)
        ->where(function ($q) use ($query) {
            $q->where('name', 'LIKE', "%{$query}%")
              ->orWhere('email', 'LIKE', "%{$query}%")
              ->orWhere('customer_id', 'LIKE', "%{$query}%");
        })
        ->select(['id', 'customer_id', 'name', 'email', 'level', 'location', 'avatar_url'])
        ->limit(20)
        ->get()
        ->map(function ($user) use ($currentUser) {
            // Check friendship status
            $user->is_friend = $currentUser->isFriendWith($user);
            $user->friend_request_sent = $currentUser->hasPendingRequestTo($user);
            $user->has_pending_request = $currentUser->hasPendingRequestFrom($user);
            
            return $user;
        });
    
    return response()->json(['users' => $users]);
}
```

## 3. Update Existing Friend Management Methods

Make sure your existing `FriendshipController` methods return the correct JSON format:

### listFriends method should return:
```php
public function listFriends()
{
    $customer = Auth::user();
    $friends = $customer->friends()->get(['id', 'name', 'email', 'avatar_url']);
    $totalFriends = $customer->total_friends;

    return response()->json([
        'friends' => $friends,
        'total_friends' => $totalFriends,
    ]);
}
```

### pendingRequests method should return:
```php
public function pendingRequests()
{
    $customer = Auth::user();
    $pending = $customer->receivedFriendRequests()
        ->where('status', 'pending')
        ->with('sender:id,name,email,avatar_url,level,location')
        ->get()
        ->map(function ($request) {
            return [
                'id' => $request->id,
                'sender' => $request->sender,
                'status' => $request->status,
                'created_at' => $request->created_at,
            ];
        });

    return response()->json(['pending_requests' => $pending]);
}
```

## 4. Update Authentication Response Format

Make sure your `login_mobile` method in `CustomerAuthController` returns this format:

```php
public function login_mobile(Request $request)
{
    // ... validation and authentication logic ...
    
    if (Auth::attempt($credentials)) {
        $user = Auth::user();
        $token = $user->createToken('mobile-app')->plainTextToken;
        
        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'customer_id' => $user->customer_id,
                'name' => $user->name,
                'email' => $user->email,
                'mobile_no' => $user->mobile_no,
                'level' => $user->level,
                'location' => $user->location,
                'dupr_id' => $user->dupr_id,
                'avatar_url' => $user->avatar_url,
                'about' => $user->about,
                'credit_balance' => $user->credit_balance,
                'suspend' => $user->suspend,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }
    
    return response()->json(['message' => 'Invalid credentials'], 401);
}
```

## 5. Test Your Endpoints

After making these changes, test your endpoints:

```bash
# Test login
curl -X POST https://firstshot.my/api/auth/login/mobile \
  -H "Content-Type: application/json" \
  -d '{"mobile_no":"60123456789","password":"yourpassword"}'

# Test friends list (with token)
curl -X GET https://firstshot.my/api/auth/friends \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test user search (with token)
curl -X GET "https://firstshot.my/api/auth/users/search?q=john" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test send friend request (with token)
curl -X POST https://firstshot.my/api/auth/friends/send/2 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 6. CORS Configuration

Make sure your `config/cors.php` allows your Flutter app:

```php
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'], // Or specify your app's domain
'allowed_headers' => ['*'],
```

## Summary

Once you add these changes to your Laravel backend:
1. ✅ Login will work with the correct endpoint
2. ✅ Friend management will be fully functional
3. ✅ User search will work in the add friends page
4. ✅ All API responses will have the correct format

Your Flutter app is now configured to use these endpoints correctly!