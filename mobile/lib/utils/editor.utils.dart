import 'dart:math';

import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/asset_edit.model.dart';
import 'package:immich_mobile/utils/matrix.utils.dart';
import 'package:openapi/api.dart' hide AssetEditAction;

Rect convertCropParametersToRect(CropParameters parameters, int originalWidth, int originalHeight) {
  return Rect.fromLTWH(
    parameters.x.toDouble() / originalWidth,
    parameters.y.toDouble() / originalHeight,
    parameters.width.toDouble() / originalWidth,
    parameters.height.toDouble() / originalHeight,
  );
}

CropParameters convertRectToCropParameters(Rect rect, int originalWidth, int originalHeight) {
  final x = (rect.left * originalWidth).truncate();
  final y = (rect.top * originalHeight).truncate();
  final width = (rect.width * originalWidth).truncate();
  final height = (rect.height * originalHeight).truncate();

  return CropParameters(
    x: max(x, 0).clamp(0, originalWidth),
    y: max(y, 0).clamp(0, originalHeight),
    width: max(width, 0).clamp(0, originalWidth - x),
    height: max(height, 0).clamp(0, originalHeight - y),
  );
}

AffineMatrix buildAffineFromEdits(List<AssetEdit> edits) {
  return AffineMatrix.compose(
    edits.map<AffineMatrix>((edit) {
      return switch (edit) {
        RotateEdit(:final parameters) => AffineMatrix.rotate(parameters.angle * pi / 180),
        MirrorEdit(:final parameters) =>
          parameters.axis == MirrorAxis.horizontal ? AffineMatrix.flipY() : AffineMatrix.flipX(),
        CropEdit() => AffineMatrix.identity(),
        AdjustEdit() => AffineMatrix.identity(),
      };
    }).toList(),
  );
}

/// Builds a 4x5 color matrix for [ColorFilter.matrix] applying brightness,
/// contrast, and saturation multipliers (1 = neutral), approximating the
/// server-side rendering: brightness/saturation like sharp's modulate and
/// contrast as a linear curve pivoted around mid-grey.
List<double> buildAdjustColorMatrix({
  required double brightness,
  required double contrast,
  required double saturation,
}) {
  // Rec. 709 luminance weights, matching the css saturate() filter used by the web editor
  const lumR = 0.2126;
  const lumG = 0.7152;
  const lumB = 0.0722;

  final sr = (1 - saturation) * lumR;
  final sg = (1 - saturation) * lumG;
  final sb = (1 - saturation) * lumB;

  final scale = brightness * contrast;
  final offset = 255 * (1 - contrast) / 2;

  return [
    (sr + saturation) * scale,
    sg * scale,
    sb * scale,
    0,
    offset,
    sr * scale,
    (sg + saturation) * scale,
    sb * scale,
    0,
    offset,
    sr * scale,
    sg * scale,
    (sb + saturation) * scale,
    0,
    offset,
    0,
    0,
    0,
    1,
    0,
  ];
}

bool isCloseToZero(double value, [double epsilon = 1e-15]) {
  return value.abs() < epsilon;
}

typedef NormalizedTransform = ({double rotation, bool mirrorHorizontal, bool mirrorVertical});

NormalizedTransform normalizeTransformEdits(List<AssetEdit> edits) {
  final matrix = buildAffineFromEdits(edits);

  double a = matrix.a;
  double b = matrix.b;
  double c = matrix.c;
  double d = matrix.d;

  final rotation = ((isCloseToZero(a) ? asin(c) : acos(a)) * 180) / pi;

  return (
    rotation: rotation < 0 ? 360 + rotation : rotation,
    mirrorHorizontal: false,
    mirrorVertical: isCloseToZero(a) ? b == c : a == -d,
  );
}
