import { AssetEditAction } from '@immich/sdk';
import { adjustManager } from '$lib/managers/edit/adjust-manager.svelte';
import { FilterManager, filterPresets } from '$lib/managers/edit/filter-manager.svelte';

describe('FilterManager', () => {
  let sut: FilterManager;

  beforeEach(() => {
    adjustManager.reset();
    sut = new FilterManager();
  });

  afterEach(() => {
    adjustManager.reset();
  });

  it('detects the original preset for neutral adjustments', () => {
    expect(sut.selectedFilter?.id).toBe('original');
  });

  it('writes preset values through to the adjust manager', () => {
    const vivid = filterPresets.find((preset) => preset.id === 'vivid')!;

    sut.selectFilter(vivid);

    expect(adjustManager.brightness).toBe(vivid.brightness);
    expect(adjustManager.contrast).toBe(vivid.contrast);
    expect(adjustManager.saturation).toBe(vivid.saturation);
    expect(sut.selectedFilter?.id).toBe('vivid');
  });

  it('emits no edits of its own so the adjust action is not duplicated', () => {
    const mono = filterPresets.find((preset) => preset.id === 'mono')!;

    sut.selectFilter(mono);

    expect(sut.edits).toEqual([]);
    expect(adjustManager.edits).toEqual([
      {
        action: AssetEditAction.Adjust,
        parameters: { brightness: mono.brightness, contrast: mono.contrast, saturation: mono.saturation },
      },
    ]);
  });

  it('reports no selected preset for custom adjustments', () => {
    adjustManager.setValue('brightness', 1.17);

    expect(sut.selectedFilter).toBeUndefined();
  });
});
