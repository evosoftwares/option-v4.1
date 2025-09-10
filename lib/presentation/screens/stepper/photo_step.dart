import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class PhotoStep extends StatefulWidget {

  const PhotoStep({
    super.key,
    required this.onNext,
    this.onSave,
  });
  final VoidCallback onNext;
  final Function(String)? onSave;

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final controller = Provider.of<StepperController>(context, listen: false);
        controller.setProfilePhoto(File(image.path));
        widget.onSave?.call(image.path);
      }
    } catch (e) {
      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.error,
            content: Text(
              'Erro ao selecionar foto. Por favor, tente novamente.',
              style: TextStyle(color: colors.onError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removePhoto() {
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.removeProfilePhoto();
  }

  Future<void> _submitPhoto() async {
    final controller = Provider.of<StepperController>(context, listen: false);
    
    if (!controller.hasProfilePhoto()) {
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.error,
          content: Text(
            'Por favor, adicione uma foto para continuar.',
            style: TextStyle(color: colors.onError),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.error,
            content: Text(
              'Erro ao continuar. Por favor, tente novamente mais tarde.',
              style: TextStyle(color: colors.onError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Consumer<StepperController>(
      builder: (context, controller, child) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Adicione uma foto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                controller.userType == 'driver'
                    ? 'As pessoas gostam de ver quem está dirigindo'
                    : 'As pessoas gostam de ver quem está solicitando a corrida',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: AppSpacing.avatarXl * 2.34,
                    height: AppSpacing.avatarXl * 2.34,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.outline,
                        width: AppSpacing.xs / 2,
                      ),
                    ),
                    child: controller.hasProfilePhoto()
                        ? ClipOval(
                            child: kIsWeb
                                ? Image.network(
                                    controller.profilePhoto!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.broken_image,
                                        size: AppSpacing.iconXl + AppSpacing.xs * 2,
                                        color: colors.onSurfaceVariant,
                                      ),
                                  )
                                : Image.file(
                                    controller.profilePhoto!,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: AppSpacing.iconXl + AppSpacing.xs * 2,
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              if (controller.hasProfilePhoto()) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: _removePhoto,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.error,
                    ),
                    child: const Text(
                      'Remover foto',
                      style: TextStyle(
                        fontSize: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitPhoto,
                  child: _isLoading
                      ? SizedBox(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSpacing.xs / 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: AppSpacing.md,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
    );
  }

  void _showImageSourceDialog() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
      ),
      builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: colors.onSurface),
                  title: Text('Tirar foto', style: TextStyle(color: colors.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: colors.onSurface),
                  title: Text('Escolher da galeria', style: TextStyle(color: colors.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}