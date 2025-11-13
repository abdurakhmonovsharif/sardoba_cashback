import 'package:flutter/material.dart';

import '../../app_localizations.dart';
import '../../constants.dart';
import '../../models/account.dart';
import '../../navigation/app_navigator.dart';
import '../../services/auth_service.dart';
import '../../services/auth_storage.dart';
import '../../utils/snackbar_utils.dart';

class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key, this.account});

  final Account? account;

  @override
  State<ProfileInformationScreen> createState() =>
      _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _referralController;
  bool _isSaving = false;
  DateTime? _selectedDob;
  String? _dobError;

  Account? get _initialAccount => widget.account;

  @override
  void initState() {
    super.initState();
    final account = _initialAccount;
    _nameController = TextEditingController(text: account?.name ?? '');
    _phoneController = TextEditingController(
      text: _formatPhone(account?.phone ?? ''),
    );
    _referralController =
        TextEditingController(text: account?.referralCode ?? '');
    _selectedDob = account?.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final account = _initialAccount;
    final l10n = AppLocalizations.of(context);
    if (account == null) {
      Navigator.of(context).maybePop(false);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      setState(() => _dobError = l10n.profileDobValidation);
      return;
    }
    setState(() => _isSaving = true);
    final storage = AuthStorage.instance;
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileLoginRequired),
      );
      return;
    }
    final tokenType = await storage.getTokenType();
    final authService = AuthService();
    try {
      final response = await authService.updateUserProfile(
        accessToken: accessToken,
        tokenType: tokenType,
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDob,
        fallbackPhone: account.phone,
        fallbackName: account.name,
      );
      final referralValue = _referralController.text.trim();
      final merged = response.copyWith(
        referralCode: referralValue.isEmpty ? null : referralValue,
      );
      await storage.upsertAccount(merged.copyWith(isVerified: true));
      if (!mounted) return;
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileInfoSaveSuccess),
      );
      Navigator.of(context).pop(true);
    } on AuthUnauthorizedException {
      await AppNavigator.forceLogout();
    } on AuthServiceException catch (error) {
      if (mounted) {
        showNavAwareSnackBar(
          context,
          content: Text(error.message),
        );
      }
    } catch (_) {
      if (mounted) {
        showNavAwareSnackBar(
          context,
          content: Text(l10n.commonErrorTryAgain),
        );
      }
    } finally {
      authService.dispose();
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final approxInitial = DateTime(now.year - 18, now.month, now.day);
    final initial = _selectedDob ??
        (approxInitial.isBefore(DateTime(1900))
            ? DateTime(1900)
            : (approxInitial.isAfter(now) ? now : approxInitial));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: AppLocalizations.of(context).profileDobLabel,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasAccount = _initialAccount != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.profileInfoMenuTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            defaultPadding,
            24,
            defaultPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasAccount)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.profileInfoSignInHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: bodyTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.profileInfoSectionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: l10n.formFullNameLabel,
                        helper: '',
                        child: TextFormField(
                          controller: _nameController,
                          enabled: hasAccount,
                          decoration: _fieldDecoration(l10n.formFullNameHint),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n.formFullNameRequired;
                            }
                            if ((value ?? '').trim().length < 2) {
                              return l10n.formFullNameTooShort;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: l10n.formPhoneLabel,
                        helper: '',
                        child: TextFormField(
                          controller: _phoneController,
                          readOnly: true,
                          enabled: hasAccount,
                          decoration: _fieldDecoration('—'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: l10n.profileDobLabel,
                        helper: '',
                        error: _dobError,
                        child: _DobPicker(
                          enabled: hasAccount,
                          hasValue: _selectedDob != null,
                          displayText: _selectedDob != null
                              ? l10n.formatDateDdMMyyyy(_selectedDob!)
                              : l10n.profileDobPlaceholder,
                          showError: _dobError != null,
                          onTap: hasAccount ? _pickBirthDate : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: !hasAccount || _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.formSaveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _formatPhone(String digits) {
    if (digits.isEmpty) return '+998 -- --- -- --';
    if (digits.startsWith('+')) return digits;
    return '+$digits';
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.helper,
    this.error,
  });

  final String label;
  final Widget child;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (helper != null && error == null) ...[
          const SizedBox(height: 8),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: bodyTextColor,
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }
}

class _DobPicker extends StatelessWidget {
  const _DobPicker({
    required this.enabled,
    required this.displayText,
    required this.hasValue,
    this.showError = false,
    this.onTap,
  });

  final bool enabled;
  final String displayText;
  final bool hasValue;
  final bool showError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = hasValue ? titleColor : bodyTextColor;
    final textColor =
        enabled ? baseColor : bodyTextColor.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showError ? Colors.redAccent : Colors.transparent,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: textColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
