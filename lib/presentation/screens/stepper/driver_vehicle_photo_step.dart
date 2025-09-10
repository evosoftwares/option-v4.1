import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_colors.dart';

/// Step para captura de fotos do veículo
class DriverVehiclePhotoStep extends StatefulWidget {
  const DriverVehiclePhotoStep({
    super.key,
    required this.driverId,
    required this.documentType,
    required this.onNext,
    this.isLoading = false,
  });

  final String driverId;
  final DocumentType documentType;
  final VoidCallback onNext;
  final bool isLoading;

  @override
  State<DriverVehiclePhotoStep> createState() => _DriverVehiclePhotoStepState();
}

class _DriverVehiclePhotoStepState extends State<DriverVehiclePhotoStep> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _error;
  final _photoService = PhotoService();

  String get _title {
    switch (widget.documentType) {
      case DocumentType.vehicleFront:
        return 'Foto do Veículo - Frente';
      case DocumentType.vehicleBack:
        return 'Foto do Veículo - Trás';
      case DocumentType.vehicleLeft:
        return 'Foto do Veículo - Esquerda';
      case DocumentType.vehicleRight:
        return 'Foto do Veículo - Direita';
      case DocumentType.vehicleInterior:
        return 'Interior do Veículo';
      default:
        return 'Foto do Veículo';
    }
  }

  String get _instructions {
    switch (widget.documentType) {
      case DocumentType.vehicleFront:
        return 'Fotografe a frente do seu veículo. Certifique-se de que a foto esteja bem iluminada e todos os detalhes sejam visíveis.';
      case DocumentType.vehicleBack:
        return 'Fotografe a traseira do seu veículo. Verifique se todas as informações estão visíveis e nítidas.';
      case DocumentType.vehicleLeft:
        return 'Fotografe o lado esquerdo do seu veículo. Mantenha uma distância adequada para enquadrar todo o veículo.';
      case DocumentType.vehicleRight:
        return 'Fotografe o lado direito do seu veículo. Certifique-se de que a foto esteja bem iluminada.';
      case DocumentType.vehicleInterior:
        return 'Fotografe o interior do seu veículo. Mostre os bancos e o painel de instrumentos.';
      default:
        return 'Fotografe seu veículo conforme solicitado.';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingDocument();
  }

  Future<void> _loadExistingDocument() async {
    try {
      final existingDoc = await DriverDocumentService.getDocumentByType(
        widget.driverId,
        widget.documentType,
      );

      if (existingDoc != null && mounted) {
        setState(() {
          // We don't load the actual image for privacy reasons, just indicate that one exists
        });
      }
    } catch (e) {
      print('Error loading existing document: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() => _error = null);

      final image = await _photoService.takePhoto();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      setState(() => _error = 'Erro ao capturar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _error = null);

      final image = await _photoService.pickFromGallery();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      setState(() => _error = 'Erro ao selecionar foto: $e');
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Selecione uma foto do veículo');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      await DriverDocumentService.createDocument(
        driverId: widget.driverId,
        documentType: widget.documentType,
        imageFile: _selectedImage!,
      );

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_title enviada com sucesso!'),
            backgroundColor: colors.primary,
          ),
        );
        widget.onNext();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao enviar documento: $e';
        _isUploading = false;
      });
    }
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar Foto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      title: 'Câmera',
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.photo_library,
                      title: 'Galeria',
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Título e instruções
          Text(
            _title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _instructions,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Seção da foto
          if (_selectedImage != null)
            _buildImagePreview()
          else
            _buildImagePlaceholder(),

          const SizedBox(height: 24),

          // Mensagem de erro
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colors.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Spacer(),

          // Botão de continuar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: (_isUploading || widget.isLoading)
                  ? null
                  : _uploadAndContinue,
              child: (_isUploading || widget.isLoading)
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.onPrimary,
                        ),
                      ),
                    )
                  : const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.scrim.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.scrim.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: _showImageSourceDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showImageSourceDialog,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: colors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar Foto do Veículo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toque para selecionar uma foto',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}