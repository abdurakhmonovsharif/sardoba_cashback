import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_language.dart';
import '../../app_localizations.dart';
import '../../components/combined_card_widget.dart';
import '../../constants.dart';
import '../../models/account.dart';
import '../../navigation/app_navigator.dart';
import '../../services/auth_service.dart';
import '../../services/auth_storage.dart';
import '../../utils/snackbar_utils.dart';
import '../cashback/cashback_screen.dart';
import '../notifications/notifications_screen.dart';
import 'change_pin_screen.dart';
import 'help_center_screen.dart';
import 'profile_information_screen.dart';
import 'refer_friends_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l10n.profileTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  late Future<Account?> _accountFuture;
  static const int _cashbackThreshold = 30000;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _accountFuture = _fetchAccount();
  }

  void _refreshAccount() {
    setState(() {
      _accountFuture = _fetchAccount();
    });
  }

  Future<Account?> _fetchAccount() async {
    final storage = AuthStorage.instance;
    var account = await storage.getCurrentAccount();
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) return account;
    final tokenType = await storage.getTokenType();
    final currentPhone = await storage.getCurrentUser();
    final authService = AuthService();
    try {
      final profile = await authService.fetchProfileWithToken(
        accessToken: token,
        tokenType: tokenType,
        fallbackPhone: currentPhone,
        fallbackName: account?.name,
      );
      if (profile != null) {
        await storage.upsertAccount(profile.copyWith(isVerified: true));
        account = profile;
      }
    } on AuthUnauthorizedException {
      final refreshed = await storage.refreshTokens();
      if (!refreshed) {
        await AppNavigator.forceLogout();
        account = null;
      } else {
        final newToken = await storage.getAccessToken();
        final newType = await storage.getTokenType();
        if (newToken == null || newToken.isEmpty) {
          await AppNavigator.forceLogout();
          account = null;
        } else {
          try {
            final profile = await authService.fetchProfileWithToken(
              accessToken: newToken,
              tokenType: newType,
              fallbackPhone: currentPhone,
              fallbackName: account?.name,
            );
            if (profile != null) {
              await storage.upsertAccount(profile.copyWith(isVerified: true));
              account = profile;
            }
          } on AuthUnauthorizedException {
            await AppNavigator.forceLogout();
            account = null;
          }
        }
      }
    } catch (_) {
      // Ignore sync errors; fallback to cached account.
    } finally {
      authService.dispose();
    }
    return account;
  }

  Future<void> _openProfileInfo(Account? account) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileInformationScreen(account: account),
      ),
    );
    if (shouldRefresh == true) {
      _refreshAccount();
    }
  }

  Future<void> _openChangePin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangePinScreen()),
    );
  }

  Future<void> _openHelpCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
    );
  }

  Future<void> _openReferFriends(Account? account) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReferFriendsScreen(account: account),
      ),
    );
    if (!mounted) return;
    _refreshAccount();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openCashback(Account? account) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CashbackScreen(
          account: account,
          threshold: _cashbackThreshold,
          initialBalance:
              account?.loyalty?.currentPoints ?? account?.cashbackBalance,
          initialEntries: account?.cashbackHistory,
          initialLoyalty: account?.loyalty,
        ),
      ),
    );
    if (!mounted) return;
    _refreshAccount();
  }

  Future<ImageSource?> _selectImageSource() async {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profileAvatarActionCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profileAvatarActionGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) return;
    final source = await _selectImageSource();
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final storage = AuthStorage.instance;
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileLoginRequired),
      );
      return;
    }
    final tokenType = await storage.getTokenType();
    final fallbackPhone = await storage.getCurrentUser();
    final cachedAccount = await storage.getCurrentAccount();
    final authService = AuthService();
    if (!mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final updated = await authService.uploadProfilePhoto(
        accessToken: accessToken,
        tokenType: tokenType,
        file: File(picked.path),
        fallbackPhone: fallbackPhone,
        fallbackName: cachedAccount?.name,
      );
      await storage.upsertAccount(updated.copyWith(isVerified: true));
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileAvatarUploadSuccess),
      );
      _refreshAccount();
    } on AuthUnauthorizedException {
      await AppNavigator.forceLogout();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      showNavAwareSnackBar(
        context,
        content: Text(error.message),
      );
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileAvatarUploadError),
      );
    } finally {
      authService.dispose();
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) return;
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteConfirmTitle),
        content: Text(l10n.profileDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileDeleteConfirmSecondary),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.profileDeleteConfirmPrimary),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    final l10n = AppLocalizations.of(context);
    final storage = AuthStorage.instance;
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) return;
      showNavAwareSnackBar(
        context,
        content: Text(l10n.profileLoginRequired),
      );
      return;
    }
    final tokenType = await storage.getTokenType();
    final authService = AuthService();
    setState(() => _isDeletingAccount = true);
    try {
      await authService.deleteAccount(
        accessToken: accessToken,
        tokenType: tokenType,
      );
      if (mounted) {
        showNavAwareSnackBar(
          context,
          content: Text(l10n.profileDeleteSuccess),
        );
      }
      await AppNavigator.forceLogout();
    } on AuthUnauthorizedException {
      await AppNavigator.forceLogout();
    } on AuthServiceException catch (error) {
      if (mounted) {
        showNavAwareSnackBar(
          context,
          content: Text(error.message),
        );
      }
    } finally {
      authService.dispose();
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account?>(
      future: _accountFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final account = snapshot.data;
        final double scrollBottomPadding =
            navAwareBottomPadding(context, extra: 24);
        return SafeArea(
          top: true,
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                defaultPadding, 0, defaultPadding, scrollBottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  account: account,
                  onEdit: () => _openProfileInfo(account),
                  onAvatarTap: account == null ? null : () => _changeAvatar(),
                  isAvatarUploading: _isUploadingAvatar,
                ),
                const SizedBox(height: 20),
                _LoyaltyHighlight(
                  account: account,
                  onCashbackTap:
                      account == null ? null : () => _openCashback(account),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  onProfileInfoTap: () => _openProfileInfo(account),
                  onChangePinTap: _openChangePin,
                  onNotificationsTap: _openNotifications,
                ),
                const SizedBox(height: 24),
                _SupportSection(
                  onHelpCenterTap: _openHelpCenter,
                  onReferFriendsTap: () => _openReferFriends(account),
                  showRefer: false,
                ),
                const SizedBox(height: 28),
                const _LogoutButton(),
                if (account != null) ...[
                  const SizedBox(height: 12),
                  _DeleteAccountButton(
                    isLoading: _isDeletingAccount,
                    onDelete: _confirmDeleteAccount,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    this.account,
    required this.onEdit,
    this.onAvatarTap,
    required this.isAvatarUploading,
  });

  final Account? account;
  final VoidCallback onEdit;
  final VoidCallback? onAvatarTap;
  final bool isAvatarUploading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final displayName = (account?.name.trim().isEmpty ?? true)
        ? l10n.profileGuestName
        : account!.name.trim();
    final displayPhone = account == null ? '—' : _formatPhone(account?.phone);
    final initials = _initials(displayName);
    final hasPhoto = (account?.profilePhotoUrl ?? '').isNotEmpty;
    final dob = account?.dateOfBirth;

    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0DD277), Color(0xFF0AA35D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: hasPhoto
                        ? NetworkImage(account!.profilePhotoUrl!)
                        : null,
                    child: !hasPhoto
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isAvatarUploading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: primaryColor,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayPhone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: bodyTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dob != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.profileDobLabel}: ${l10n.formatDateDdMMyyyy(dob)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bodyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (account == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.profileLoginRequired,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bodyTextColor,
                    ),
                  ),
                ],
                if ((account?.loyalty?.level ?? account?.level)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFDE9C37)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.profileTierBadge(
                            account?.loyalty?.level ?? account?.level ?? '',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A6C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: primaryColor),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String? digits) {
    if (digits == null || digits.isEmpty) return '+998 -- --- -- --';
    final buffer = StringBuffer('+');
    buffer.write(digits);
    return buffer.toString();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'GU';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final result = (first + second).toUpperCase();
    return result.isEmpty ? 'GU' : result;
  }
}

