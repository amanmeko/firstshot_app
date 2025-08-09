import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core Screens
import 'splash_screen.dart';
import 'login_welcome_screen.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'new_password_screen.dart';
import 'password_changed_screen.dart';
import 'login_screen.dart';
import 'main_page.dart';
import 'gamematchset.dart';
import 'user_profile.dart';

// General Screens
import 'listevent.dart';
import 'settings_page.dart';
import 'about_us_page.dart';
import 'contact_us_page.dart';
import 'data_deletion_page.dart';
import 'privacy_policy_page.dart';
import 'forgot_password.dart';
import 'profile_page.dart';
import 'edit_profile_page.dart';
import 'newsinfo.dart';

// Friends Screens
import 'add_friends_page.dart';
import 'friend_requests_page.dart';

// Booking & Coaching
import 'booking_page.dart';
import 'bookingdetails.dart' as booking_details_create;
import 'booking_details.dart' as booking_details_view;
import 'booking_list_page.dart';
import 'checkout_page.dart';
import 'coaching_select.dart';
import 'group_lesson.dart';
import 'private_lesson_page.dart';
import 'class_booking_info.dart';
import 'instructors_page.dart';
import 'CoachProfilePage.dart';
import 'widgets/protected_route.dart';

// Game & Match
import 'game_match_page.dart';
import 'create_match_page.dart';

// Transactions
import 'transactions_page.dart';
import 'manage_card_page.dart';
import 'transfer_credit_page.dart';
import 'credit_transfer_success.dart';
import 'productcheckout.dart';
import 'listproducts.dart';
import 'receipt.dart';
import 'payment_webview_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization removed - now using Laravel backend
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProfile()..loadProfileData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirstShot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        // Auth
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const LoginWelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/otp': (context) => const OtpScreen(),
        '/new_password': (context) => const NewPasswordScreen(),
        '/password_changed': (context) => const PasswordChangedScreen(),

        // Main
        '/main': (context) => const MainPage(),
        '/event': (context) => const ListEventsPage(),

        // Profile & Settings
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/editprofile': (context) => const EditProfilePage(),

        // Friends
        '/add_friends': (context) => const AddFriendsPage(),
        '/friend_requests': (context) => const FriendRequestsPage(),

        // Info Pages
        '/about': (context) => const AboutUsPage(),
        '/contact': (context) => const ContactUsPage(),
        '/DataDeletionPage': (context) => const DataDeletionPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/newsinfo': (context) => const NewsInfoPage(),
        '/merchandise': (context) => const ListProductsPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/gamematchset': (context) => const GameMatchSetPage(),

        // Booking (Protected Routes)
        '/booking': (context) => const ProtectedRoute(
          routeName: 'Booking',
          child: BookingPage(),
        ),
        '/booking-list': (context) => const ProtectedRoute(
          routeName: 'Booking List',
          child: BookingListPage(),
        ),
        '/checkout': (context) => const ProtectedRoute(
          routeName: 'Checkout',
          child: CheckoutPage(),
        ),
        '/booking-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final bookingId = args is int ? args : null;
          return ProtectedRoute(
            routeName: 'Booking Details',
            child: booking_details_view.BookingDetailsPage(
              bookingId: bookingId ?? 0,
            ),
          );
        },
        '/classbookinginfo': (context) => const ProtectedRoute(
          routeName: 'Class Booking',
          child: ClassBookingInfoPage(),
        ),
        '/productcheckout': (context) => const ProtectedRoute(
          routeName: 'Product Checkout',
          child: ProductCheckoutPage(),
        ),

        // Coaching
        '/coaching': (context) => const CoachingSelect(),
        '/groupclass': (context) => const GroupLessonScreen(),
        '/private-lesson': (context) => const PrivateLessonPage(),
        '/coach_profile': (context) => const CoachProfilePage(),

        // Matchmaking
        '/createMatch': (context) => const CreateMatchPage(),

        // Transactions
        '/transactions': (context) => const TransactionsPage(),
        '/manage_card': (context) => const ManageCardPage(),
        '/transfer_credit': (context) => const TransferCreditPage(),
        '/credit_success': (context) => const CreditTransferSuccessPage(
              amount: "100",
              phone: "0123456789",
            ),
        '/receipts': (context) => const ProtectedRoute(
          routeName: 'Receipts',
          child: ReceiptScreen(),
        ),
        '/payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String url = '';
          if (args is Map) {
            url = (args['url'] ?? '').toString();
          }
          return ProtectedRoute(
            routeName: 'Payment',
            child: PaymentWebViewPage(
              paymentUrl: url,
              onPaymentComplete: (transactionData) {
                // Handle payment completion
                if (transactionData != null) {
                  final isSuccess = transactionData['status'] == '00' || transactionData['status'] == 'completed';
                  
                  // Navigate to receipt page
                  Navigator.pushReplacementNamed(
                    context,
                    '/receipts',
                    arguments: {
                      'transactionData': transactionData,
                      'isSuccess': isSuccess,
                    },
                  );
                } else {
                  // Payment was cancelled or failed
                  Navigator.pop(context, 'cancelled');
                }
              },
            ),
          );
        },

        // e-Shop
        '/listproducts': (context) => const ListProductsPage(),
      },
    );
  }
}