// lib/screens/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Verify Your Email')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please verify your email address.',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: authService.isLoading
                  ? null
                  : () async {
                try {
                  await authService.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification email sent')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send verification email: $e')),
                  );
                }
              },
              child: authService.isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Resend Verification Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: authService.isLoading
                  ? null
                  : () async {
                try {
                  await authService.signOut();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign out: $e')),
                  );
                }
              },
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}