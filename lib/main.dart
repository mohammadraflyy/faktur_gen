import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'pages/splash_page.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/billing_service.dart';
import 'services/recurring_invoice_service.dart';
import 'services/subscription_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hanya inisialisasi ringan sebelum runApp
  try {
    await initializeDateFormatting('id_ID', null);
    await ThemeService.load();
    await LocaleService.load();
  } catch (e) {
    debugPrint('[main] Pre-init error (non-fatal): $e');
  }

  // Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    AuthService.init();
    BillingService.init();
  } catch (e) {
    debugPrint('[main] Firebase init error (non-fatal): $e');
  }

  runApp(const MyApp());

  // Inisialisasi berat dijalankan SETELAH runApp agar UI tidak stuck
  try {
    await NotificationService.init();
    // requestPermission tidak perlu blocking — jalankan tapi jangan await lama
    NotificationService.requestPermission().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('[main] Permission request timed out');
        return false;
      },
    );
    await ReminderService.rescheduleNotifications();
    // Auto-backup (silent, won't block UI)
    BackupService.autoBackupIfNeeded().then((did) {
      if (did) debugPrint('[main] Auto-backup completed');
    });
    // Check recurring invoices (Pro only, silent)
    SubscriptionService.isPro().then((isPro) {
      if (isPro) {
        RecurringInvoiceService.checkAndGenerate().then((generated) {
          if (generated.isNotEmpty) {
            debugPrint('[main] Generated ${generated.length} recurring invoices');
          }
        });
      }
    });
  } catch (e) {
    debugPrint('[main] Post-init error (non-fatal): $e');
  }
}

/// Centralized semantic color constants for the app.
/// Use these instead of hard-coding color values in individual pages.
class AppColors {
  AppColors._();

  // Brand colors
  static const invoiceBlue = Color(0xFF2563EB);
  // #059669 was 3.77:1 under white text; #047857 is 5.48:1.
  static const strukGreen = Color(0xFF047857);

  // Light variants (for dark mode)
  static const invoiceBlueSoft = Color(0xFF60A5FA);
  static const strukGreenSoft = Color(0xFF34D399);

  // Status colors (light mode), all >= 4.5:1 on white
  static const error = Color(0xFFB91C1C);
  static const warning = Color(0xFFB45309);

  // Status colors (dark mode — softer to avoid harsh contrast)
  static const errorSoft = Color(0xFFF87171);
  static const warningSoft = Color(0xFFFBBF24);

  // Success (for snackbar, badges)
  static const success = Color(0xFF047857);
  static const successSoft = Color(0xFF34D399);

  /// Get the appropriate error color for the current brightness.
  static Color errorFor(Brightness brightness) =>
      brightness == Brightness.dark ? errorSoft : error;

  /// Get the appropriate warning color for the current brightness.
  static Color warningFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningSoft : warning;

  /// Get the appropriate success color for the current brightness.
  static Color successFor(Brightness brightness) =>
      brightness == Brightness.dark ? successSoft : success;
}

/// Global navigator key for deep navigation from notifications.
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: LocaleService.languageNotifier,
          builder: (context, _, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Faktura',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: light(),
          darkTheme: dark(),
          // Resolved brightness, so ThemeMode.system also gets the right icons.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: child!,
          ),
          home: const SplashWrapper(),
        ),
        );
      },
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final txt = _text(
        base.textTheme, const Color(0xFF111827), const Color(0xFF6B7280));
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        onPrimary: Colors.white,
        secondary: AppColors.strukGreen,
        surface: const Color(0xFFFAFBFC),
        onSurface: const Color(0xFF111827),
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: txt,
      primaryTextTheme: txt,
      inputDecorationTheme: _input(false),
      cardTheme: _card(false),
      appBarTheme: _appBar(false),
      elevatedButtonTheme: _elevatedBtn(),
      textButtonTheme: _textBtn(),
      pageTransitionsTheme: _pageTransitions,
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF0F1F3),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final txt = _text(
        base.textTheme, const Color(0xFFF3F4F6), const Color(0xFF9CA3AF));
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF60A5FA),
        // White on #60A5FA is only 2.5:1.
        onPrimary: const Color(0xFF0F1117),
        secondary: const Color(0xFF34D399),
        surface: const Color(0xFF161822),
        onSurface: const Color(0xFFE5E7EB),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1117),
      textTheme: txt,
      primaryTextTheme: txt,
      inputDecorationTheme: _input(true),
      cardTheme: _card(true),
      appBarTheme: _appBar(true),
      elevatedButtonTheme: _elevatedBtn(),
      textButtonTheme: _textBtn(),
      pageTransitionsTheme: _pageTransitions,
      dividerTheme: const DividerThemeData(
        color: Color(0xFF252836),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1A1D2B),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1D2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // Six sizes only: 32 / 22 / 17 / 15 / 13 / 12. bodyMedium is the default
  // for plain Text, so it stays at body size and primary color.
  static TextTheme _text(TextTheme base, Color strong, Color muted) {
    final t = GoogleFonts.interTextTheme(base).apply(
      bodyColor: strong,
      displayColor: strong,
    );
    TextStyle s(TextStyle? x, double size, FontWeight w) =>
        x!.copyWith(fontSize: size, fontWeight: w, height: 1.3);
    return t.copyWith(
      displaySmall: s(t.displaySmall, 32, FontWeight.w700),
      headlineSmall: s(t.headlineSmall, 22, FontWeight.w700),
      titleLarge: s(t.titleLarge, 22, FontWeight.w700),
      titleMedium: s(t.titleMedium, 17, FontWeight.w600),
      titleSmall: s(t.titleSmall, 15, FontWeight.w600),
      bodyLarge: s(t.bodyLarge, 15, FontWeight.w400),
      bodyMedium: s(t.bodyMedium, 15, FontWeight.w400),
      bodySmall: s(t.bodySmall, 13, FontWeight.w400).copyWith(color: muted),
      labelLarge: s(t.labelLarge, 15, FontWeight.w600),
      labelMedium: s(t.labelMedium, 12, FontWeight.w600),
      labelSmall: s(t.labelSmall, 12, FontWeight.w500),
    );
  }

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static CardThemeData _card(bool dark) => CardThemeData(
        elevation: dark ? 0 : 0,
        color: dark ? const Color(0xFF1A1D2B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: dark ? const Color(0xFF252836) : const Color(0xFFF0F1F3),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      );

  static AppBarTheme _appBar(bool dark) => AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: dark ? const Color(0xFF0F1117) : Colors.white,
        foregroundColor: dark ? Colors.white : const Color(0xFF111827),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : const Color(0xFF111827),
        ),
        iconTheme: IconThemeData(
          color: dark ? Colors.white : const Color(0xFF374151),
          size: 22,
        ),
      );

  static InputDecorationTheme _input(bool dark) {
    final radius = BorderRadius.circular(12);
    final error = dark ? AppColors.errorSoft : AppColors.error;
    return InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1F2233) : const Color(0xFFF3F4F6),
      border:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: dark ? const Color(0xFF60A5FA) : _primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
      ),
      // #6B7280 on #F3F4F6 is 4.39:1, below AA.
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: dark ? const Color(0xFF60A5FA) : _primary,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedBtn() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData _textBtn() => TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
}
