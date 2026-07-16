import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/constants/filter_presets.dart';

void main() {
  group('FilterPreset', () {
    test('original preset matches neutral adjustments', () {
      final original = filterPresets.firstWhere((preset) => preset.id == 'original');

      expect(original.matches(brightness: 1, contrast: 1, saturation: 1), true);
    });

    test('matches tolerates floating point noise', () {
      final vivid = filterPresets.firstWhere((preset) => preset.id == 'vivid');

      expect(vivid.matches(brightness: 1 + 1e-9, contrast: 1.1 - 1e-9, saturation: 1.3), true);
    });

    test('does not match different adjustments', () {
      final mono = filterPresets.firstWhere((preset) => preset.id == 'mono');

      expect(mono.matches(brightness: 1, contrast: 1, saturation: 0.5), false);
    });

    test('preset ids are unique', () {
      final ids = filterPresets.map((preset) => preset.id).toSet();

      expect(ids.length, filterPresets.length);
    });

    test('every preset has a distinct parameter combination', () {
      for (final preset in filterPresets) {
        final matching = filterPresets.where(
          (other) =>
              other.matches(brightness: preset.brightness, contrast: preset.contrast, saturation: preset.saturation),
        );

        expect(matching.length, 1, reason: 'preset ${preset.id} must not collide with another preset');
      }
    });
  });
}
