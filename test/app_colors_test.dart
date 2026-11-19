import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faktur_gen/main.dart';

// WCAG 2.x contrast ratio, same formula as antislop contrast-check.py.
double _contrast(Color a, Color b) {
  double lin(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) => 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _white = Color(0xFFFFFFFF);
const _darkBg = Color(0xFF0F1117);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppColors', () {
    test('brand colors are defined', () {
      expect(AppColors.invoiceBlue, const Color(0xFF2563EB));
      expect(AppColors.strukGreen, const Color(0xFF047857));
      expect(AppColors.invoiceBlueSoft, const Color(0xFF60A5FA));
      expect(AppColors.strukGreenSoft, const Color(0xFF34D399));
    });

    test('errorFor returns correct color per brightness', () {
      expect(AppColors.errorFor(Brightness.light), AppColors.error);
      expect(AppColors.errorFor(Brightness.dark), AppColors.errorSoft);
    });

    test('warningFor returns correct color per brightness', () {
      expect(AppColors.warningFor(Brightness.light), AppColors.warning);
      expect(AppColors.warningFor(Brightness.dark), AppColors.warningSoft);
    });

    test('successFor returns correct color per brightness', () {
      expect(AppColors.successFor(Brightness.light), AppColors.success);
      expect(AppColors.successFor(Brightness.dark), AppColors.successSoft);
    });

    test('soft colors are lighter than base colors', () {
      expect(
        HSLColor.fromColor(AppColors.errorSoft).lightness,
        greaterThan(HSLColor.fromColor(AppColors.error).lightness),
      );
      expect(
        HSLColor.fromColor(AppColors.warningSoft).lightness,
        greaterThan(HSLColor.fromColor(AppColors.warning).lightness),
      );
    });
  });

  group('WCAG AA contrast (4.5:1)', () {
    test('status text on light background', () {
      for (final c in [AppColors.error, AppColors.warning, AppColors.success]) {
        expect(_contrast(c, _white), greaterThanOrEqualTo(4.5), reason: '$c');
      }
    });

    test('status text on dark background', () {
      for (final c in [
        AppColors.errorSoft,
        AppColors.warningSoft,
        AppColors.successSoft,
      ]) {
        expect(_contrast(c, _darkBg), greaterThanOrEqualTo(4.5), reason: '$c');
      }
    });

    // testWidgets, not test: MyApp.light/dark build Inter text styles, and the
    // font load failure would otherwise leak into the next test.
    testWidgets('button label on primary, both themes and struk green', (
      tester,
    ) async {
      final light = MyApp.light().colorScheme;
      final dark = MyApp.dark().colorScheme;
      expect(_contrast(light.onPrimary, light.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.onPrimary, dark.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(light.onPrimary, AppColors.strukGreen), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.onPrimary, AppColors.strukGreenSoft), greaterThanOrEqualTo(4.5));
    });
  });
}
