import 'package:flutter/material.dart';

import '../../components/buttons/primary_button.dart';
import '../../components/welcome_text.dart';
import '../../constants.dart';
import '../../entry_point.dart';
import '../../services/auth_service.dart';
import '../../services/auth_storage.dart';
import 'number_verify_screen.dart';

class PghoneLoginScreen extends StatefulWidget {
  const PghoneLoginScreen({super.key});

  @override
  State<PghoneLoginScreen> createState() => _PghoneLoginScreenState();
}

class _PghoneLoginScreenState extends State<PghoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String? phoneNumber;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to Foodly"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: "Get started with Foodly",
                text:
                    "Enter your phone number to use foodly \nand enjoy your food :)",
              ),
              const SizedBox(height: defaultPadding),
              Form(
                key: _formKey,
                child: TextFormField(
                  validator: phoneNumberValidator.call,
                  autofocus: true,
                  onSaved: (value) => phoneNumber = value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: titleColor),
                  cursorColor: primaryColor,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Phone Number",
                    contentPadding: kTextFieldPadding,
                  ),
                ),
              ),
              const Spacer(),
              // Sign Up Button
              PrimaryButton(
                text: "Send Code",
                press: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final raw = phoneNumber ?? '';
                    final storage = AuthStorage.instance;
                    final normalized = storage.normalizePhone(raw);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NumberVerifyScreen(
                          phone: normalized,
                          displayPhone: raw,
                          onVerified: (ctx, code) async {
                            final messenger = ScaffoldMessenger.of(ctx);
                            final authService = AuthService();
                            try {
                              final session = await authService.verifyOtp(
                                phone: normalized,
                                code: code,
                                purpose: 'login',
                              );
                              await storage.upsertAccount(
                                session.account.copyWith(isVerified: true),
                              );
                              await storage
                                  .setCurrentUser(session.account.phone);
                              await storage.saveAuthTokens(
                                accessToken: session.accessToken,
                                refreshToken: session.refreshToken,
                                tokenType: session.tokenType,
                              );
                              if (!ctx.mounted) return false;
                              final innerNavigator = Navigator.of(ctx);
                              innerNavigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const EntryPoint()),
                                (_) => false,
                              );
                              return true;
                            } on AuthServiceException catch (error) {
                              messenger.showSnackBar(
                                  SnackBar(content: Text(error.message)));
                              return false;
                            } catch (_) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to verify. Please try again.'),
                                ),
                              );
                              return false;
                            } finally {
                              authService.dispose();
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
