<script lang="ts">
  import { adjustManager, type AdjustmentKey } from '$lib/managers/edit/adjust-manager.svelte';
  import { t } from 'svelte-i18n';

  interface AdjustmentOption {
    key: AdjustmentKey;
    label: string;
  }

  const adjustments: AdjustmentOption[] = $derived([
    { key: 'brightness', label: $t('editor_brightness') },
    { key: 'contrast', label: $t('editor_contrast') },
    { key: 'saturation', label: $t('editor_saturation') },
  ]);
</script>

<div class="mt-3 px-4">
  <div class="mt-2 flex h-10 w-full items-center justify-between text-sm">
    <h2>{$t('editor_adjustments')}</h2>
  </div>

  {#each adjustments as adjustment (adjustment.key)}
    <div class="mt-2">
      <div class="flex w-full items-center justify-between text-sm">
        <label for="adjust-{adjustment.key}">{adjustment.label}</label>
        <span class="tabular-nums">{adjustManager.displayValue(adjustment.key)}</span>
      </div>
      <input
        id="adjust-{adjustment.key}"
        type="range"
        min="0"
        max="2"
        step="0.01"
        value={adjustManager[adjustment.key]}
        oninput={(event) => adjustManager.setValue(adjustment.key, Number(event.currentTarget.value))}
        ondblclick={() => adjustManager.setValue(adjustment.key, 1)}
        class="h-4 w-full accent-immich-primary"
      />
    </div>
  {/each}
</div>
