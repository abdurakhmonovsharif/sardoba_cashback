import 'package:flutter/material.dart';

import '../screens/onboarding/onboarding_scrreen.dart';
import '../services/auth_storage.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> forceLogout() async {
    await AuthStorage.instance.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }
}
