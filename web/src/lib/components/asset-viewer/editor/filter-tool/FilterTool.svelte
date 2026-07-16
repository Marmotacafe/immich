<script lang="ts">
  import { editManager } from '$lib/managers/edit/edit-manager.svelte';
  import { cssFilterForPreset, filterManager, filterPresets } from '$lib/managers/edit/filter-manager.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { AssetMediaSize } from '@immich/sdk';
  import { t } from 'svelte-i18n';

  let thumbnailSrc = $derived(
    editManager.currentAsset
      ? getAssetMediaUrl({
          id: editManager.currentAsset.id,
          cacheKey: editManager.currentAsset.thumbhash,
          edited: false,
          size: AssetMediaSize.Thumbnail,
        })
      : null,
  );
</script>

<div class="mt-3 px-4">
  <div class="mt-2 flex h-10 w-full items-center justify-between text-sm">
    <h2>{$t('editor_filters')}</h2>
  </div>

  <div class="grid grid-cols-3 gap-3">
    {#each filterPresets as preset (preset.id)}
      {@const isSelected = filterManager.selectedFilter?.id === preset.id}
      <button
        type="button"
        class="flex flex-col items-center gap-1"
        onclick={() => filterManager.selectFilter(preset)}
        aria-label={$t(preset.labelKey)}
        aria-pressed={isSelected}
      >
        <div
          class={[
            'aspect-square w-full overflow-hidden rounded-lg border-2',
            isSelected ? 'border-immich-primary' : 'border-transparent',
          ]}
        >
          {#if thumbnailSrc}
            <img
              draggable="false"
              src={thumbnailSrc}
              alt={$t(preset.labelKey)}
              class="size-full object-cover select-none"
              style:filter={cssFilterForPreset(preset)}
            />
          {/if}
        </div>
        <span class={['text-xs', isSelected ? 'text-immich-primary' : 'text-white']}>{$t(preset.labelKey)}</span>
      </button>
    {/each}
  </div>
</div>