class _LoyaltyHighlight extends StatelessWidget {
  const _LoyaltyHighlight({
    required this.account,
    required this.onCashbackTap,
  });

  final Account? account;
  final VoidCallback? onCashbackTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRu = l10n.locale == AppLocale.ru;
    final loyalty = account?.loyalty;
    final balanceValue = loyalty?.currentPoints ?? account?.cashbackBalance;
    final balanceLabel =
        balanceValue != null ? _formatCurrency(balanceValue, isRu) : '—';
    final helper = account == null
        ? l10n.cashbackLoginRequired
        : loyalty == null
            ? l10n.cashbackHelper
            : loyalty.isMaxLevel
                ? l10n.loyaltyMaxLevelHelper
                : (loyalty.nextLevel?.isNotEmpty == true &&
                        loyalty.pointsToNext != null)
                    ? l10n.loyaltyPointsToNextHelper(
                        _formatPoints(loyalty.pointsToNext ?? 0),
                        loyalty.nextLevel ?? '',
                      )
                    : l10n.cashbackHelper;
    final tierTitle = loyalty?.level?.isNotEmpty == true
        ? loyalty!.level!
        : l10n.membershipTitle;
    final tierNote = loyalty == null
        ? l10n.membershipHelper
        : loyalty.isMaxLevel
            ? l10n.loyaltyMaxLevelHelper
            : l10n.loyaltyNextLevelLabel(loyalty.nextLevel ?? '');
    final currentLabel = loyalty == null
        ? l10n.membershipHelper
        : l10n.loyaltyProgressLabel(
            _formatPoints(loyalty.currentLevelPoints ?? 0),
            _formatPoints(loyalty.currentLevelMax ?? 0),
          );

