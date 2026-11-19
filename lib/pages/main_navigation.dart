import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import 'dashboard_page.dart';
import 'faktur_page.dart';
import 'history_page.dart';
import 'reminder_page.dart';
import 'settings_page.dart';
import 'struk_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Switch tab from a page inside MainNavigation (e.g. dashboard banner).
  static void goToTab(BuildContext context, int index) => context
      .findAncestorStateOfType<_MainNavigationState>()
      ?._onNavTap(index);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _dueCount = 0;

  static const _pages = [
    DashboardPage(),
    HistoryPage(),
    ReminderPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDueCount();
  }

  Future<void> _loadDueCount() async {
    final upcoming = await ReminderService.getUpcoming();
    if (mounted) {
      setState(() {
        _dueCount = upcoming.where((r) => r.isDue || r.isOverdue).length;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == 0 || index == 2) _loadDueCount();
  }

  void _showCreateSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('create.title'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _CreateOption(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoice',
                      subtitle: tr('create.invoice_sub'),
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FakturPage()));
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CreateOption(
                      icon: Icons.receipt_outlined,
                      label: 'Struk',
                      subtitle: tr('create.receipt_sub'),
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const StrukPage()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        switchInCurve: Easing.emphasizedDecelerate,
        switchOutCurve: Easing.emphasizedAccelerate,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            // ~8px rise on a phone-height page.
            position: Tween(begin: const Offset(0, 0.01), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        dueCount: _dueCount,
        onTap: _onNavTap,
        onCreateTap: _showCreateSheet,
        primary: theme.colorScheme.primary,
        muted: theme.colorScheme.onSurface.withValues(alpha: 0.32),
        bgColor: isDark ? const Color(0xFF0F1117) : Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create sheet option card
// ─────────────────────────────────────────────────────────────────────────────

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation with center create button
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int dueCount;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;
  final Color primary;
  final Color muted;
  final Color bgColor;

  const _BottomNav({
    required this.currentIndex,
    required this.dueCount,
    required this.onTap,
    required this.onCreateTap,
    required this.primary,
    required this.muted,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.space_dashboard_outlined,
        activeIcon: Icons.space_dashboard_rounded,
        label: tr('nav.dashboard'),
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: tr('nav.history'),
      ),
      _NavItem(
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: tr('nav.notifications'),
        badge: dueCount > 0 ? dueCount : null,
      ),
      _NavItem(
        icon: Icons.tune_rounded,
        activeIcon: Icons.tune_rounded,
        label: tr('nav.settings'),
      ),
    ];

    const fabSize = 56.0;
    const navHeight = 60.0;
    const fabOverlap = 22.0; // seberapa jauh FAB keluar ke atas
    const gapWidth = 6.0; // gap antara FAB ring dan nav bar

    return SizedBox(
      height: navHeight + fabOverlap + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: bgColor,
              height: navHeight + MediaQuery.of(context).padding.bottom,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                children: [
                  // Left 2 tabs
                  ..._buildTiles(items, 0, 2),
                  // Space for center button
                  SizedBox(width: fabSize + gapWidth * 2 + 12),
                  // Right 2 tabs
                  ..._buildTiles(items, 2, 4),
                ],
              ),
            ),
          ),
          // Center FAB — positioned to float above
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: fabSize + gapWidth * 2,
                height: fabSize + gapWidth * 2,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: onCreateTap,
                    child: Container(
                      width: fabSize,
                      height: fabSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary,
                            primary.withValues(alpha: 0.75),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTiles(List<_NavItem> items, int from, int to) {
    return List.generate(to - from, (i) {
      final idx = from + i;
      return Expanded(
        child: _NavTile(
          item: items[idx],
          isActive: idx == currentIndex,
          primary: primary,
          muted: muted,
          bgColor: bgColor,
          onTap: () => onTap(idx),
        ),
      );
    });
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color primary;
  final Color muted;
  final Color bgColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.primary,
    required this.muted,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? primary : muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dot indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
          ),
          // Icon + badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 22,
                color: color,
              ),
              if (item.badge != null)
                Positioned(
                  right: -5,
                  top: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.errorFor(Theme.of(context).brightness),
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
