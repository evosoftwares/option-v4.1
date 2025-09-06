import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../services/photo_service.dart';
import '../../theme/app_colors.dart';

/// Tela para captura e upload de documentos do motorista
class DocumentCaptureScreen extends StatefulWidget {

  const DocumentCaptureScreen({
    super.key,
    required this.documentType,
    required this.driverId,
    this.existingDocument,
  });
  final DocumentType documentType;
  final String driverId;
  final DriverDocument? existingDocument;

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;
  String? _error;
  DateTime? _expiryDate;
  final _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    if (widget.existingDocument?.expiryDate != null) {
      _expiryDate = widget.existingDocument!.expiryDate;
    }
    // Carregar URL da imagem existente se disponível
    if (widget.existingDocument?.fileUrl.isNotEmpty == true) {
      _existingImageUrl = widget.existingDocument!.fileUrl;
    }
  }

  bool get _requiresExpiryDate => widget.documentType == DocumentType.cnhFront ||
        widget.documentType == DocumentType.cnhBack ||
        widget.documentType == DocumentType.crlv;

  String get _documentTitle {
    switch (widget.documentType) {
      case DocumentType.cnhFront:
        return 'CNH - Frente';
      case DocumentType.cnhBack:
        return 'CNH - Verso';
      case DocumentType.crlv:
        return 'CRLV';
      case DocumentType.vehicleFront:
        return 'Foto do Veículo - Frente';
      case DocumentType.vehicleBack:
        return 'Foto do Veículo - Traseira';
      case DocumentType.vehicleLeft:
        return 'Foto do Veículo - Lateral Esquerda';
      case DocumentType.vehicleRight:
        return 'Foto do Veículo - Lateral Direita';
      case DocumentType.vehicleInterior:
        return 'Foto do Veículo - Interior';
    }
  }

  String get _documentInstructions {
    switch (widget.documentType) {
      case DocumentType.cnhFront:
        return 'Fotografe a frente da sua CNH. Certifique-se de que todos os dados estejam legíveis e a foto esteja bem iluminada.';
      case DocumentType.cnhBack:
        return 'Fotografe o verso da sua CNH. Verifique se todas as informações estão visíveis e nítidas.';
      case DocumentType.crlv:
        return 'Fotografe seu CRLV (Certificado de Registro e Licenciamento do Veículo). Todos os dados devem estar legíveis.';
      case DocumentType.vehicleFront:
        return 'Tire uma foto da frente do seu veículo. Inclua a placa e certifique-se de que o veículo esteja bem enquadrado.';
      case DocumentType.vehicleBack:
        return 'Fotografe a traseira do seu veículo. A placa deve estar visível e legível.';
      case DocumentType.vehicleLeft:
        return 'Tire uma foto da lateral esquerda do seu veículo. Mostre o perfil completo do carro.';
      case DocumentType.vehicleRight:
        return 'Fotografe a lateral direita do seu veículo. Inclua o perfil completo do carro.';
      case DocumentType.vehicleInterior:
        return 'Tire uma foto do interior do seu veículo. Mostre os bancos e o painel.';
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _error = null;
      });

      final image = await _photoService.takePhoto();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      } else {
        setState(() {
          _error = 'Não foi possível capturar a foto';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao capturar foto: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _error = null;
      });

      final image = await _photoService.pickFromGallery();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      } else {
        setState(() {
          _error = 'Não foi possível selecionar a foto';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao selecionar foto: $e';
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 20);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.lightPrimary,
              onPrimary: AppColors.lightOnPrimary,
              surface: AppColors.lightSurface,
              onSurface: AppColors.lightOnSurface,
            ),
          ),
          child: child!,
        ),
    );

    if (selectedDate != null) {
      setState(() {
        _expiryDate = selectedDate;
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedImage == null) {
      setState(() {
        _error = 'Selecione uma foto antes de continuar';
      });
      return;
    }

    if (_requiresExpiryDate && _expiryDate == null) {
      setState(() {
        _error = 'Data de validade é obrigatória para este documento';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // Criar documento usando o serviço
      await DriverDocumentService.createDocument(
        driverId: widget.driverId,
        documentType: widget.documentType,
        imageFile: _selectedImage!,
        expiryDate: _expiryDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento enviado com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao enviar documento: $e';
        _isUploading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightSurface,
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
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar Foto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightOnSurface,
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
  }) => DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray200,
        ),
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
                    color: AppColors.lightPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.lightPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          _documentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            _buildImageSection(),
            if (_requiresExpiryDate) ...[
              const SizedBox(height: 24),
              _buildExpiryDateSection(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
            const SizedBox(height: 32),
            _buildUploadButton(),
          ],
        ),
      ),
    );

  Widget _buildInstructionsCard() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instruções',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _documentInstructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );

  Widget _buildImageSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto do Documento',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildImageDisplay(),
      ],
    );

  /// Método principal para decidir qual imagem exibir
  Widget _buildImageDisplay() {
    if (_selectedImage != null) {
      return _buildLocalImagePreview();
    } else if (_existingImageUrl != null) {
      return _buildNetworkImagePreview();
    } else {
      return _buildImagePlaceholder();
    }
  }

  /// Preview de imagem local (recém selecionada)
  Widget _buildLocalImagePreview() => Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray200,
        ),
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
                  color: AppColors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

  /// Preview de imagem da rede (documento existente)
  Widget _buildNetworkImagePreview() => Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusBorderColor(),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              _existingImageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.gray100,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lightPrimary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.gray100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erro ao carregar imagem',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Indicador de status
            _buildStatusIndicator(),
            // Botão para substituir imagem
            Positioned(
              bottom: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
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

  /// Retorna a cor da borda baseada no status do documento
  Color _getStatusBorderColor() {
    if (widget.existingDocument == null) return AppColors.gray200;
    
    switch (widget.existingDocument!.status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray200;
    }
  }

  /// Constrói o indicador visual de status do documento
  Widget _buildStatusIndicator() {
    if (widget.existingDocument == null) return const SizedBox.shrink();
    
    final document = widget.existingDocument!;
    IconData icon;
    Color color;
    String label;
    
    switch (document.status) {
      case 'approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        label = 'Aprovado';
        break;
      case 'pending':
        icon = Icons.schedule;
        color = AppColors.warning;
        label = 'Em análise';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        label = 'Rejeitado';
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.gray400;
        label = 'Desconhecido';
    }
    
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna o texto apropriado para o botão de upload
  String _getUploadButtonText() {
    if (_selectedImage != null) {
      return widget.existingDocument != null ? 'Substituir Documento' : 'Enviar Documento';
    } else if (widget.existingDocument != null) {
      return 'Reenviar Documento';
    } else {
      return 'Enviar Documento';
    }
  }

  Widget _buildImagePlaceholder() => Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray200,
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
                  color: AppColors.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: AppColors.lightPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar Foto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toque para selecionar uma foto',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildExpiryDateSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data de Validade',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gray200,
            ),
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
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.gray600,
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
                              ? AppColors.lightOnSurface
                              : AppColors.gray600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.gray400,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

  Widget _buildErrorMessage() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildUploadButton() {
    final canUpload = _selectedImage != null && 
        (!_requiresExpiryDate || _expiryDate != null) && 
        !_isUploading;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canUpload ? _uploadDocument : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.lightOnPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Enviando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                _getUploadButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}