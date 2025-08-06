# Friend Management System - Laravel Backend Integration

This guide explains the new friend management system that integrates with your Laravel backend using Sanctum authentication.

## 🔧 Backend Requirements

Your Laravel backend should have the following endpoints configured:

### Authentication Base URL
```
https://firstshot.my/api/auth
```

### Required API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile` | Get current user profile |
| PUT | `/profile/update` | Update user profile |
| GET | `/friends` | Get user's friends list |
| GET | `/friends/pending` | Get pending friend requests |
| POST | `/friends/send` | Send friend request |
| POST | `/friends/accept/{senderId}` | Accept friend request |
| POST | `/friends/reject/{senderId}` | Reject friend request |
| GET | `/users/search?q={query}` | Search users |
| POST | `/logout` | Logout user |

## 📱 Flutter App Features

### 1. Profile Page (`lib/profile_page.dart`)
- **Dynamic Profile Loading**: Loads user data from Laravel API
- **Friend Count Display**: Shows total number of friends
- **Friend Requests Badge**: Shows pending friend requests count
- **Friends Grid**: Displays up to 6 friends with avatars and names
- **Pull to Refresh**: Swipe down to refresh profile data
- **Navigation**: Easy access to Add Friends and Friend Requests pages

#### Key Features:
- Real-time friend request notifications
- Automatic data refresh when returning from other pages
- Error handling with user-friendly messages
- Fallback to cached data when API is unavailable

### 2. Friend Requests Page (`lib/friend_requests_page.dart`)
- **Pending Requests**: Lists all incoming friend requests
- **Accept/Reject Actions**: Quick action buttons for each request
- **Loading States**: Shows loading indicators during API calls
- **Pull to Refresh**: Swipe down to refresh requests
- **Empty State**: Helpful message when no requests are available

#### Key Features:
- Individual loading states for each request
- Automatic list updates after actions
- Detailed sender information (name, email, level, location)
- Error handling with retry options

### 3. Add Friends Page (`lib/add_friends_page.dart`)
- **Search Functionality**: Search users by name, email, or customer ID
- **Smart Search**: Debounced search with 500ms delay
- **Status Indicators**: Shows relationship status with each user
- **Action Buttons**: Context-aware buttons based on friendship status

#### Friendship Status Indicators:
- **Friends**: Green badge indicating existing friendship
- **Request Sent**: Orange badge showing pending outgoing request
- **Respond**: Blue badge for incoming friend requests
- **Add Friend**: Blue button to send new friend request

#### Key Features:
- Real-time search with debouncing
- Comprehensive user information display
- Status-aware action buttons
- Loading states during requests
- Clear search functionality

## 🔐 Authentication Integration

### Token Management
The app uses Laravel Sanctum tokens for authentication:

```dart
// Save token after login
await ApiService.saveAuthToken(token);

// Automatic token inclusion in headers
static Future<Map<String, String>> _getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

### User Profile Synchronization
The `UserProfile` model now syncs with your Laravel backend:

```dart
// Sync from API
await userProfile.syncFromAPI();

// Update profile
await userProfile.updateProfile({
  'name': 'New Name',
  'level': 'Advanced',
  'location': 'New York'
});
```

## 📊 Data Structure

### User Profile Data
```json
{
  "id": 1,
  "customer_id": "#FS00001",
  "name": "John Doe",
  "email": "john@example.com",
  "mobile_no": "+1234567890",
  "level": "Intermediate",
  "location": "New York",
  "dupr_id": "12345",
  "avatar_url": "https://example.com/avatar.jpg",
  "about": "Love playing pickleball!",
  "credit_balance": 25.50,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T12:30:00Z"
}
```

### Friends List Response
```json
{
  "friends": [
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "avatar_url": "https://example.com/jane-avatar.jpg"
    }
  ],
  "total_friends": 1
}
```

### Friend Requests Response
```json
{
  "pending_requests": [
    {
      "id": 1,
      "sender": {
        "id": 3,
        "name": "Bob Wilson",
        "email": "bob@example.com",
        "avatar_url": "https://example.com/bob-avatar.jpg",
        "level": "Beginner",
        "location": "California"
      },
      "status": "pending",
      "created_at": "2024-01-10T10:00:00Z"
    }
  ]
}
```

## 🚀 Setup Instructions

### 1. Update Dependencies
Run the following command to update dependencies:
```bash
flutter pub get
```

### 2. Configure API Base URL
Update the base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = "https://your-domain.com/api/auth";
```

### 3. Remove Firebase (if previously used)
The app has been updated to remove Firebase dependencies. If you had Firebase configured:
- Remove `google-services.json` (Android)
- Remove `GoogleService-Info.plist` (iOS)
- Update initialization code to remove Firebase

### 4. Test API Integration
Ensure your Laravel backend endpoints are working:
```bash
# Test authentication
curl -H "Authorization: Bearer YOUR_TOKEN" https://your-domain.com/api/auth/profile

# Test friends list
curl -H "Authorization: Bearer YOUR_TOKEN" https://your-domain.com/api/auth/friends
```

## 🔄 Migration from Firebase

If you're migrating from Firebase:

1. **Data Export**: Export user data from Firebase
2. **Data Import**: Import into your Laravel database
3. **Update Routes**: Ensure all Laravel routes are configured
4. **Test Authentication**: Verify Sanctum token authentication
5. **Update App**: Deploy the updated Flutter app

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Sanctum is properly configured
   - Check token expiration settings
   - Ensure CORS is configured for your domain

2. **API Connection Issues**
   - Verify base URL is correct
   - Check network connectivity
   - Ensure SSL certificates are valid

3. **Friend Request Issues**
   - Verify friendship model relationships
   - Check database constraints
   - Ensure proper error handling in controllers

### Debug Mode
Enable debug logging in `api_service.dart`:
```dart
print('API Request: $url');
print('Response: ${response.body}');
```

## 📝 Additional Notes

- The app gracefully handles offline scenarios with cached data
- All API calls include proper error handling
- User interface provides clear feedback for all actions
- The system supports real-time updates through API polling

For more detailed backend implementation, refer to your Laravel controller and model files provided in the initial request. 