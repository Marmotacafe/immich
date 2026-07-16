// Filter presets are named combinations of the adjust edit parameters,
// mirroring web/src/lib/managers/edit/filter-manager.svelte.ts — keep both in sync
class FilterPreset {
  final String id;
  final String labelKey;
  final double brightness;
  final double contrast;
  final double saturation;

  const FilterPreset({
    required this.id,
    required this.labelKey,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  static const _epsilon = 1e-6;

  bool matches({required double brightness, required double contrast, required double saturation}) {
    return (this.brightness - brightness).abs() < _epsilon &&
        (this.contrast - contrast).abs() < _epsilon &&
        (this.saturation - saturation).abs() < _epsilon;
  }
}

const filterPresets = <FilterPreset>[
  FilterPreset(id: 'original', labelKey: 'editor_filter_original', brightness: 1, contrast: 1, saturation: 1),
  FilterPreset(id: 'vivid', labelKey: 'editor_filter_vivid', brightness: 1, contrast: 1.1, saturation: 1.3),
  FilterPreset(id: 'dramatic', labelKey: 'editor_filter_dramatic', brightness: 0.95, contrast: 1.3, saturation: 1.05),
  FilterPreset(id: 'fade', labelKey: 'editor_filter_fade', brightness: 1.05, contrast: 0.85, saturation: 0.85),
  FilterPreset(id: 'mono', labelKey: 'editor_filter_mono', brightness: 1, contrast: 1, saturation: 0),
  FilterPreset(id: 'noir', labelKey: 'editor_filter_noir', brightness: 0.95, contrast: 1.35, saturation: 0),
];
