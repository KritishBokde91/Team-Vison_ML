import 'package:civic_sense/screens/home_screen.dart';
import 'package:civic_sense/screens/profile_screen.dart';
import 'package:civic_sense/screens/report_history_screen.dart';
import 'package:civic_sense/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen>
    with TickerProviderStateMixin {
  // -----------------------------------------------------------------------
  // 1. Screens
  // -----------------------------------------------------------------------
  final List<Widget> _screens = const [
    HomeScreen(),
    ReportScreen(),
    ReportHistoryScreen(),
    ProfileScreen(),
  ];

  // -----------------------------------------------------------------------
  // 2. Navigation state
  // -----------------------------------------------------------------------
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // 3. UI
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (i) => setState(() => _currentIndex = i),
      ),
      bottomNavigationBar: _SolidBottomBar(
        currentIndex: _currentIndex,
        primaryColor: primary,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. SOLID MODERN BOTTOM BAR
// ---------------------------------------------------------------------------
class _SolidBottomBar extends StatelessWidget {
  final int currentIndex;
  final Color primaryColor;
  final ValueChanged<int> onTap;

  const _SolidBottomBar({
    required this.currentIndex,
    required this.primaryColor,
    required this.onTap,
  });

  static const List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/report.svg',
    'assets/icons/history.svg',
    'assets/icons/profile.svg',
  ];

  static const List<String> _labels = [
    'Home',
    'Report',
    'History',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (i) {
              final bool selected = i == currentIndex;
              return _NavItem(
                iconPath: _icons[i],
                label: _labels[i],
                selected: selected,
                primaryColor: primaryColor,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. NAV ITEM WITH SMOOTH ANIMATIONS
// ---------------------------------------------------------------------------
class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
        Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            AnimatedScale(
              scale: selected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 260),
              child: SvgPicture.asset(
                iconPath,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  selected ? primaryColor : inactiveColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Animated Label
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? primaryColor : inactiveColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}