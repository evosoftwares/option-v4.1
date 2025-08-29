import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Step para captura da CNH (frente ou verso)
class DriverCNHStep extends StatefulWidget {
  const DriverCNHStep({
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
  State<DriverCNHStep> createState() => _DriverCNHStepState();
}

class _DriverCNHStepState extends State<DriverCNHStep> {
  File? _selectedImage;
  DateTime? _expiryDate;
  bool _isUploading = false;
  String? _error;
  final _photoService = PhotoService();

  bool get _isFrontSide => widget.documentType == DocumentType.cnhFront;
  
  String get _title => _isFrontSide ? 'CNH - Frente' : 'CNH - Verso';
  
  String get _instructions => _isFrontSide
      ? 'Fotografe a frente da sua CNH. Certifique-se de que todos os dados estejam legíveis e a foto esteja bem iluminada.'
      : 'Fotografe o verso da sua CNH. Verifique se todas as informações estão visíveis e nítidas.';

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
      
      if (existingDoc != null) {
        setState(() {
          _expiryDate = existingDoc.expiryDate;
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

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );

    if (selectedDate != null) {
      setState(() => _expiryDate = selectedDate);
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Selecione uma foto da CNH');
      return;
    }

    if (_isFrontSide && _expiryDate == null) {
      setState(() => _error = 'Selecione a data de validade');
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
        expiryDate: _expiryDate,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
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
              fontWeight: AppTypography.bold,
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

          // Data de validade (apenas na frente da CNH)
          if (_isFrontSide) ...[
            Text(
              'Data de Validade',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selectExpiryDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _expiryDate != null
                                ? _formatDate(_expiryDate!)
                                : 'Selecionar data de validade',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _expiryDate != null
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: colors.onSurfaceVariant,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

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
                  : const Text(
                      'Continuar',
                      style: AppTypography.titleMedium,
                    ),
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
                  Icons.add_a_photo,
                  color: colors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar Foto da CNH',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}