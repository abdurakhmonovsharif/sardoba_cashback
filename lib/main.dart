import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language.dart';
import 'app_localizations.dart';
import 'constants.dart';
import 'entry_point.dart';
import 'screens/onboarding/onboarding_scrreen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/pin/pin_lock_screen.dart';
import 'services/auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.instance.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
    final hasPin = await storage.hasPin();
    return hasPin ? _AppStartDestination.pin : _AppStartDestination.entry;
  }

  @override
  Widget build(BuildContext context) {
    final appName = dotenv.env['API_BASE_URL'];
    return AnimatedBuilder(
      animation: _language,
      builder: (context, _) {
        final locale = _language.locale;
        return AppLocalizations(
          locale: locale,
          child: MaterialApp(
            title: appName ?? 'Sardoba',
            locale: locale.flutterLocale,
            supportedLocales: const [Locale('ru'), Locale('uz')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
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
