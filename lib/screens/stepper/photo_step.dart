import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Adicione uma foto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As pessoas gostam de ver quem está dirigindo',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceDialog(),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.outline,
                        width: 2,
                      ),
                    ),
                    child: controller.hasProfilePhoto()
                        ? ClipOval(
                            child: kIsWeb
                                ? Image.network(
                                    controller.profilePhoto!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: colors.onSurfaceVariant,
                                      );
                                    },
                                  )
                                : Image.file(
                                    controller.profilePhoto!,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              if (controller.hasProfilePhoto()) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _removePhoto,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.error,
                    ),
                    child: const Text(
                      'Remover foto',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitPhoto,
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: colors.primary),
                  title: Text('Tirar foto', style: TextStyle(color: colors.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: colors.primary),
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