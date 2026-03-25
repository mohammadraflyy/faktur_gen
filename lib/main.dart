import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/home_page.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await ThemeService.load();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await ReminderService.rescheduleNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return MaterialApp(
          title: 'Faktur Gen',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _light(),
          darkTheme: _dark(),
          home: const HomePage(),
        );
      },
    );
  }

  static ThemeData _light() {
    final base = ThemeData.light(useMaterial3: true);
    final txt = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        secondary: const Color(0xFF059669),
        surface: const Color(0xFFFAFBFC),
        onSurface: const Color(0xFF111827),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      textTheme: txt,
      primaryTextTheme: txt,
      inputDecorationTheme: _input(false),
      cardTheme: _card(false),
      appBarTheme: _appBar(false),
      elevatedButtonTheme: _elevatedBtn(),
      textButtonTheme: _textBtn(),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 0.5,
        space: 16,
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

  static ThemeData _dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final txt = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF60A5FA),
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
      dividerTheme: const DividerThemeData(
        color: Color(0xFF252836),
        thickness: 0.5,
        space: 16,
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
        backgroundColor: dark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FB),
        foregroundColor: dark ? Colors.white : const Color(0xFF111827),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : const Color(0xFF111827),
        ),
        iconTheme: IconThemeData(
          color: dark ? Colors.white : const Color(0xFF374151),
          size: 22,
        ),
      );

  static InputDecorationTheme _input(bool dark) => InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1F2233) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF2D3044) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF2D3044) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF60A5FA) : _primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: dark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: dark ? const Color(0xFF60A5FA) : _primary,
        ),
      );

  static ElevatedButtonThemeData _elevatedBtn() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData _textBtn() => TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      );
}
