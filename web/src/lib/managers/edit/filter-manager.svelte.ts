import type { Translations } from 'svelte-i18n';
import { adjustManager } from '$lib/managers/edit/adjust-manager.svelte';
import { type EditActions, type EditToolManager } from '$lib/managers/edit/edit-manager.svelte';

export interface FilterPreset {
  id: string;
  labelKey: Translations;
  brightness: number;
  contrast: number;
  saturation: number;
}

export const filterPresets: FilterPreset[] = [
  { id: 'original', labelKey: 'editor_filter_original', brightness: 1, contrast: 1, saturation: 1 },
  { id: 'vivid', labelKey: 'editor_filter_vivid', brightness: 1, contrast: 1.1, saturation: 1.3 },
  { id: 'dramatic', labelKey: 'editor_filter_dramatic', brightness: 0.95, contrast: 1.3, saturation: 1.05 },
  { id: 'fade', labelKey: 'editor_filter_fade', brightness: 1.05, contrast: 0.85, saturation: 0.85 },
  { id: 'mono', labelKey: 'editor_filter_mono', brightness: 1, contrast: 1, saturation: 0 },
  { id: 'noir', labelKey: 'editor_filter_noir', brightness: 0.95, contrast: 1.35, saturation: 0 },
];

export const cssFilterForPreset = (preset: FilterPreset) =>
  `brightness(${preset.brightness}) contrast(${preset.contrast}) saturate(${preset.saturation})`;

const matches = (a: number, b: number) => Math.abs(a - b) < 1e-6;

// Filters are presets over the adjust parameters: selecting one writes through to
// adjustManager, which owns the resulting 'adjust' edit action. This manager emits
// no edits of its own so the action is never duplicated on save.
export class FilterManager implements EditToolManager {
  hasChanges = $state(false);
  canReset = false;
  edits: EditActions = [];

  selectedFilter = $derived.by(() =>
    filterPresets.find(
      (preset) =>
        matches(preset.brightness, adjustManager.brightness) &&
        matches(preset.contrast, adjustManager.contrast) &&
        matches(preset.saturation, adjustManager.saturation),
    ),
  );

  selectFilter(preset: FilterPreset) {
    adjustManager.setValue('brightness', preset.brightness);
    adjustManager.setValue('contrast', preset.contrast);
    adjustManager.setValue('saturation', preset.saturation);
  }

  onActivate(): Promise<void> {
    return Promise.resolve();
  }

  onDeactivate() {}

  resetAllChanges(): Promise<void> {
    return Promise.resolve();
  }
}

export const filterManager = new FilterManager();
