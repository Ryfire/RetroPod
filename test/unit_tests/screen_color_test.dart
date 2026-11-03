import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/screen_color.dart';

void main() {
  group('screen_color', () {
    test('theme resolves to no override', () {
      expect(ScreenColor.theme.color, isNull);
    });

    test('swatches resolve through the matching device color', () {
      expect(
        ScreenColor.blue.color,
        ScreenColor.blue.color,
      );
      expect(ScreenColor.blue.color, isNotNull);
      // Distinct swatches must not collapse to the same color.
      expect(
        ScreenColor.blue.color,
        isNot(ScreenColor.yellow.color),
      );
      expect(
        ScreenColor.oledBlack.color,
        isNot(ScreenColor.silver.color),
      );
    });

    test('auto contrast picks dark text on light backgrounds', () {
      expect(
        ScreenColor.autoContrastTextColor(
          ScreenColor.yellow.color!,
        ),
        const Color(0xFF101214),
      );
      expect(
        ScreenColor.autoContrastTextColor(ScreenColor.silver.color!),
        const Color(0xFF101214),
      );
    });

    test('auto contrast picks light text on dark backgrounds', () {
      expect(
        ScreenColor.autoContrastTextColor(
          ScreenColor.oledBlack.color!,
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