    return CombinedCardWidget(
      balanceLabel: l10n.cashbackTitle,
      balanceValue: balanceLabel,
      balanceNote: helper,
      tierTitle: tierTitle,
      tierNote: tierNote,
      currentPointsText: currentLabel,
      onTap: onCashbackTap,
    );
  }

  String _formatCurrency(double value, bool isRu) {
    final formatted = _formatPoints(value);
    final suffix = isRu ? 'сум' : 'soʻm';
    return '$formatted $suffix';
  }

  String _formatPoints(double value) {
    final text =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    final reversed = text.split('').reversed;
    final buffer = StringBuffer();
    var count = 0;
    for (final char in reversed) {
      if (count != 0 && count % 3 == 0) buffer.write(' ');
      buffer.write(char);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join();
    return formatted;
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.onProfileInfoTap,
    required this.onChangePinTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onProfileInfoTap;
  final VoidCallback onChangePinTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.profileAccountSection),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.person_outline,
          title: l10n.profileInfoMenuTitle,
          subtitle: l10n.profileInfoMenuSubtitle,
          onTap: onProfileInfoTap,
        ),
        _ProfileMenuCard(
          icon: Icons.lock_outline,
          title: l10n.profilePinMenuTitle,
          subtitle: l10n.profilePinMenuSubtitle,
          onTap: onChangePinTap,
        ),
        _ProfileMenuCard(
          icon: Icons.notifications_active_outlined,
          title: l10n.profileNotificationsMenuTitle,
          subtitle: l10n.profileNotificationsMenuSubtitle,
          onTap: onNotificationsTap,
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
    required this.onHelpCenterTap,
    this.onReferFriendsTap,
    this.showRefer = true,
  });

  final VoidCallback onHelpCenterTap;
  final VoidCallback? onReferFriendsTap;
  final bool showRefer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.profileSupportSection),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.headset_mic_outlined,
          title: l10n.profileHelpMenuTitle,
          subtitle: l10n.profileHelpMenuSubtitle,
          onTap: onHelpCenterTap,
        ),
        if (showRefer && onReferFriendsTap != null)
          _ProfileMenuCard(
            icon: Icons.card_giftcard_outlined,
            title: l10n.profileReferMenuTitle,
            subtitle: l10n.profileReferMenuSubtitle,
            onTap: onReferFriendsTap!,
          ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.profileLogoutConfirmTitle),
            content: Text(l10n.profileLogoutConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.profileLogoutConfirmSecondary),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.profileLogoutConfirmPrimary),
              ),
            ],
          ),
        );
        if (shouldLogout == true) {
          await AppNavigator.forceLogout();
        }
      },
      icon: const Icon(Icons.logout_rounded),
      label: Text(
        l10n.profileLogout,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFED5A5A),
        side: const BorderSide(color: Color(0xFFED5A5A)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({
    required this.onDelete,
    required this.isLoading,
  });

  final VoidCallback onDelete;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: isLoading ? null : onDelete,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFB3261E),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.profileDeleteAccount),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: bodyTextColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: bodyTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
