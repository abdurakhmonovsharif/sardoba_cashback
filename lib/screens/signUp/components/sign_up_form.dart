import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/buttons/primary_button.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../models/account.dart';
import '../../../services/auth_storage.dart';
import '../../phoneLogin/number_verify_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool _showReferralField = false;
  bool _isPhoneValid = false;
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handlePhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
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

  InputDecoration _buildInputDecoration(String hint, {Widget? suffix}) {
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

  Widget _buildLabel(String text, TextStyle style) {
    return Text(text, style: style);
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
    final name = _nameController.text.trim();
    final phoneRaw = _phoneController.text;
    final normalizedPhone = storage.normalizePhone(phoneRaw);
    final referral = _referralController.text.trim().isEmpty
        ? null
        : _referralController.text.trim();

    final exists = await storage.accountExists(normalizedPhone);
    if (!mounted) return;
    if (exists) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('An account with this phone already exists')),
      );
      return;
    }

    final account = Account(
      name: name,
      phone: normalizedPhone,
      referralCode: referral,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => NumberVerifyScreen(
          phone: normalizedPhone,
          displayPhone: phoneRaw,
          expectedCode: '1234',
          onVerified: (ctx) async {
            final innerNavigator = Navigator.of(ctx);
            await storage.upsertAccount(
              account.copyWith(isVerified: true),
            );
            await storage.setCurrentUser(normalizedPhone);
            if (!innerNavigator.mounted) return;
            innerNavigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const EntryPoint()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: titleColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ) ??
        const TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Enter your name", labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            validator: requiredValidator.call,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration("Saidmurod"),
          ),
          const SizedBox(height: 16),
          _buildLabel("Enter your phone", labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            validator: phoneNumberValidator.call,
            onSaved: (value) {},
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            controller: _phoneController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: _buildInputDecoration(
              "+998 91 123 54 56",
              suffix: AnimatedSwitcher(
                duration: kDefaultDuration,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
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
            'We will send a 4-digit code to confirm your number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _showReferralField = !_showReferralField;
              });
            },
            child: AnimatedContainer(
              duration: kDefaultDuration,
              curve: Curves.easeInOut,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _showReferralField
                      ? primaryColor.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
                boxShadow: _showReferralField
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          offset: const Offset(0, 12),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Affitsant referral code",
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showReferralField ? 0.5 : 0,
                    duration: kDefaultDuration,
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF8D97A8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: kDefaultDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showReferralField
                ? Column(
                    children: [
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _referralController,
                        decoration:
                            _buildInputDecoration("Enter referral code"),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'Continue',
            isLoading: _isSubmitting,
            press: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
