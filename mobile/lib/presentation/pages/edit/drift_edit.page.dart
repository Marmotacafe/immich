import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:crop_image/crop_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/aspect_ratios.dart';
import 'package:immich_mobile/constants/filter_presets.dart';
import 'package:immich_mobile/domain/models/asset_edit.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/pages/edit/editor.provider.dart';
import 'package:immich_mobile/providers/theme.provider.dart';
import 'package:immich_mobile/theme/theme_data.dart';
import 'package:immich_mobile/utils/editor.utils.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';
import 'package:immich_ui/immich_ui.dart';
import 'package:openapi/api.dart' show AdjustParameters, RotateParameters, MirrorParameters, MirrorAxis;

@RoutePage()
class DriftEditImagePage extends ConsumerStatefulWidget {
  final Image image;
  final Future<void> Function(List<AssetEdit> edits) applyEdits;

  const DriftEditImagePage({super.key, required this.image, required this.applyEdits});

  @override
  ConsumerState<DriftEditImagePage> createState() => _DriftEditImagePageState();
}

enum _EditorSection { transform, adjust, filters }

class _DriftEditImagePageState extends ConsumerState<DriftEditImagePage> with TickerProviderStateMixin {
  _EditorSection _section = _EditorSection.transform;

  Future<void> _saveEditedImage() async {
    ref.read(editorStateProvider.notifier).setIsEditing(true);

    final editorState = ref.read(editorStateProvider);
    final cropParameters = convertRectToCropParameters(
      editorState.crop,
      editorState.originalWidth,
      editorState.originalHeight,
    );
    final edits = <AssetEdit>[];

    if (cropParameters.width != editorState.originalWidth || cropParameters.height != editorState.originalHeight) {
      edits.add(CropEdit(cropParameters));
    }

    if (editorState.flipHorizontal) {
      edits.add(MirrorEdit(MirrorParameters(axis: MirrorAxis.horizontal)));
    }

    if (editorState.flipVertical) {
      edits.add(MirrorEdit(MirrorParameters(axis: MirrorAxis.vertical)));
    }

    final normalizedRotation = (editorState.rotationAngle % 360 + 360) % 360;
    if (normalizedRotation != 0) {
      edits.add(RotateEdit(RotateParameters(angle: normalizedRotation)));
    }

    if (editorState.hasAdjustments) {
      edits.add(
        AdjustEdit(
          AdjustParameters(
            brightness: editorState.brightness,
            contrast: editorState.contrast,
            saturation: editorState.saturation,
          ),
        ),
      );
    }

    try {
      await widget.applyEdits(edits);
      ImmichToast.show(context: context, msg: 'success'.tr(), toastType: ToastType.success);
      Navigator.of(context).pop();
    } catch (e) {
      ImmichToast.show(context: context, msg: 'error_title'.tr(), toastType: ToastType.error);
    } finally {
      ref.read(editorStateProvider.notifier).setIsEditing(false);
    }
  }

  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('editor_discard_edits_title'.tr()),
        content: Text('editor_discard_edits_prompt'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(context.themeData.colorScheme.onSurfaceVariant),
            ),
            child: Text('cancel'.tr()),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('confirm'.tr())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsavedEdits = ref.watch(editorStateProvider.select((state) => state.hasUnsavedEdits));

