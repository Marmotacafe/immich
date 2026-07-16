import "package:openapi/api.dart" show AdjustParameters, CropParameters, RotateParameters, MirrorParameters;

// The local database stores this enum by index, so new values must be appended
// at the end to keep existing rows decoding correctly
enum AssetEditAction { rotate, crop, mirror, other, adjust }

sealed class AssetEdit {
  const AssetEdit();
}

class CropEdit extends AssetEdit {
  final CropParameters parameters;

  const CropEdit(this.parameters);
}

class RotateEdit extends AssetEdit {
  final RotateParameters parameters;

  const RotateEdit(this.parameters);
}

class MirrorEdit extends AssetEdit {
  final MirrorParameters parameters;

  const MirrorEdit(this.parameters);
}

class AdjustEdit extends AssetEdit {
  final AdjustParameters parameters;

  const AdjustEdit(this.parameters);
}
