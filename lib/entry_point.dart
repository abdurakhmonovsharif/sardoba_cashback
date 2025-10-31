import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/locations/locations_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/qr/qr_screen.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {"icon": Icons.home_rounded, "label": "Home"},
    {"icon": Icons.grid_view_rounded, "label": "Catalog"},
    {"icon": Icons.location_on_outlined, "label": "Locations"},
    {"icon": Icons.person_outline_rounded, "label": "Profile"},
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    CatalogScreen(),
    LocationsScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: _screens[_selectedIndex],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.translate(
          offset: const Offset(0, -12),
          child: _AnimatedQrButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScreen()),
              );
            },
          ),
        ),
        bottomNavigationBar: _FloatingNavBar(
          navItems: _navItems,
          selectedIndex: _selectedIndex,
          onItemSelected: _onTabSelected,
        ),
      ),
    );
  }
}

class _AnimatedQrButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedQrButton({required this.onPressed});

  @override
  State<_AnimatedQrButton> createState() => _AnimatedQrButtonState();
}

class _AnimatedQrButtonState extends State<_AnimatedQrButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          final scaleValue = 1 + _scale.value;
          return Transform.scale(
            scale: scaleValue,
            child: child,
          );
        },
        child: Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0DD277), Color(0xFF089D57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.qr_code_rounded,
              size: 30,
              color: primaryColor.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final List<Map<String, dynamic>> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _FloatingNavBar({
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(defaultPadding, 0, defaultPadding, 16),
      child: SizedBox(
        height: 78,
        child: ClipPath(
          clipper: _ConcaveClipper(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(navItems.length + 1, (index) {
                if (index == 2) {
                  return const SizedBox(width: 84);
                }
                final navIndex = index > 2 ? index - 1 : index;
                final item = navItems[navIndex];
                final isActive = navIndex == selectedIndex;
                return _NavItem(
                  icon: item["icon"] as IconData,
                  isActive: isActive,
                  onTap: () => onItemSelected(navIndex),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor =
        isActive ? const Color(0xFF5D4221) : bodyTextColor.withValues(alpha: 0.4);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: isActive ? 1 : 0.9,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFF4EFE6) : Colors.transparent,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0x805D4221).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

class _ConcaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    const cornerRadius =34.0;
    const dipWidth = 110.0;
    const dipDepth = 34.0;
    final dipStart = (width - dipWidth) / 2;
    final dipEnd = dipStart + dipWidth;

    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(dipStart, 0);
    path.cubicTo(
      dipStart + dipWidth * 0.18,
      0,
      dipStart + dipWidth * 0.25,
      dipDepth,
      width / 2,
      dipDepth + 6,
    );
    path.cubicTo(
      dipEnd - dipWidth * 0.25,
      dipDepth,
      dipEnd - dipWidth * 0.18,
      0,
      dipEnd,
      0,
    );
    path.lineTo(width - cornerRadius, 0);
    path.quadraticBezierTo(width, 0, width, cornerRadius);
    path.lineTo(width, height - cornerRadius);
    path.quadraticBezierTo(width, height, width - cornerRadius, height);
    path.lineTo(cornerRadius, height);
    path.quadraticBezierTo(0, height, 0, height - cornerRadius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
