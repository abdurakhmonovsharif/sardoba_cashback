import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language.dart';
import 'app_localizations.dart';
import 'constants.dart';
import 'entry_point.dart';
import 'navigation/app_navigator.dart';
import 'screens/onboarding/onboarding_scrreen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/pin/pin_lock_screen.dart';
import 'services/auth_service.dart';
import 'services/auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.instance.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLanguage _language = AppLanguage.instance;
  late final Future<_AppStartDestination> _initialDestination =
      _resolveStartDestination();
  bool _splashFinished = false;

  Future<_AppStartDestination> _resolveStartDestination() async {
    final storage = AuthStorage.instance;
    final hasUser = await storage.hasCurrentUser();
    if (!hasUser) return _AppStartDestination.onboarding;
    await _syncCurrentAccount(storage);
    final hasPin = await storage.hasPin();
    return hasPin ? _AppStartDestination.pin : _AppStartDestination.entry;
  }

  Future<void> _syncCurrentAccount(AuthStorage storage) async {
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;
    final tokenType = await storage.getTokenType();
    final currentPhone = await storage.getCurrentUser();
    final authService = AuthService();
    try {
      final account = await authService.fetchProfileWithToken(
        accessToken: accessToken,
        tokenType: tokenType,
        fallbackPhone: currentPhone,
      );
      if (account == null) return;
      await storage.upsertAccount(account.copyWith(isVerified: true));
      if (currentPhone == null || currentPhone.isEmpty) {
        await storage.setCurrentUser(account.phone);
      }
    } on AuthUnauthorizedException {
      final refreshed = await storage.refreshTokens();
      if (!refreshed) {
        await AppNavigator.forceLogout();
      } else {
        final newToken = await storage.getAccessToken();
        final newType = await storage.getTokenType();
        if (newToken == null || newToken.isEmpty) {
          await AppNavigator.forceLogout();
        } else {
          try {
            final account = await authService.fetchProfileWithToken(
              accessToken: newToken,
              tokenType: newType,
              fallbackPhone: currentPhone,
            );
            if (account == null) return;
            await storage.upsertAccount(account.copyWith(isVerified: true));
            if (currentPhone == null || currentPhone.isEmpty) {
              await storage.setCurrentUser(account.phone);
            }
          } on AuthUnauthorizedException {
            await AppNavigator.forceLogout();
          }
        }
      }
    } catch (_) {
      // Ignore other sync errors during app launch.
    } finally {
      authService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    const appName = 'Sardoba';
    return AnimatedBuilder(
      animation: _language,
      builder: (context, _) {
        final locale = _language.locale;
        return AppLocalizations(
          locale: locale,
          child: MaterialApp(
            title: appName,
            navigatorKey: AppNavigator.navigatorKey,
            locale: locale.flutterLocale,
            supportedLocales: const [Locale('ru'), Locale('uz')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),

              // ✅ Add this block to fix status bar and app bar text color
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                systemOverlayStyle:
                    SystemUiOverlayStyle.dark, // 👈 black time & battery icons
              ),

              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: bodyTextColor),
                bodySmall: TextStyle(color: bodyTextColor),
              ),

              inputDecorationTheme: const InputDecorationTheme(
                contentPadding: EdgeInsets.all(defaultPadding),
                hintStyle: TextStyle(color: bodyTextColor),
              ),
            ),
            home: FutureBuilder<_AppStartDestination>(
              future: _initialDestination,
              builder: (context, snapshot) {
                if (!_splashFinished) {
                  return SplashScreen(
                    onFinished: () {
                      if (mounted) {
                        setState(() => _splashFinished = true);
                      }
                    },
                  );
                }
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                switch (snapshot.data!) {
                  case _AppStartDestination.onboarding:
                    return const OnboardingScreen();
                  case _AppStartDestination.entry:
                    return const EntryPoint();
                  case _AppStartDestination.pin:
                    return PinLockScreen(
                      onUnlocked: (ctx) {
                        Navigator.of(ctx).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const EntryPoint(),
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

enum _AppStartDestination { onboarding, entry, pin }
