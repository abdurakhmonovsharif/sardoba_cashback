import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/welcome_text.dart';
import '../../constants.dart';
import 'components/otp_form.dart';

class NumberVerifyScreen extends StatelessWidget {
  const NumberVerifyScreen({
    super.key,
    required this.phone,
    required this.onVerified,
    this.expectedCode = '1234',
    this.displayPhone,
    this.title,
    this.subtitle,
  });

  final String phone;
  final Future<void> Function(BuildContext context) onVerified;
  final String expectedCode;
  final String? displayPhone;
  final String? title;
  final String? subtitle;

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
                    'Enter the 4-digit code sent to ${displayPhone ?? '+$phone'}.'
                        '\nUse code $expectedCode to continue.',
              ),

              // OTP form
              OtpForm(
                onSubmit: (code) async {
                  if (code == expectedCode) {
                    await onVerified(context);
                    return true;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect code, try again.')),
                  );
                  return false;
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
