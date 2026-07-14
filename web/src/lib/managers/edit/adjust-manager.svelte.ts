import { AssetEditAction, type AdjustParameters, type AssetResponseDto } from '@immich/sdk';
import { type EditActions, type EditToolManager } from '$lib/managers/edit/edit-manager.svelte';

export type AdjustmentKey = 'brightness' | 'contrast' | 'saturation';

const NEUTRAL = 1;

export class AdjustManager implements EditToolManager {
  brightness = $state(NEUTRAL);
  contrast = $state(NEUTRAL);
  saturation = $state(NEUTRAL);
  hasChanges = $state(false);

  canReset = $derived(this.brightness !== NEUTRAL || this.contrast !== NEUTRAL || this.saturation !== NEUTRAL);
  edits: EditActions = $derived.by(() => this.getEdits());

  // Live preview approximation of the server-side rendering: css brightness/contrast/saturate
  // are close to sharp's modulate (brightness, saturation) and mid-grey pivoted linear (contrast)
  cssFilter = $derived(`brightness(${this.brightness}) contrast(${this.contrast}) saturate(${this.saturation})`);

  getEdits(): EditActions {
    if (!this.canReset) {
      return [];
    }

    return [
      {
        action: AssetEditAction.Adjust,
        parameters: { brightness: this.brightness, contrast: this.contrast, saturation: this.saturation },
      },
    ];
  }

  setValue(key: AdjustmentKey, value: number) {
    this.hasChanges = true;
    this[key] = value;
  }

  displayValue(key: AdjustmentKey): string {
    const percent = Math.round((this[key] - NEUTRAL) * 100);
    return percent > 0 ? `+${percent}` : `${percent}`;
  }

  onActivate(asset: AssetResponseDto, edits: EditActions): Promise<void> {
    const adjust = edits.find((edit) => edit.action === AssetEditAction.Adjust);
    if (adjust) {
      const { brightness, contrast, saturation } = adjust.parameters as AdjustParameters;
      this.brightness = brightness;
      this.contrast = contrast;
      this.saturation = saturation;
    }

    return Promise.resolve();
  }

  onDeactivate() {
    this.reset();
  }

  reset() {
    this.brightness = NEUTRAL;
    this.contrast = NEUTRAL;
    this.saturation = NEUTRAL;
    this.hasChanges = false;
  }

  resetAllChanges(): Promise<void> {
    this.reset();
    return Promise.resolve();
  }
}

export const adjustManager = new AdjustManager();
