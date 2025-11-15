import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'onboarding_screen.dart';
import 'registration_screen.dart';
import 'main_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if onboarding completed
    final isOnboarded = await _storageService.isOnboardingCompleted();
    if (!isOnboarded) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
      return;
    }

    // Check if user is registered
    final userId = await _storageService.getUserId();
    if (userId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      );
      return;
    }

    // Load user profile
    try {
      final profileData = await _apiService.getProfile();
      final user = User.fromJson(profileData);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    } catch (e) {
      print('Error loading profile: $e');
      if (!mounted) return;

      // If profile load fails, go to registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.car_crash,
                size: 64,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Safe Ride',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            // const LoadingIndicator(message: 'Initializing...'),
          ],
        ),
      ),
    );
  }
}
