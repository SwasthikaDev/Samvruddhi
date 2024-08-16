// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/crop_info_screen.dart';
import 'screens/farm_details_screen.dart';
import 'screens/farm_location_screen.dart';
import 'screens/worker_info_screen.dart';
import 'screens/worker_management.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'themes/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'EcoYieldPro',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/email_verification': (context) => EmailVerificationScreen(),
          '/farm_location': (context) => FarmLocationScreen(),
          '/farm_details': (context) => FarmDetailsScreen(farmLocation: ModalRoute.of(context)!.settings.arguments as List<LatLng>),
          '/crop_info': (context) => CropInfoScreen(farmData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
          '/worker_info': (context) => WorkerInfoScreen(farmData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
          '/dashboard': (context) => DashboardScreen(),
          '/worker_management': (context) => WorkerManagementScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authService.user == null) {
      return LoginScreen();
    }

    return FutureBuilder(
      future: authService.isEmailVerified(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return DashboardScreen();
        } else {
          return EmailVerificationScreen();
        }
      },
    );
  }
}