    return PopScope(
      canPop: !hasUnsavedEdits,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldDiscard = await _showDiscardChangesDialog() ?? false;
        if (shouldDiscard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Theme(
        data: getThemeData(colorScheme: ref.watch(immichThemeProvider).dark, locale: context.locale),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text("edit".tr()),
            leading: ImmichCloseButton(onPressed: () => Navigator.of(context).maybePop()),
            actions: [_SaveEditsButton(onSave: _saveEditedImage)],
          ),
          backgroundColor: Colors.black,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(child: _EditorPreview(image: widget.image)),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ref.watch(immichThemeProvider).dark.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EditorSectionToggle(
                          section: _section,
                          onChanged: (section) => setState(() => _section = section),
                        ),
                        switch (_section) {
                          _EditorSection.transform => const _TransformControls(),
                          _EditorSection.adjust => const _AdjustControls(),
                          _EditorSection.filters => _FilterControls(imageProvider: widget.image.image),
                        },
                        const Padding(
                          padding: EdgeInsets.only(bottom: 36, left: 24, right: 24),
                          child: Row(children: [Spacer(), _ResetEditsButton()]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AspectRatioButton extends StatelessWidget {
  final CropAspectRatio ratio;
  final bool isSelected;
  final VoidCallback onPressed;

  const _AspectRatioButton({required this.ratio, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.primaryColor : context.themeData.iconTheme.color;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        IconButton(
          iconSize: 36,
          icon: ratio.ratio != null
              ? _AspectRatioRect(ratio: ratio.ratio!, color: color)
              : Icon(ratio.icon, color: color),
          onPressed: onPressed,
        ),
        Text(ratio.label, style: context.textTheme.displayMedium),
      ],
    );
  }
}

class _AspectRatioRect extends StatelessWidget {
  final double ratio;
  final Color? color;

  const _AspectRatioRect({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color ?? Colors.transparent, width: 3),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AspectRatioSelector extends ConsumerWidget {
  const _AspectRatioSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: aspectRatioPresets.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _AspectRatioButton(
              ratio: entry,
              isSelected: editorState.aspectRatio == entry,
              onPressed: () => editorNotifier.setAspectRatio(entry),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EditorSectionToggle extends StatelessWidget {
  final _EditorSection section;
  final ValueChanged<_EditorSection> onChanged;

  const _EditorSectionToggle({required this.section, required this.onChanged});

  static const _icons = {
    _EditorSection.transform: Icons.crop_rotate,
    _EditorSection.adjust: Icons.tune,
    _EditorSection.filters: Icons.filter_vintage,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _EditorSection.values.map((value) {
          final isSelected = value == section;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ImmichIconButton(
              icon: _icons[value]!,
              variant: isSelected ? ImmichVariant.filled : ImmichVariant.ghost,
              color: isSelected ? ImmichColor.primary : ImmichColor.secondary,
              onPressed: () => onChanged(value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterControls extends ConsumerWidget {
  final ImageProvider imageProvider;

  const _FilterControls({required this.imageProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: filterPresets.map((preset) {
              final isSelected = preset.matches(
                brightness: editorState.brightness,
                contrast: editorState.contrast,
                saturation: editorState.saturation,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  onTap: () => editorNotifier.setAdjustments(
                    brightness: preset.brightness,
                    contrast: preset.contrast,
                    saturation: preset.saturation,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          border: Border.all(color: isSelected ? context.primaryColor : Colors.transparent, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(
                              buildAdjustColorMatrix(
                                brightness: preset.brightness,
                                contrast: preset.contrast,
                                saturation: preset.saturation,
                              ),
                            ),
                            child: Image(image: imageProvider, width: 64, height: 64, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.labelKey.tr(),
                        style: context.textTheme.displayMedium?.copyWith(
                          color: isSelected ? context.primaryColor : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AdjustmentSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _AdjustmentSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final percent = ((value - 1) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: context.textTheme.labelLarge)),
          Expanded(
            child: Slider(value: value, min: 0, max: 2, onChanged: onChanged),
          ),
          SizedBox(
            width: 40,
            child: Text(
              percent > 0 ? '+$percent' : '$percent',
              textAlign: TextAlign.end,
              style: context.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustControls extends ConsumerWidget {
  const _AdjustControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _AdjustmentSlider(
          label: 'editor_brightness'.tr(),
          value: editorState.brightness,
          onChanged: editorNotifier.setBrightness,
        ),
        _AdjustmentSlider(
          label: 'editor_contrast'.tr(),
          value: editorState.contrast,
          onChanged: editorNotifier.setContrast,
        ),
        _AdjustmentSlider(
          label: 'editor_saturation'.tr(),
          value: editorState.saturation,
          onChanged: editorNotifier.setSaturation,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TransformControls extends ConsumerWidget {
  const _TransformControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorNotifier = ref.read(editorStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ImmichIconButton(
                    icon: Icons.rotate_left,
                    variant: ImmichVariant.ghost,
                    color: ImmichColor.secondary,
                    onPressed: editorNotifier.rotateCCW,
                  ),
                  const SizedBox(width: 8),
                  ImmichIconButton(
                    icon: Icons.rotate_right,
                    variant: ImmichVariant.ghost,
                    color: ImmichColor.secondary,
                    onPressed: editorNotifier.rotateCW,
                  ),
                ],
              ),
              Row(
                children: [
                  ImmichIconButton(
                    icon: Icons.flip,
                    variant: ImmichVariant.ghost,
                    color: ImmichColor.secondary,
                    onPressed: editorNotifier.flipHorizontally,
                  ),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: pi / 2,
                    child: ImmichIconButton(
                      icon: Icons.flip,
                      variant: ImmichVariant.ghost,
                      color: ImmichColor.secondary,
                      onPressed: editorNotifier.flipVertically,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _AspectRatioSelector(),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SaveEditsButton extends ConsumerWidget {
  final VoidCallback onSave;

  const _SaveEditsButton({required this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApplyingEdits = ref.watch(editorStateProvider.select((state) => state.isApplyingEdits));
    final hasUnsavedEdits = ref.watch(editorStateProvider.select((state) => state.hasUnsavedEdits));

    return isApplyingEdits
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        : ImmichIconButton(
            icon: Icons.done_rounded,
            color: ImmichColor.primary,
            variant: ImmichVariant.ghost,
            disabled: !hasUnsavedEdits,
            onPressed: onSave,
          );
  }
}

class _ResetEditsButton extends ConsumerWidget {
  const _ResetEditsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);

    return ImmichTextButton(
      labelText: 'reset'.tr(),
      onPressed: editorNotifier.resetEdits,
      variant: ImmichVariant.ghost,
      expanded: false,
      disabled: !editorState.hasEdits || editorState.isApplyingEdits,
    );
  }
}

class _EditorPreview extends ConsumerStatefulWidget {
  final Image image;

  const _EditorPreview({required this.image});

  @override
  ConsumerState<_EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends ConsumerState<_EditorPreview> with TickerProviderStateMixin {
  late final CropController cropController;

  @override
  void initState() {
    super.initState();

    cropController = CropController();
    cropController.crop = ref.read(editorStateProvider.select((state) => state.crop));
    cropController.addListener(onCrop);
  }

  void onCrop() {
    if (!mounted || cropController.crop == ref.read(editorStateProvider).crop) {
      return;
    }

    ref.read(editorStateProvider.notifier).setCrop(cropController.crop);
  }

  @override
  void dispose() {
    cropController.removeListener(onCrop);
    cropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);

    ref.listen(editorStateProvider, (previous, current) {
      // Only re-apply the aspect ratio when it changes, otherwise the crop rect will shrink on every rotation
      if (previous?.aspectRatio != current.aspectRatio) {
        double? ratio;

        ratio = switch (current.aspectRatio) {
          CropAspectRatio.original => current.originalWidth / current.originalHeight,
          _ => current.aspectRatio.ratio,
        };

        if (current.rotationAngle % 180 != 0) {
          ratio = ratio != null ? 1 / ratio : null;
        }

        cropController.aspectRatio = ratio;
      }

      if (cropController.crop != current.crop) {
        cropController.crop = current.crop;
      }
    });

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Calculate the bounding box size needed for the rotated container
        final baseWidth = constraints.maxWidth * 0.9;
        final baseHeight = constraints.maxHeight * 0.95;

        return Center(
          child: AnimatedRotation(
            turns: editorState.rotationAngle / 360,
            duration: editorState.animationDuration,
            curve: Curves.easeInOut,
            onEnd: editorNotifier.normalizeRotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(
                  editorState.flipHorizontal ? -1.0 : 1.0,
                  editorState.flipVertical ? -1.0 : 1.0,
                  1.0,
                  1.0,
                ),
              child: AnimatedContainer(
                duration: editorState.animationDuration,
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(10),
                width: (editorState.rotationAngle % 180 == 0) ? baseWidth : baseHeight,
                height: (editorState.rotationAngle % 180 == 0) ? baseHeight : baseWidth,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    buildAdjustColorMatrix(
                      brightness: editorState.brightness,
                      contrast: editorState.contrast,
                      saturation: editorState.saturation,
                    ),
                  ),
                  child: CropImage(controller: cropController, image: widget.image, gridColor: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
