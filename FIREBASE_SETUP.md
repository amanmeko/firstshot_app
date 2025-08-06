# Firebase Integration for FirstShot App

## Overview
The FirstShot app now includes Firebase integration for user authentication and friends management functionality.

## Features Added

### 1. User Authentication
- Firebase Authentication for user login/registration
- Automatic sync of existing user data to Firebase Firestore
- Secure user profile management

### 2. Friends Management
- **Add Friends**: Browse and send friend requests to other users
- **Friend Requests**: View and manage incoming friend requests
- **Friends List**: Display current friends in the profile page
- **Real-time Updates**: Friends list updates automatically

## Firebase Services Used

### Firebase Authentication
- Email/password authentication
- Automatic user account creation during registration
- Secure login process

### Cloud Firestore
- User profiles storage
- Friends relationships management
- Friend requests tracking

## Database Structure

### Users Collection
```javascript
users/{userId} {
  name: string,
  email: string,
  mobileNo: string,
  duprId: string,
  level: string,
  location: string,
  avatarUrl: string,
  memberSince: string,
  createdAt: timestamp,
  friends: [userId1, userId2, ...],
  friendRequests: [userId1, userId2, ...],
  pendingRequests: [userId1, userId2, ...]
}
```

## New Screens

### 1. Add Friends Page (`/add_friends`)
- Lists all users who are not friends
- Shows user profile information (name, level, location)
- "Add Friend" button to send friend requests
- Real-time updates when requests are sent

### 2. Friend Requests Page (`/friend_requests`)
- Shows incoming friend requests
- Accept/Reject buttons for each request
- User profile information display
- Automatic removal after action

## Updated Screens

### Profile Page
- Dynamic user data from Firebase
- Real friends list display
- Friend requests badge with count
- "Add as friend" button navigates to add friends page

## Implementation Details

### Firebase Service (`lib/services/firebase_service.dart`)
- Centralized Firebase operations
- User management functions
- Friends management functions
- Error handling and data validation

### User Sync Service (`lib/services/user_sync_service.dart`)
- Syncs existing user data to Firebase
- Updates Firebase profiles when data changes
- Handles migration from secure storage

### Authentication Flow
1. User logs in/registers via existing API
2. Firebase user account is created automatically
3. User data is synced to Firestore
4. Friends functionality becomes available

## Setup Requirements

### Firebase Configuration
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- Firebase project with Authentication and Firestore enabled

### Dependencies Added
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.3
cloud_firestore: ^5.4.3
firebase_storage: ^12.3.3
```

## Usage

### For Users
1. **Login/Register**: Normal process, Firebase account created automatically
2. **Add Friends**: Click "Add as friend" button → Browse users → Send requests
3. **Manage Requests**: Click friend requests icon → Accept/Reject requests
4. **View Friends**: Friends appear in profile page automatically

### For Developers
1. **Firebase Service**: Use `FirebaseService` class for all Firebase operations
2. **User Sync**: `UserSyncService` handles data migration
3. **Error Handling**: All Firebase operations include proper error handling
4. **Real-time Updates**: Friends lists update automatically

## Security Rules

### Firestore Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Testing

### Manual Testing
1. Register new user
2. Login with existing user
3. Navigate to profile page
4. Test "Add as friend" functionality
5. Test friend requests management
6. Verify friends list updates

### Firebase Console
- Monitor user creation in Authentication
- Check Firestore for user documents
- Verify friends relationships
- Monitor friend requests

## Troubleshooting

### Common Issues
1. **Firebase not initialized**: Ensure `Firebase.initializeApp()` is called in `main()`
2. **User not authenticated**: Check Firebase Auth state
3. **Friends not loading**: Verify Firestore permissions
4. **Sync issues**: Check network connectivity and Firebase configuration

### Debug Information
- All Firebase operations include console logging
- Error messages are displayed to users
- Network errors are handled gracefully

## Future Enhancements
- Push notifications for friend requests
- Real-time chat functionality
- Friend activity feed
- Advanced friend search and filtering
- Friend recommendations 