import { AssetEditAction, type AssetResponseDto } from '@immich/sdk';
import { AdjustManager } from '$lib/managers/edit/adjust-manager.svelte';

describe('AdjustManager', () => {
  let sut: AdjustManager;

  beforeEach(() => {
    sut = new AdjustManager();
  });

  it('emits no edits when all values are neutral', () => {
    expect(sut.edits).toEqual([]);
    expect(sut.canReset).toBe(false);
    expect(sut.hasChanges).toBe(false);
  });

  it('emits a single adjust edit when a value changes', () => {
    sut.setValue('brightness', 1.5);

    expect(sut.hasChanges).toBe(true);
    expect(sut.canReset).toBe(true);
    expect(sut.edits).toEqual([
      {
        action: AssetEditAction.Adjust,
        parameters: { brightness: 1.5, contrast: 1, saturation: 1 },
      },
    ]);
  });

  it('initializes from an existing adjust edit without marking changes', async () => {
    await sut.onActivate({} as AssetResponseDto, [
      {
        action: AssetEditAction.Adjust,
        parameters: { brightness: 1.2, contrast: 0.8, saturation: 1.4 },
      },
    ]);

    expect(sut.brightness).toBe(1.2);
    expect(sut.contrast).toBe(0.8);
    expect(sut.saturation).toBe(1.4);
    expect(sut.hasChanges).toBe(false);
    expect(sut.canReset).toBe(true);
  });

  it('resets to neutral values', async () => {
    sut.setValue('contrast', 1.8);
    sut.setValue('saturation', 0.2);

    await sut.resetAllChanges();

    expect(sut.brightness).toBe(1);
    expect(sut.contrast).toBe(1);
    expect(sut.saturation).toBe(1);
    expect(sut.edits).toEqual([]);
    expect(sut.hasChanges).toBe(false);
  });

  it('formats display values as signed percentages', () => {
    expect(sut.displayValue('brightness')).toBe('0');

    sut.setValue('brightness', 1.25);
    expect(sut.displayValue('brightness')).toBe('+25');

    sut.setValue('brightness', 0.6);
    expect(sut.displayValue('brightness')).toBe('-40');
  });

  it('builds a css filter matching the current values', () => {
    sut.setValue('brightness', 1.1);
    sut.setValue('contrast', 0.9);

    expect(sut.cssFilter).toBe('brightness(1.1) contrast(0.9) saturate(1)');
  });
});
