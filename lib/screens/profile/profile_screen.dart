import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/account.dart';
import '../../services/auth_storage.dart';
import '../onboarding/onboarding_scrreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account?>(
      future: AuthStorage.instance.getCurrentAccount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final account = snapshot.data;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                defaultPadding, 0, defaultPadding, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(account: account),
                const SizedBox(height: 20),
                const _LoyaltyHighlight(),
                const SizedBox(height: 24),
                const _SettingsSection(),
                const SizedBox(height: 24),
                const _SupportSection(),
                const SizedBox(height: 28),
                const _LogoutButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.account});

  final Account? account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        (account?.name.trim().isEmpty ?? true) ? 'Guest' : account!.name.trim();
    final displayPhone = _formatPhone(account?.phone);
    final initials = _initials(displayName);
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
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
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
                    children: const [
                      Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFDE9C37)),
                      SizedBox(width: 6),
                      Text(
                        'Gold member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9A6C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
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
  const _LoyaltyHighlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _TierStatTile(
            label: 'Cashback balance',
            value: '50 000 soʻm',
            helper: 'Redeem available at 75 000 soʻm',
            accent: Color(0xFF0DD277),
          ),
          SizedBox(height: 18),
          _TierStatTile(
            label: 'Membership level',
            value: 'Silver',
            helper: 'Reach Gold at 3,000 pts',
            accent: Color(0xFF8C6CFF),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _TierStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color accent;
  final bool highlight;

  const _TierStatTile({
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0xFFFFF3CE), Color(0xFFFFF7E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : const Color(0xFFF7F8FA),
        border: Border.all(
          color: highlight
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: const Color(0x55FFD76F),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlight ? const Color(0xFF876523) : titleColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: highlight ? const Color(0xFF7050FF) : accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: highlight ? const Color(0xFF6F603F) : bodyTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(title: 'Account'),
        SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.person_outline,
          title: 'Profile information',
          subtitle: 'Change name, phone and preferences',
        ),
        _ProfileMenuCard(
          icon: Icons.lock_outline,
          title: 'Change password',
          subtitle: 'Update your account security',
        ),
        _ProfileMenuCard(
          icon: Icons.location_on_outlined,
          title: 'Saved locations',
          subtitle: 'Delivery and pickup addresses',
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(title: 'Support & more'),
        SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.headset_mic_outlined,
          title: 'Help center',
          subtitle: 'FAQ, live chat and contact options',
        ),
        _ProfileMenuCard(
          icon: Icons.card_giftcard_outlined,
          title: 'Refer friends',
          subtitle: 'Invite friends & earn rewards',
        ),
        _ProfileMenuCard(
          icon: Icons.notifications_active_outlined,
          title: 'Notifications',
          subtitle: 'Push, SMS and email preferences',
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final navigator = Navigator.of(context);
        await AuthStorage.instance.clearPin();
        await AuthStorage.instance.clearCurrentUser();
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false,
        );
      },
      icon: const Icon(Icons.logout_rounded),
      label: const Text(
        'Log out',
        style: TextStyle(fontWeight: FontWeight.w600),
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

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
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
