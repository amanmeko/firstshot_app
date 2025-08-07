import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_helper.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String routeName;

  const ProtectedRoute({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthHelper.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          // Redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please log in to access $routeName'),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          });
          
          return const Scaffold(
            body: Center(
              child: Text('Redirecting to login...'),
            ),
          );
        }
      },
    );
  }
}
