import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/asset_edit.model.dart';
import 'package:immich_mobile/utils/editor.utils.dart';
import 'package:openapi/api.dart' show MirrorAxis, MirrorParameters, RotateParameters;

List<AssetEdit> normalizedToEdits(NormalizedTransform transform) {
  List<AssetEdit> edits = [];

  if (transform.mirrorHorizontal) {
    edits.add(MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)));
  }

  if (transform.mirrorVertical) {
    edits.add(MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)));
  }

  if (transform.rotation != 0) {
    edits.add(RotateEdit(RotateParameters(angle: transform.rotation)));
  }

  return edits;
}

bool compareEditAffines(List<AssetEdit> editsA, List<AssetEdit> editsB) {
  final normA = buildAffineFromEdits(editsA);
  final normB = buildAffineFromEdits(editsB);

  return ((normA.a - normB.a).abs() < 0.0001 &&
      (normA.b - normB.b).abs() < 0.0001 &&
      (normA.c - normB.c).abs() < 0.0001 &&
      (normA.d - normB.d).abs() < 0.0001);
}

void main() {
  group('normalizeEdits', () {
    test('should handle no edits', () {
      final edits = <AssetEdit>[];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle a single 90° rotation', () {
      final edits = <AssetEdit>[RotateEdit(RotateParameters(angle: 90))];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle a single 180° rotation', () {
      final edits = <AssetEdit>[RotateEdit(RotateParameters(angle: 180))];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle a single 270° rotation', () {
      final edits = <AssetEdit>[RotateEdit(RotateParameters(angle: 270))];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle a single horizontal mirror', () {
      final edits = <AssetEdit>[MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal))];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle a single vertical mirror', () {
      final edits = <AssetEdit>[MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical))];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 90° rotation + horizontal mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 90)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 90° rotation + vertical mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 90)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 90° rotation + both mirrors', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 90)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 180° rotation + horizontal mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 180)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 180° rotation + vertical mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 180)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 180° rotation + both mirrors', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 180)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 270° rotation + horizontal mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 270)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 270° rotation + vertical mirror', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 270)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle 270° rotation + both mirrors', () {
      final edits = <AssetEdit>[
        RotateEdit(RotateParameters(angle: 270)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle horizontal mirror + 90° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        RotateEdit(RotateParameters(angle: 90)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle horizontal mirror + 180° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        RotateEdit(RotateParameters(angle: 180)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle horizontal mirror + 270° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        RotateEdit(RotateParameters(angle: 270)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle vertical mirror + 90° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 90)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle vertical mirror + 180° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 180)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle vertical mirror + 270° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 270)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle both mirrors + 90° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 90)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle both mirrors + 180° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 180)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });

    test('should handle both mirrors + 270° rotation', () {
      final edits = <AssetEdit>[
        MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)),
        MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)),
        RotateEdit(RotateParameters(angle: 270)),
      ];

      final result = normalizeTransformEdits(edits);
      final normalizedEdits = normalizedToEdits(result);

      expect(compareEditAffines(normalizedEdits, edits), true);
    });
  });

  group('buildAdjustColorMatrix', () {
    // Applies the 4x5 color matrix to an rgb pixel (alpha assumed 1)
    List<double> applyMatrix(List<double> m, double r, double g, double b) {
      return [
        m[0] * r + m[1] * g + m[2] * b + m[4],
        m[5] * r + m[6] * g + m[7] * b + m[9],
        m[10] * r + m[11] * g + m[12] * b + m[14],
      ];
    }

    test('neutral values produce the identity matrix', () {
      final matrix = buildAdjustColorMatrix(brightness: 1, contrast: 1, saturation: 1);
      final result = applyMatrix(matrix, 120, 80, 40);

      expect(result[0], closeTo(120, 1e-9));
      expect(result[1], closeTo(80, 1e-9));
      expect(result[2], closeTo(40, 1e-9));
    });

    test('brightness scales channels linearly', () {
      final matrix = buildAdjustColorMatrix(brightness: 1.5, contrast: 1, saturation: 1);
      final result = applyMatrix(matrix, 100, 100, 100);

      expect(result[0], closeTo(150, 1e-9));
      expect(result[1], closeTo(150, 1e-9));
      expect(result[2], closeTo(150, 1e-9));
    });

    test('contrast pivots around mid-grey', () {
      final matrix = buildAdjustColorMatrix(brightness: 1, contrast: 1.5, saturation: 1);

      // out = 1.5 * in - 0.5 * 127.5: light moves up, dark moves down, mid-grey stays
      expect(applyMatrix(matrix, 200, 200, 200)[0], closeTo(236.25, 1e-9));
      expect(applyMatrix(matrix, 50, 50, 50)[0], closeTo(11.25, 1e-9));
      expect(applyMatrix(matrix, 127.5, 127.5, 127.5)[0], closeTo(127.5, 1e-9));
    });

    test('zero saturation converges channels to luminance grey', () {
      final matrix = buildAdjustColorMatrix(brightness: 1, contrast: 1, saturation: 0);
      final result = applyMatrix(matrix, 200, 50, 50);

      expect(result[0], closeTo(result[1], 1e-9));
      expect(result[1], closeTo(result[2], 1e-9));
    });
  });
}
