import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/welcome_text.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'components/otp_form.dart';

class NumberVerifyScreen extends StatelessWidget {
  const NumberVerifyScreen({
    super.key,
    required this.phone,
    required this.onVerified,
    this.displayPhone,
    this.title,
    this.subtitle,
    this.demoCode,
  });

  final String phone;
  final Future<bool> Function(BuildContext context, String code) onVerified;
  final String? displayPhone;
  final String? title;
  final String? subtitle;
  final String? demoCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify phone number"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeText(
                title: title ?? 'Confirm your code',
                text: subtitle ??
                    _buildDefaultSubtitle(displayPhone ?? '+$phone', demoCode),
              ),

              // OTP form
              OtpForm(
                onSubmit: (code) async {
                  try {
                    final success = await onVerified(context, code);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not verify the code.'),
                        ),
                      );
                    }
                    return success;
                  } on AuthServiceException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                    return false;
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Something went wrong. Try again.'),
                        ),
                      );
                    }
                    return false;
                  }
                },
              ),
              const SizedBox(height: defaultPadding),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Didn’t receive code? ",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.w500),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Resend Again.",
                        style: const TextStyle(color: primaryColor),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Your OTP PIN resend code
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              const Center(
                child: Text(
                  "By Signing up you agree to our Terms \nConditions & Privacy Policy.",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}

String _buildDefaultSubtitle(String phoneLabel, String? demoCode) {
  final buffer = StringBuffer(
    'Enter the 4-digit code sent to $phoneLabel.',
  );
  if (demoCode != null && demoCode.isNotEmpty) {
    buffer.write('\nUse code $demoCode to continue.');
  }
  return buffer.toString();
}
