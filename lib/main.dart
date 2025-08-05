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
import 'package:firstshot_app/forgot_password.dart';

// Booking & Coaching
import 'booking_page.dart';
import 'checkout_page.dart';
import 'coaching_select.dart';
import 'group_lesson.dart';
import 'groupclass.dart' as group;
import 'privateclass.dart'; // Legacy, optional
import 'private_lesson_page.dart';
import 'class_booking_info.dart';
import 'instructors_page.dart';

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


// e-Shop
import 'listproducts.dart';

void main() {
  runApp( ChangeNotifierProvider(
      create: (context) => UserProfile()..loadProfileData(),
      child: const MyApp(),
    ),);
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



        // Booking
        '/booking': (context) => const BookingPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/classbookinginfo': (context) => const ClassBookingInfoPage(),
        '/productcheckout': (context) => const ProductCheckoutPage(),

        // Coaching
        '/coaching': (context) => const CoachingSelect(),
        '/groupclass': (context) => const GroupLesson(),
        '/privateclass': (context) => const PrivateClass(), // optional
        '/private-lesson': (context) => const PrivateLessonPage(),

        // Matchmaking
        // '/matchmaking': (context) => const GameMatchPage(),
        '/createMatch': (context) => const CreateMatchPage(),

        // Transactions
        '/transactions': (context) => const TransactionsPage(),
        '/manage_card': (context) => const ManageCardPage(),
        '/transfer_credit': (context) => const TransferCreditPage(),
        '/credit_success': (context) => const CreditTransferSuccessPage(
          amount: "100",
          phone: "0123456789",
        ),

        // e-Shop
        '/listproducts': (context) => const ListProductsPage(),
      },
    );
  }
}
