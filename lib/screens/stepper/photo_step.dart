import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../theme/app_theme.dart';

class PhotoStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(String)? onSave;

  const PhotoStep({
    super.key,
    required this.onNext,
    this.onSave,
  });

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar foto: $e'),
            backgroundColor: AppTheme.uberRed,
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
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao continuar: $e'),
            backgroundColor: AppTheme.uberRed,
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
    return Consumer<StepperController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Adicione uma foto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As pessoas gostam de ver quem está dirigindo',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.uberLightGray,
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
                      color: AppTheme.uberMediumGray,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.uberWhite,
                        width: 2,
                      ),
                    ),
                    child: controller.hasProfilePhoto()
                        ? ClipOval(
                            child: Image.file(
                              controller.profilePhoto!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: AppTheme.uberLightGray,
                          ),
                  ),
                ),
              ),
              if (controller.hasProfilePhoto()) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _removePhoto,
                    child: const Text(
                      'Remover foto',
                      style: TextStyle(
                        color: AppTheme.uberRed,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _submitPhoto,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.uberWhite),
                        foregroundColor: AppTheme.uberWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pular'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.uberWhite,
                        foregroundColor: AppTheme.uberBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uberBlack),
                              ),
                            )
                          : const Text('Continuar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.uberDarkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('Tirar foto', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Escolher da galeria', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white),
                  title: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}