import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../widgets/stepper_navigation.dart';

class Step2PhotoScreen extends StatefulWidget {
  const Step2PhotoScreen({super.key});

  @override
  State<Step2PhotoScreen> createState() => _Step2PhotoScreenState();
}

class _Step2PhotoScreenState extends State<Step2PhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<StepperController>(context, listen: false);
    if (controller.profilePhoto != null && controller.hasProfilePhoto()) {
      _imageFile = controller.profilePhoto;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Atualiza o controller
        final controller = Provider.of<StepperController>(context, listen: false);
        controller.setProfilePhoto(File(pickedFile.path));
      }
    } catch (e) {
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.error,
          content: Text(
            'Erro ao selecionar imagem. Por favor, tente novamente.',
            style: TextStyle(color: colors.onError),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
    
    // Remove do controller
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.removeProfilePhoto();
  }

  void _showImageSourceDialog() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            'Adicione uma foto de perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isso ajuda os motoristas a reconhecê-lo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 48),
          
          // Avatar circular
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceVariant,
                  border: Border.all(
                    color: colors.outline.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _imageFile != null
                    ? ClipOval(
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 60,
                        color: colors.onSurfaceVariant,
                      ),
              ),
              if (_isLoading)
                CircularProgressIndicator(color: colors.primary),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null) ...[
                ElevatedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: Text(_imageFile != null ? 'Trocar foto' : 'Adicionar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Texto opcional
          Text(
            _imageFile != null
                ? 'Foto adicionada com sucesso!'
                : 'Você pode pular esta etapa e adicionar depois',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _imageFile != null
                      ? colors.tertiary
                      : colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}