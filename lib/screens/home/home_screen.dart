import 'package:flutter/material.dart';

import '../../app_language.dart';
import '../../app_localizations.dart';
import '../../constants.dart';

const List<String> _offerImageAssets = [
  "https://cdn-kz3.foodpicasso.com/assets/2023/11/07/6ac3aad7f099694d41fa173689653e39---jpg_1100_1e6e0_convert.webp",
  "https://cdn-kz3.foodpicasso.com/assets/2024/03/24/4524dd6957ef3977b2aff12d10503ea6---jpg_1100_1e6e0_convert.webp",
  "https://cdn-kz3.foodpicasso.com/assets/2023/11/07/a72a63b03a4c3130b70be4844ad40807---jpg_1100_1e6e0_convert.webp",
  "https://cdn-kz3.foodpicasso.com/assets/2024/03/24/55156360bcd21c6e1f4abe2e2ed076ac---jpg_1100_1e6e0_convert.webp",
  "https://cdn-kz3.foodpicasso.com/assets/2024/03/24/312fa2cb04c24a1f921db760741f9819---jpg_1100_1e6e0_convert.webp"
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  InputDecoration _buildSearchDecoration(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InputDecoration(
      hintText: l10n.searchHint,
      hintStyle: const TextStyle(color: Color(0xFFB0B6C3), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF8D97A8),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            defaultPadding,
            12,
            defaultPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: _panelDecoration(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: 24),
                    TextField(
                      decoration: _buildSearchDecoration(context),
                    ),
                    const SizedBox(height: 20),
                    const _PromoSwiper(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loyaltyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const _LoyaltyStats(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.offersTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: titleColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _offerImageAssets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final imageAsset = _offerImageAssets[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        imageAsset,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 110,
                            height: 110,
                            alignment: Alignment.center,
                            color: const Color(0xFFF3F5F9),
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          alignment: Alignment.center,
                          color: const Color(0xFFF3F5F9),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: bodyTextColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _notifController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    lowerBound: 0.0,
    upperBound: 0.1,
  );

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

  Future<void> _openLanguagePicker() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final current = AppLanguage.instance.locale;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageSheetTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...AppLocale.values.map((locale) {
                  final isActive = locale == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isActive
                          ? primaryColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      child: Text(
                        locale.shortLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(l10n.languageLabel(locale)),
                    trailing: isActive
                        ? const Icon(Icons.check_rounded, color: primaryColor)
                        : null,
                    onTap: () {
                      AppLanguage.instance.setLocale(locale);
                      Navigator.of(context).pop();
                    },
                  );
                })
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications() async {
    final l10n = AppLocalizations.of(context);
    await _notifController.forward(from: 0);
    await _notifController.reverse();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notificationsTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _NotificationCard(
                icon: Icons.cake_outlined,
                title: l10n.birthdayOfferTitle,
                message: l10n.birthdayOfferBody,
                accent: primaryColor,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentLocale = AppLanguage.instance.locale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changeBranch,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Sardoba',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.changeBranchSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderActionButton(
          icon: Icons.language_rounded,
          label: currentLocale.shortLabel,
          onTap: _openLanguagePicker,
        ),
        const SizedBox(width: 12),
        AnimatedBuilder(
          animation: _notifController,
          builder: (context, child) {
            final scale = 1 + _notifController.value;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: _HeaderActionButton(
            icon: Icons.notifications_none_rounded,
            onTap: _showNotifications,
          ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.label,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLabel = label != null && label!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: hasLabel
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: titleColor),
              if (hasLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoSwiper extends StatefulWidget {
  const _PromoSwiper();

  @override
  State<_PromoSwiper> createState() => _PromoSwiperState();
}

class _PromoSwiperState extends State<_PromoSwiper> {
  static const double _itemSpacing = 12;

  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _offerImageAssets.length,
            padEnds: false,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final imageAsset = _offerImageAssets[index];
              final padding =
                  index == _offerImageAssets.length - 1 ? 0.0 : _itemSpacing;
              return Padding(
                padding: EdgeInsets.only(right: padding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    imageAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF3F5F9),
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF3F5F9),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: bodyTextColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _offerImageAssets.length,
            (index) {
              final isActive = index == _activeIndex;
              return AnimatedContainer(
                duration: kDefaultDuration,
                curve: Curves.easeOut,
                width: isActive ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyStats extends StatelessWidget {
  const _LoyaltyStats();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.cashbackTitle,
            value: '48 500 soʻm',
            helper: l10n.cashbackHelper,
            accentColor: primaryColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium_rounded,
            title: l10n.membershipTitle,
            value: 'Silver',
            helper: l10n.membershipHelper,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.helper,
    required this.accentColor,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String value;
  final String helper;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: theme.textTheme.bodySmall?.copyWith(color: bodyTextColor),
          ),
        ],
      ),
    );
  }
}
