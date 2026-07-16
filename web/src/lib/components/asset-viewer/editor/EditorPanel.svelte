<script lang="ts">
  import { shortcuts } from '$lib/actions/shortcut';
  import { editManager, EditToolType } from '$lib/managers/edit/edit-manager.svelte';
  import { websocketEvents } from '$lib/stores/websocket';
  import { getAssetEdits, type AssetEditsResponseDto, type AssetResponseDto } from '@immich/sdk';
  import { Button, HStack, IconButton } from '@immich/ui';
  import { mdiClose } from '@mdi/js';
  import { onDestroy, onMount } from 'svelte';
  import { t } from 'svelte-i18n';

  onMount(() => {
    return websocketEvents.on('on_asset_update', (assetUpdate) => {
      if (assetUpdate.id === asset.id) {
        asset = assetUpdate;
      }
    });
  });

  interface Props {
    asset: AssetResponseDto;
    onClose: () => void;
  }

  let assetEdits = $state<AssetEditsResponseDto | null>(null);

  const toolLabels = $derived<Record<EditToolType, string>>({
    [EditToolType.Transform]: $t('editor_tool_transform'),
    [EditToolType.Adjust]: $t('editor_tool_adjust'),
    [EditToolType.Filters]: $t('editor_tool_filters'),
  });

  onMount(async () => {
    assetEdits = await getAssetEdits({ id: asset.id });
    await editManager.activateTool(EditToolType.Transform, asset, assetEdits);
  });

  async function selectTool(toolType: EditToolType) {
    if (!assetEdits) {
      return;
    }

    await editManager.activateTool(toolType, asset, assetEdits);
  }

  onDestroy(() => {
    editManager.cleanup();
  });

  async function applyEdits() {
    const success = await editManager.applyEdits();

    if (success) {
      onClose();
    }
  }

  async function closeEditor() {
    if (await editManager.closeConfirm()) {
      onClose();
    }
  }

  let { asset = $bindable(), onClose }: Props = $props();
</script>

<svelte:document
  use:shortcuts={[
    { shortcut: { key: 'Escape' }, onShortcut: onClose },
    { shortcut: { key: 'Enter' }, onShortcut: applyEdits },
  ]}
/>

<section class="dark relative flex h-full flex-col p-2 pt-3 dark:bg-immich-dark-bg dark:text-immich-dark-fg">
  <HStack class="me-4 justify-between">
    <HStack>
      <IconButton
        shape="round"
        variant="ghost"
        color="secondary"
        icon={mdiClose}
        aria-label={$t('close')}
        onclick={closeEditor}
      />
      <p class="text-lg text-immich-fg capitalize dark:text-immich-dark-fg">{$t('editor')}</p>
    </HStack>
    <Button shape="round" size="small" onclick={applyEdits} loading={editManager.isApplyingEdits}>{$t('save')}</Button>
  </HStack>

  <HStack class="mt-3 justify-center">
    {#each editManager.tools as tool (tool.type)}
      <IconButton
        shape="round"
        variant={editManager.selectedTool?.type === tool.type ? 'filled' : 'ghost'}
        color={editManager.selectedTool?.type === tool.type ? 'primary' : 'secondary'}
        icon={tool.icon}
        aria-label={toolLabels[tool.type]}
        onclick={() => selectTool(tool.type)}
      />
    {/each}
  </HStack>

  <section>
    {#if editManager.selectedTool}
      <editManager.selectedTool.component />
    {/if}
  </section>
  <div class="flex-1"></div>
  <section class="p-4">
    <Button
      variant="outline"
      onclick={() => editManager.resetAllChanges()}
      disabled={!editManager.canReset}
      class="self-start"
      shape="round"
      size="small"
    >
      {$t('editor_reset_all_changes')}
    </Button>
  </section>
</section>
