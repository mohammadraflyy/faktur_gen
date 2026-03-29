import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';
import 'main_navigation.dart';
import 'onboarding_page.dart';

/// Root widget that shows splash then transitions to MainNavigation or Onboarding.
/// No Navigator usage — just swaps child widgets to avoid GlobalKey conflicts.
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;
  bool _needsOnboarding = false;
  bool _checkDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final needsOnboarding = await shouldShowOnboarding();

    // Wait minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2600));

    if (mounted) {
      setState(() {
        _needsOnboarding = needsOnboarding;
        _checkDone = true;
        _showSplash = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showSplash
          ? const _SplashContent(key: ValueKey('splash'))
          : _checkDone && _needsOnboarding
              ? OnboardingPage(
                  key: const ValueKey('onboarding'),
                  onComplete: _onOnboardingComplete,
                )
              : const MainNavigation(key: ValueKey('home')),
    );
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent({super.key});

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _tipOpacity;

  static const _tips = [
    'Atur profil toko di Pengaturan untuk invoice lebih profesional',
    'Tambahkan logo dan tanda tangan untuk branding yang konsisten',
    'Gunakan template untuk mempercepat pembuatan invoice berulang',
    'Atur pengingat layanan agar tidak terlewat jadwal pelanggan',
    'Export data ke CSV untuk pembukuan yang lebih rapi',
    'Simpan kontak pelanggan untuk auto-fill di invoice berikutnya',
    'Gunakan katalog item untuk menambahkan produk dengan cepat',
    'Backup data secara berkala untuk keamanan dokumen Anda',
    'Struk bisa langsung dicetak ke printer thermal 80mm',
    'Aktifkan dark mode untuk kenyamanan mata di malam hari',
  ];

  late final String _tip;

  @override
  void initState() {
    super.initState();
    _tip = _tips[Random().nextInt(_tips.length)];

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.5, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    _tipOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: const AppLogo(size: 88),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    'Faktura',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    'Invoice & Struk Profesional',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Opacity(
                  opacity: _tipOpacity.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tip,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
