import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_language.dart';
import '../../app_localizations.dart';
import '../../constants.dart';
import '../../components/combined_card_widget.dart';
import '../../models/account.dart';
import '../../models/branch.dart';
import '../../models/catalog.dart';
import '../../models/news.dart';
import '../../components/branch_picker_sheet.dart';
import '../../services/auth_storage.dart';
import '../../services/branch_state.dart';
import '../../services/catalog_repository.dart';
import '../../services/news_service.dart';
import '../../entry_point.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/product_details_screen.dart';
import '../cashback/cashback_screen.dart';
import '../notifications/notifications_screen.dart';

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
    final double scrollBottomPadding =
        navAwareBottomPadding(context, extra: 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🔹 Background + scrollable content
          Container(
            color: const Color(0xFFF3F5F9),
            child: SafeArea(
              top: true,
              bottom: false, // we'll handle bottom manually
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  defaultPadding,
                  12,
                  defaultPadding,
                  scrollBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: _panelDecoration(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HomeHeader(),
                          const SizedBox(height: 24),
                          TextField(
                            decoration: _buildSearchDecoration(context),
                          ),
                          const SizedBox(height: 18),
                          const _CheesecakePromoBanner(),
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
                    InkWell(
                      onTap: () {
                        final handled = EntryPoint.selectTab(context, 1);
                        if (!handled) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CatalogScreen(),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _OffersCarousel(),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  final BranchState _branchState = BranchState.instance;
  late Branch _activeBranch;

  late final AnimationController _notifController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    lowerBound: 0.0,
    upperBound: 0.1,
  );

  @override
  void initState() {
    super.initState();
    _activeBranch = _branchState.activeBranch;
    _branchState.addListener(_handleBranchChange);
  }

  void _handleBranchChange() {
    final branch = _branchState.activeBranch;
    if (!mounted || branch.id == _activeBranch.id) return;
    setState(() => _activeBranch = branch);
  }

  @override
  void dispose() {
    _branchState.removeListener(_handleBranchChange);
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
                    leading: _LocaleFlag(
                      locale: locale,
                      width: 36,
                      height: 24,
                      highlight: isActive,
                    ),
                    title: Text(
                      l10n.languageLabel(locale),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
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

  Future<void> _openBranchPicker() async {
    await showBranchPickerSheet(context);
  }

  Future<void> _showNotifications() async {
    await _notifController.forward(from: 0);
    await _notifController.reverse();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openBranchPicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _activeBranch.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _LanguageButton(
          locale: currentLocale,
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
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
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
          child: Icon(icon, color: titleColor),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.locale,
    required this.onTap,
  });

  final AppLocale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: titleColor,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              _LocaleFlag(
                locale: locale,
                width: 32,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(locale.shortLabel, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleFlag extends StatelessWidget {
  const _LocaleFlag({
    required this.locale,
    this.width = 24,
    this.height = 16,
    this.highlight = false,
  });

  final AppLocale locale;
  final double width;
  final double height;
  final bool highlight;

  String get _assetName {
    switch (locale) {
      case AppLocale.ru:
        return 'assets/icons/flag_ru.svg';
      case AppLocale.uz:
        return 'assets/icons/flag_uz.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(height * 0.6);
    final decoration = BoxDecoration(
      color:
          highlight ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: borderRadius,
      border: Border.all(
        color: highlight
            ? primaryColor.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.08),
        width: highlight ? 1.4 : 1,
      ),
      boxShadow: highlight
          ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );

    return Container(
      padding: EdgeInsets.all(highlight ? 3 : 2),
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height * 0.35),
        child: SvgPicture.asset(
          _assetName,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CheesecakePromoBanner extends StatefulWidget {
  const _CheesecakePromoBanner();

  @override
  State<_CheesecakePromoBanner> createState() => _CheesecakePromoBannerState();
}

class _CheesecakePromoBannerState extends State<_CheesecakePromoBanner> {
  final NewsService _newsService = NewsService();
  NewsItem? _news;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _newsService.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    try {
      final featured = await _newsService.fetchFeaturedNews();
      if (!mounted) return;
      setState(() => _news = featured);
    } catch (_) {
      if (!mounted) return;
      setState(() => _news = null);
    }
  }

  void _showQrSheet(BuildContext context) {
    final code = 'SARD-CHEESE-${DateTime.now().millisecondsSinceEpoch}';
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _CheesecakeQrSheet(code: code),
    );
  }

  void _showNewsDetails(NewsItem news) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                news.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                  height: 1.4,
                ),
              ),
              if (news.startsAt != null || news.endsAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formatNewsPeriod(news),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bodyTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_news == null) {
      return _StaticCheesecakeBanner(onCta: () => _showQrSheet(context));
    }
    return _NewsBanner(
      news: _news!,
      onDetails: () => _showNewsDetails(_news!),
    );
  }

  String _formatNewsPeriod(NewsItem news) {
    String format(DateTime? date) {
      if (date == null) return '—';
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    }

    final start = format(news.startsAt);
    final end = format(news.endsAt);
    return '$start • $end';
  }
}

class _StaticCheesecakeBanner extends StatelessWidget {
  const _StaticCheesecakeBanner({required this.onCta});

  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEF4FB),
            Color(0xFFF9E8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB678E6).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cheesecakeBannerTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.cheesecakeBannerSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B6375),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCta,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.cheesecakeBannerButton,
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3350465F),
                  blurRadius: 24,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/cheesecake_banner.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsBanner extends StatelessWidget {
  const _NewsBanner({required this.news, required this.onDetails});

  final NewsItem news;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0F9FF),
            Color(0xFFE4F2FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  news.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  news.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B6375),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDetails,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.newsBannerButton),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3350465F),
                  blurRadius: 24,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: news.imageUrl != null
                  ? Image.network(
                      news.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/cheesecake_banner.jpg',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/cheesecake_banner.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheesecakeQrSheet extends StatelessWidget {
  const _CheesecakeQrSheet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            l10n.cheesecakeSheetTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE6E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: QrImageView(
                data: code,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            code,
            style: theme.textTheme.titleSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.cheesecakeSheetDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B6375),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersCarousel extends StatefulWidget {
  const _OffersCarousel();

  @override
  State<_OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<_OffersCarousel> {
  static const int _maxOffers = 6;

  final CatalogRepository _catalogRepository = CatalogRepository.instance;
  final BranchState _branchState = BranchState.instance;

  late Branch _activeBranch;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  List<_OfferEntry> _offers = const [];
  bool _isLoading = true;
  String? _errorMessage;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeBranch = _branchState.activeBranch;
    _branchState.addListener(_handleBranchChange);
    _applyCachedOffers();
    _loadOffers();
  }

  @override
  void dispose() {
    _branchState.removeListener(_handleBranchChange);
    _pageController.dispose();
    super.dispose();
  }

  void _handleBranchChange() {
    final branch = _branchState.activeBranch;
    if (!mounted || branch.id == _activeBranch.id) return;
    setState(() {
      _activeBranch = branch;
    });
    _applyCachedOffers();
    _loadOffers();
  }

  Future<void> _applyCachedOffers() async {
    final cached = await _catalogRepository.getCachedCatalog();
    if (!mounted || cached == null) return;
    final offers = _extractOffers(cached);
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadOffers({bool forceRefresh = false}) async {
    setState(() {
      if (_offers.isEmpty || forceRefresh) {
        _isLoading = true;
      }
      _errorMessage = null;
    });
    try {
      final payload = await _catalogRepository.loadCatalog(
        forceRefresh: forceRefresh,
      );
      final offers = _extractOffers(payload);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<_OfferEntry> _extractOffers(CatalogPayload payload) {
    final offers = <_OfferEntry>[];
    for (final category in payload.categories) {
      for (final item in category.items) {
        final price = _priceForActiveBranch(item);
        if (price == null || price.disabled) continue;
        offers.add(
          _OfferEntry(category: category, item: item, price: price),
        );
        if (offers.length >= _maxOffers) break;
      }
      if (offers.length >= _maxOffers) break;
    }
    return offers;
  }

  CatalogPrice? _priceForActiveBranch(CatalogItem item) {
    final storeId = _activeBranch.storeId;
    if (storeId == null) return null;
    for (final price in item.prices) {
      if (price.storeId == storeId) return price;
    }
    return null;
  }

  String _formatPrice(double value, bool isRu) {
    final intValue = value.round();
    final reversed = intValue.toString().split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(reversed[i]);
    }
    final formatted = buffer.toString().split('').reversed.join();
    final suffix = isRu ? 'сум' : 'soʻm';
    return '$formatted $suffix';
  }

  void _openDetails(_OfferEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogProductDetailsScreen(
          category: entry.category,
          initialItem: entry.item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRu = l10n.locale == AppLocale.ru;

    if (_isLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
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
        child: const CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _OfferError(
        message: l10n.catalogLoadError,
        details: _errorMessage!,
        onRetry: () => _loadOffers(forceRefresh: true),
      );
    }

    if (_offers.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          l10n.catalogEmpty,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: bodyTextColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _offers.length,
            padEnds: false,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final entry = _offers[index];
              final padding = index == _offers.length - 1 ? 0.0 : 12.0;
              return Padding(
                padding: EdgeInsets.only(right: padding, bottom: 12.0),
                child: _OfferCard(
                  entry: entry,
                  price: _formatPrice(entry.price.price, isRu),
                  onTap: () => _openDetails(entry),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _offers.length,
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

class _OfferEntry {
  const _OfferEntry({
    required this.category,
    required this.item,
    required this.price,
  });

  final CatalogCategory category;
  final CatalogItem item;
  final CatalogPrice price;
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.entry,
    required this.price,
    required this.onTap,
  });

  final _OfferEntry entry;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl =
        entry.item.images.isNotEmpty ? entry.item.images.first : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFDFBFF),
                Color(0xFFF4F3FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D6BE0).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _OfferImage(imageUrl: imageUrl),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1E2233),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bodyTextColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1B1B1B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferError extends StatelessWidget {
  const _OfferError({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: Text(
              AppLocalizations.of(context).catalogRetry,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferImage extends StatelessWidget {
  const _OfferImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _OfferImagePlaceholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _OfferImagePlaceholder(isLoading: true);
                },
              )
            : const _OfferImagePlaceholder(),
      ),
    );
  }
}

class _OfferImagePlaceholder extends StatelessWidget {
  const _OfferImagePlaceholder({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F4FB),
      alignment: Alignment.center,
      child: Icon(
        isLoading
            ? Icons.hourglass_empty_rounded
            : Icons.image_not_supported_outlined,
        color: bodyTextColor.withValues(alpha: 0.4),
      ),
    );
  }
}

class _LoyaltyStats extends StatefulWidget {
  const _LoyaltyStats();

  @override
  State<_LoyaltyStats> createState() => _LoyaltyStatsState();
}

class _LoyaltyStatsState extends State<_LoyaltyStats> {
  static const int _cashbackThreshold = 30000;
  final AuthStorage _storage = AuthStorage.instance;
  Account? _account;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final account = await _storage.getCurrentAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _isLoading = false;
    });
  }

  Future<void> _openCashback(Account account) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CashbackScreen(
          account: account,
          threshold: _cashbackThreshold,
          initialBalance:
              account.loyalty?.currentPoints ?? account.cashbackBalance,
          initialEntries: account.cashbackHistory,
          initialLoyalty: account.loyalty,
        ),
      ),
    );
    if (!mounted) return;
    _loadAccount();
  }

  String _formatCurrency(double value, bool isRu) {
    final formatted = _formatPoints(value);
    final suffix = isRu ? 'сум' : 'soʻm';
    return '$formatted $suffix';
  }

  String _formatPoints(double value) {
    final text =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    final reversed = text.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRu = l10n.locale == AppLocale.ru;
    final loyalty = _account?.loyalty;
    final balanceValue = loyalty?.currentPoints ?? _account?.cashbackBalance;
    final balanceLabel = _isLoading
        ? '—'
        : balanceValue != null
            ? _formatCurrency(balanceValue, isRu)
            : '—';
    final helper = _account == null
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
      onTap: _account == null ? null : () => _openCashback(_account!),
    );
  }
}
