import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/auth/login_page.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading spinner while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A1538)),
              ),
            ),
          );
        }

        // Show login page if not authenticated
        if (!snapshot.hasData || !snapshot.data!) {
          return const LoginPage();
        }

        // Show the main app if authenticated
        return child;
      },
    );
  }
}
