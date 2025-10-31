import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

class AuthStorage {
  AuthStorage._();

  static final AuthStorage instance = AuthStorage._();

  static const _accountsKey = 'accounts';
  static const _currentUserKey = 'current_user';
  static const _pinKey = 'app_pin';

  SharedPreferences? _prefs;

  Future<void> ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<List<Account>> _loadAccounts() async {
    await ensureInitialized();
    final raw = _prefs!.getString(_accountsKey);
    return Account.listFromJson(raw);
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    await ensureInitialized();
    await _prefs!.setString(_accountsKey, Account.listToJson(accounts));
  }

  Future<bool> accountExists(String phone) async {
    final normalized = normalizePhone(phone);
    final accounts = await _loadAccounts();
    return accounts.any((account) => account.phone == normalized);
  }

  Future<Account?> getAccount(String phone) async {
    final normalized = normalizePhone(phone);
    final accounts = await _loadAccounts();
    try {
      return accounts.firstWhere((account) => account.phone == normalized);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertAccount(Account newAccount) async {
    final normalized = normalizePhone(newAccount.phone);
    final accounts = await _loadAccounts();
    final sanitized = newAccount.copyWith(phone: normalized);
    final index = accounts.indexWhere((account) => account.phone == normalized);
    if (index >= 0) {
      accounts[index] = sanitized;
    } else {
      accounts.add(sanitized);
    }
    await _saveAccounts(accounts);
  }

  Future<void> markVerified(String phone, {bool verified = true}) async {
    final normalized = normalizePhone(phone);
    final accounts = await _loadAccounts();
    final index = accounts.indexWhere((account) => account.phone == normalized);
    if (index >= 0) {
      accounts[index] = accounts[index].copyWith(isVerified: verified);
      await _saveAccounts(accounts);
    }
  }

  Future<void> setCurrentUser(String phone) async {
    await ensureInitialized();
    await _prefs!.setString(_currentUserKey, phone);
  }


  Future<void> clearCurrentUser() async {
    await ensureInitialized();
    await _prefs!.remove(_currentUserKey);
  }

  Future<String?> getCurrentUser() async {
    await ensureInitialized();
    return _prefs!.getString(_currentUserKey);
  }

  Future<Account?> getCurrentAccount() async {
    final currentPhone = await getCurrentUser();
    if (currentPhone == null) return null;
    return getAccount(currentPhone);
  }

  Future<bool> hasCurrentUser() async {
    return (await getCurrentUser()) != null;
  }

  Future<bool> hasPin() async {
    await ensureInitialized();
    return _prefs!.containsKey(_pinKey);
  }

  Future<void> savePin(String pin) async {
    await ensureInitialized();
    await _prefs!.setString(_pinKey, _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    await ensureInitialized();
    final stored = _prefs!.getString(_pinKey);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  Future<void> clearPin() async {
    await ensureInitialized();
    await _prefs!.remove(_pinKey);
  }

  String _hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
