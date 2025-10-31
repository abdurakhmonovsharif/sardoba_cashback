import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/auth_storage.dart';
import '../onboarding/onboarding_scrreen.dart';
import 'components/pin_widgets.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({
    super.key,
    required this.onUnlocked,
  });

  final void Function(BuildContext context) onUnlocked;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _currentPin = '';
  String? _error;
  bool _isVerifying = false;

  Future<void> _handleDigitTap(String digit) async {
    if (_currentPin.length >= 4 || _isVerifying) return;
    setState(() {
      _currentPin += digit;
      _error = null;
    });
    if (_currentPin.length == 4) {
      await _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final isValid = await AuthStorage.instance.verifyPin(_currentPin);
    if (!mounted) return;
    if (isValid) {
      widget.onUnlocked(context);
    } else {
      setState(() {
        _error = 'Incorrect PIN, try again';
        _currentPin = '';
        _isVerifying = false;
      });
    }
  }

  void _handleBackspace() {
    if (_currentPin.isEmpty || _isVerifying) return;
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  Future<void> _switchAccount() async {
    await AuthStorage.instance.clearPin();
    await AuthStorage.instance.clearCurrentUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(defaultPadding, 48, defaultPadding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 52, color: primaryColor),
              const SizedBox(height: 18),
              Text(
                'Enter your PIN',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock Sardoba to continue',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              PinDots(count: 4, filled: _currentPin.length),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFED5A5A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                const SizedBox(height: 32),
              Expanded(
                child: PinKeypad(
                  onDigitPressed: _handleDigitTap,
                  onBackspacePressed: _handleBackspace,
                  isBusy: _isVerifying,
                ),
              ),
              TextButton(
                onPressed: _isVerifying ? null : _switchAccount,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Switch account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
