import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/screen_color.dart';

void main() {
  group('screen_color', () {
    test('theme resolves to no override', () {
      expect(ScreenColor.theme.backgroundColor, isNull);
      expect(ScreenColor.theme.fontSwatchColor, isNull);
    });

    test('background swatches use the light gradient end', () {
      expect(ScreenColor.blue.backgroundColor, const Color(0xFF9FD3FF));
    });

    test('font swatches use the darker gradient end', () {
      expect(ScreenColor.blue.fontSwatchColor, const Color(0xFF0F4C9A));
      expect(
        ScreenColor.blue.fontSwatchColor,
        isNot(ScreenColor.blue.backgroundColor),
      );
      // Oled black stays pure black via its solid frame color.
      expect(ScreenColor.oledBlack.fontSwatchColor, CupertinoColors.black);
    });

    test('lime and green font swatches are distinct', () {
      expect(
        ScreenColor.lime.fontSwatchColor,
        isNot(ScreenColor.green.fontSwatchColor),
      );
      // ...while their background swatches were the near-identical pale
      // greens that motivated this split.
      expect(
        ScreenColor.lime.backgroundColor,
        isNot(ScreenColor.green.backgroundColor),
      );
    });

    test('auto contrast picks dark text on light backgrounds', () {
      expect(
        ScreenColor.autoContrastTextColor(
          ScreenColor.yellow.backgroundColor!,
        ),
        const Color(0xFF101214),
      );
      expect(
        ScreenColor.autoContrastTextColor(ScreenColor.silver.backgroundColor!),
        const Color(0xFF101214),
      );
    });

    test('auto contrast picks light text on dark backgrounds', () {
      expect(
        ScreenColor.autoContrastTextColor(
          ScreenColor.oledBlack.fontSwatchColor!,
        ),
        const Color(0xFFE6E7EA),
      );
      expect(
        ScreenColor.autoContrastTextColor(const Color(0xFF121212)),
        const Color(0xFFE6E7EA),
      );
    });

    test('unknown stored names fall back to theme', () {
      expect(ScreenColor.fromName(null), ScreenColor.theme);
      expect(ScreenColor.fromName('corrupted'), ScreenColor.theme);
      expect(ScreenColor.fromName('blue'), ScreenColor.blue);
    });
  });
}
