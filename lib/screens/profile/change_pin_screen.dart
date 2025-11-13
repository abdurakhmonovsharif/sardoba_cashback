import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/auth_storage.dart';
import '../../utils/snackbar_utils.dart';
import '../pin/components/pin_widgets.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _ChangePinStep { verifyCurrent, enterNew, confirmNew }

class _ChangePinScreenState extends State<ChangePinScreen> {
  _ChangePinStep _step = _ChangePinStep.verifyCurrent;
  bool _hasExistingPin = false;
  bool _isBusy = false;
  bool _initialized = false;
  String _input = '';
  String? _firstNewPin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasPin = await AuthStorage.instance.hasPin();
    if (!mounted) return;
    setState(() {
      _hasExistingPin = hasPin;
      _step = hasPin ? _ChangePinStep.verifyCurrent : _ChangePinStep.enterNew;
      _initialized = true;
    });
  }

  void _onDigitPressed(String digit) {
    if (!_initialized || _isBusy) return;
    if (_input.length >= 4) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == 4) {
      _handleCompletedInput();
    }
  }

  void _onBackspace() {
    if (_input.isEmpty || _isBusy) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _handleCompletedInput() async {
    switch (_step) {
      case _ChangePinStep.verifyCurrent:
        await _verifyCurrentPin();
        break;
      case _ChangePinStep.enterNew:
        setState(() {
          _firstNewPin = _input;
          _input = '';
          _step = _ChangePinStep.confirmNew;
        });
        break;
      case _ChangePinStep.confirmNew:
        await _saveNewPin();
        break;
    }
  }

  Future<void> _verifyCurrentPin() async {
    setState(() => _isBusy = true);
    final isValid = await AuthStorage.instance.verifyPin(_input);
    if (!mounted) return;
    if (isValid) {
      setState(() {
        _step = _ChangePinStep.enterNew;
        _input = '';
        _isBusy = false;
      });
    } else {
      setState(() {
        _error = 'Incorrect PIN, try again';
        _input = '';
        _isBusy = false;
      });
    }
  }

  Future<void> _saveNewPin() async {
    if (_firstNewPin != _input) {
      setState(() {
        _error = 'PIN codes do not match. Please start over.';
        _input = '';
        _firstNewPin = null;
        _step = _ChangePinStep.enterNew;
      });
      return;
    }
    setState(() => _isBusy = true);
    await AuthStorage.instance.savePin(_input);
    if (!mounted) return;
    showNavAwareSnackBar(
      context,
      content: const Text('PIN updated'),
    );
    Navigator.of(context).pop();
  }

  void _resetFlow() {
    setState(() {
      _step = _hasExistingPin
          ? _ChangePinStep.verifyCurrent
          : _ChangePinStep.enterNew;
      _input = '';
      _firstNewPin = null;
      _error = null;
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _buildTitle();
    final subtitle = _buildSubtitle();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Change PIN',
          style: theme.textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(defaultPadding, 32, defaultPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _step == _ChangePinStep.verifyCurrent
                    ? Icons.lock_outline_rounded
                    : Icons.shield_outlined,
                size: 48,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 28),
              PinDots(count: 4, filled: _input.length),
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
                  onDigitPressed: _onDigitPressed,
                  onBackspacePressed: _onBackspace,
                  isBusy: _isBusy || !_initialized,
                ),
              ),
              TextButton(
                onPressed: _isBusy ? null : _resetFlow,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Text(_step == _ChangePinStep.verifyCurrent
                    ? 'Try again'
                    : 'Start over'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTitle() {
    switch (_step) {
      case _ChangePinStep.verifyCurrent:
        return 'Enter current PIN';
      case _ChangePinStep.enterNew:
        return 'Create a new PIN';
      case _ChangePinStep.confirmNew:
        return 'Confirm new PIN';
    }
  }

  String _buildSubtitle() {
    switch (_step) {
      case _ChangePinStep.verifyCurrent:
        return 'We need to confirm it\'s you before updating the code';
      case _ChangePinStep.enterNew:
        return 'Use a 4-digit number that you will remember';
      case _ChangePinStep.confirmNew:
        return 'Re-enter the PIN to make sure it is correct';
    }
  }
}
