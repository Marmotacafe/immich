<script lang="ts">
  import { adjustManager } from '$lib/managers/edit/adjust-manager.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { getAltText } from '$lib/utils/thumbnail-util';
  import { toTimelineAsset } from '$lib/utils/timeline-util';
  import { AssetMediaSize, type AssetResponseDto } from '@immich/sdk';

  interface Props {
    asset: AssetResponseDto;
  }

  let { asset }: Props = $props();

  let imageSrc = $derived(
    getAssetMediaUrl({ id: asset.id, cacheKey: asset.thumbhash, edited: false, size: AssetMediaSize.Preview }),
  );
</script>

<div class="flex size-full items-center justify-center p-8">
  <img
    draggable="false"
    src={imageSrc}
    alt={$getAltText(toTimelineAsset(asset))}
    class="max-h-full max-w-full select-none"
    style:filter={adjustManager.cssFilter}
  />
</div>
