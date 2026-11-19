import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/migration_service.dart';
import '../widgets/app_logo.dart';
import 'login_page.dart';
import 'main_navigation.dart';
import 'onboarding_page.dart';

const _kSkipLogin = 's_skip_login';

/// Root widget that shows splash then transitions to Login/MainNavigation/Onboarding.
/// No Navigator usage — just swaps child widgets to avoid GlobalKey conflicts.
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

enum _Screen { splash, onboarding, login, home }

class _SplashWrapperState extends State<SplashWrapper> {
  _Screen _screen = _Screen.splash;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final needsOnboarding = await shouldShowOnboarding();

    // Wait minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    if (needsOnboarding) {
      setState(() => _screen = _Screen.onboarding);
      return;
    }

    await _decideAfterOnboarding();
  }

  Future<void> _decideAfterOnboarding() async {
    if (AuthService.isLoggedIn) {
      // Already logged in — run migration if needed, then go home
      await MigrationService.migrateIfNeeded();
      if (mounted) setState(() => _screen = _Screen.home);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getBool(_kSkipLogin) ?? false;
    if (skipped) {
      if (mounted) setState(() => _screen = _Screen.home);
    } else {
      if (mounted) setState(() => _screen = _Screen.login);
    }
  }

  void _onOnboardingComplete() {
    _decideAfterOnboarding();
  }

  void _onLoginSuccess() {
    setState(() => _screen = _Screen.home);
  }

  Future<void> _onSkipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSkipLogin, true);
    if (mounted) setState(() => _screen = _Screen.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      child: switch (_screen) {
        _Screen.splash => const _SplashContent(key: ValueKey('splash')),
        _Screen.onboarding => OnboardingPage(
            key: const ValueKey('onboarding'),
            onComplete: _onOnboardingComplete,
          ),
        _Screen.login => LoginPage(
            key: const ValueKey('login'),
            onLoginSuccess: _onLoginSuccess,
            onSkip: _onSkipLogin,
          ),
        _Screen.home => const MainNavigation(key: ValueKey('home')),
      },
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
    'splash.tip_1',
    'splash.tip_2',
    'splash.tip_3',
    'splash.tip_4',
    'splash.tip_5',
    'splash.tip_6',
    'splash.tip_7',
    'splash.tip_8',
    'splash.tip_9',
    'splash.tip_10',
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
    // Reduced motion: show the end state right away.
    final still = MediaQuery.disableAnimationsOf(context);
    double v(Animation<double> a) => still ? 1 : a.value;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: v(_logoOpacity),
                  child: Transform.scale(
                    scale: v(_logoScale),
                    child: const AppLogo(size: 88),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: v(_textOpacity),
                  child: Text(
                    'Faktura',
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: v(_textOpacity),
                  child: Text(
                    tr('about.subtitle'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 48),
                Opacity(
                  opacity: v(_tipOpacity),
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
                            tr(_tip),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurface),
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
