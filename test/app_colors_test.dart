import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/main.dart';

void main() {
  group('AppColors', () {
    test('brand colors are defined', () {
      expect(AppColors.invoiceBlue, const Color(0xFF2563EB));
      expect(AppColors.strukGreen, const Color(0xFF059669));
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
      // Soft variants should have higher luminance (lighter)
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
}
