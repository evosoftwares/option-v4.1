import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user.dart' as app;
import '../../services/file_upload_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/phone_mask.dart';
import '../../utils/phone_validator.dart';
import '../../utils/supabase_helper.dart';
import '../../widgets/app_card.dart';
import '../../widgets/logo_branding.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedType; // 'passenger' | 'driver'

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  app.User? _currentUser;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = SupabaseHelper.client;
      if (supabase == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final user = await UserService.getUserById(authUser.id);
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuário não encontrado'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      _currentUser = user;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone != null && user.phone!.isNotEmpty
          ? PhoneValidator.format(user.phone!)
          : '';
      _selectedType = user.userType;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao carregar dados. Por favor, tente novamente mais tarde.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() => _selectedImage = File(image.path));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao selecionar imagem: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null || _currentUser == null) return null;

    setState(() => _uploadingPhoto = true);
    try {
      final photoPath = FileUploadService.generateUserPhotoPath(
        userId: _currentUser!.id,
        fileName: 'profile.jpg',
      );

      final photoUrl = await FileUploadService.uploadImage(
        file: _selectedImage!,
        bucket: 'user-photos', // Usar o mesmo bucket do stepper para consistência
        path: photoPath,
        compress: true,
      );

      return photoUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer upload da foto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _onSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_currentUser == null) return;

    setState(() => _saving = true);
    try {
      final unformattedPhone = _phoneController.text.isNotEmpty
          ? PhoneValidator.unformat(_phoneController.text)
          : null;

      // Upload da foto se foi selecionada uma nova
      String? newPhotoUrl;
      if (_selectedImage != null) {
        newPhotoUrl = await _uploadPhoto();
      }

      final updated = await UserService.updateUser(
        userId: _currentUser!.id,
        fullName: _nameController.text.trim(),
        phone: unformattedPhone,
        userType: _selectedType,
        photoUrl: newPhotoUrl ?? _currentUser!.photoUrl,
      );

      if (!mounted) return;
      setState(() => _currentUser = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil atualizado com sucesso'),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar. Por favor, verifique os dados e tente novamente.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    
    final photoUrl = _currentUser?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }
    
    return null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const StandardAppBar(title: 'Editar perfil'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              minimum: AppSpacing.screenMargin,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Container surface for user info
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informações da conta', style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.email ?? '-',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Profile photo section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: _getProfileImage(),
                                child: _getProfileImage() == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: colorScheme.onSurfaceVariant,
                                      )
                                    : null,
                              ),
                              if (_uploadingPhoto)
                                const Positioned.fill(
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    color: colorScheme.onPrimary,
                                    onPressed: _uploadingPhoto ? null : _selectImage,
                                    iconSize: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Toque no ícone para alterar sua foto',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Full name field
                    Text('Nome completo', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        hintText: 'Seu nome e sobrenome',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu nome completo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Phone field
                    Text('Telefone', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PhoneInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: '(11) 9 1234-5678',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // opcional
                        }
                        return PhoneValidator.validate(value);
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // User type selection
                    Text('Tipo de usuário', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _TypeChip(
                          label: 'Passageiro',
                          value: 'passenger',
                          groupValue: _selectedType,
                          onSelected: (v) => setState(() => _selectedType = v),
                        ),
                        _TypeChip(
                          label: 'Motorista',
                          value: 'driver',
                          groupValue: _selectedType,
                          onSelected: (v) => setState(() => _selectedType = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: _saving ? null : _onSave,
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TypeChip extends StatelessWidget {

  const _TypeChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: colorScheme.secondaryContainer,
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colorScheme.secondary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}