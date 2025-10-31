import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/buttons/primary_button.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../services/auth_storage.dart';
import '../../phoneLogin/number_verify_screen.dart';
import '../../pin/pin_setup_screen.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isPhoneValid = false;
  bool _isSubmitting = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handlePhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneChanged() {
    final digitsOnly =
        _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final nextIsValid = digitsOnly.length >= 10;

    if (nextIsValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = nextIsValid;
      });
    }
  }

  InputDecoration _buildInputDecoration(
    String hint, {
    Widget? suffix,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B6C3), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.transparent),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Color(0xFF8FD7B6), width: 1.2),
      ),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: titleColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ) ??
          const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
    );
  }

  Widget _buildVerifiedIcon({Key? key}) {
    return Container(
      key: key,
      height: 24,
      width: 24,
      decoration: const BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check, color: Colors.white, size: 14),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final storage = AuthStorage.instance;
    final phoneRaw = _phoneController.text;
    final phone = storage.normalizePhone(phoneRaw);
    final account = await storage.getAccount(phone);
    if (!mounted) return;

    if (account == null) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Account not found. Please sign up.')),
      );
      return;
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => NumberVerifyScreen(
          phone: phone,
          displayPhone: phoneRaw,
          onVerified: (ctx) async {
            final innerNavigator = Navigator.of(ctx);
            await storage.setCurrentUser(phone);
            await storage.markVerified(phone);
            final hasPin = await storage.hasPin();
            if (!innerNavigator.mounted) return;
            if (!hasPin) {
              innerNavigator.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PinSetupScreen(
                    onCompleted: (innerCtx) {
                      Navigator.of(innerCtx).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const EntryPoint()),
                        (_) => false,
                      );
                    },
                  ),
                ),
              );
            } else {
              innerNavigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const EntryPoint()),
                (_) => false,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(context, "Enter your phone"),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            validator: phoneNumberValidator.call,
            onSaved: (value) {},
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: _buildInputDecoration(
              "+998 91 123 54 56",
              suffix: AnimatedSwitcher(
                duration: kDefaultDuration,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _isPhoneValid
                    ? _buildVerifiedIcon(key: const ValueKey("valid"))
                    : const SizedBox(
                        key: ValueKey("invalid"),
                        height: 24,
                        width: 24,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'We will send a 4-digit code to this number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Send Code',
            isLoading: _isSubmitting,
            press: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
