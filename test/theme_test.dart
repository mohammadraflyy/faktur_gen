import 'package:faktur_gen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // testWidgets, not test: Inter is not bundled, so google_fonts' async load
  // fails; FakeAsync keeps that failure from landing in the next test.
  for (final entry in {'light': MyApp.light, 'dark': MyApp.dark}.entries) {
    group('${entry.key} theme', () {
      testWidgets('text scale uses only 32/22/17/15/13/12', (tester) async {
        final t = entry.value().textTheme;
        expect(t.displaySmall!.fontSize, 32);
        expect(t.headlineSmall!.fontSize, 22);
        expect(t.titleLarge!.fontSize, 22);
        expect(t.titleMedium!.fontSize, 17);
        expect(t.titleSmall!.fontSize, 15);
        expect(t.bodyLarge!.fontSize, 15);
        expect(t.bodyMedium!.fontSize, 15);
        expect(t.bodySmall!.fontSize, 13);
        expect(t.labelLarge!.fontSize, 15);
        expect(t.labelMedium!.fontSize, 12);
        expect(t.labelSmall!.fontSize, 12);
      });

      testWidgets('buttons are at least 48dp tall', (tester) async {
        final theme = entry.value();
        final elevated = theme.elevatedButtonTheme.style!.minimumSize!.resolve(
          {},
        )!;
        final text = theme.textButtonTheme.style!.minimumSize!.resolve({})!;
        expect(elevated.height, greaterThanOrEqualTo(48));
        expect(text.height, greaterThanOrEqualTo(48));
      });

      testWidgets('android pages use the built-in fade-forwards transition', (
        tester,
      ) async {
        expect(
          entry.value().pageTransitionsTheme.builders[TargetPlatform.android],
          isA<FadeForwardsPageTransitionsBuilder>(),
        );
      });
    });
  }

  testWidgets('light theme: white background, borderless filled fields', (
    tester,
  ) async {
    final theme = MyApp.light();
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.inputDecorationTheme.fillColor, const Color(0xFFF3F4F6));
    expect(
      theme.inputDecorationTheme.hintStyle!.color,
      const Color(0xFF4B5563),
    );
    expect(
      theme.inputDecorationTheme.labelStyle!.color,
      const Color(0xFF4B5563),
    );
    expect(
      (theme.inputDecorationTheme.enabledBorder as OutlineInputBorder)
          .borderSide,
      BorderSide.none,
    );
  });

  testWidgets('dark theme background', (tester) async {
    expect(MyApp.dark().scaffoldBackgroundColor, const Color(0xFF0F1117));
  });
}
