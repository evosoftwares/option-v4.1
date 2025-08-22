import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../theme/app_colors.dart';
import 'document_capture_screen.dart';

/// Tela principal para gerenciamento de documentos do motorista
class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final String _driverId = Supabase.instance.client.auth.currentUser?.id ?? '';
  
  List<DriverDocument> _documents = [];
  Map<String, dynamic>? _documentationStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (_driverId.isEmpty) {
      setState(() {
        _error = 'Usuário não autenticado';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final documents = await DriverDocumentService.getCurrentDriverDocuments(_driverId);
      final status = await DriverDocumentService.getDocumentationStatus(_driverId);

      setState(() {
        _documents = documents;
        _documentationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar documentos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCapture(DocumentType documentType) async {
    final existingDocument = _documents.firstWhere(
      (doc) => doc.documentType == documentType.value,
      orElse: () => DriverDocument(
        id: '',
        driverId: _driverId,
        documentType: documentType.value,
        fileUrl: '',
        status: 'missing',
        isCurrent: false,
        createdAt: DateTime.now(),
      ),
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentCaptureScreen(
          documentType: documentType,
          driverId: _driverId,
          existingDocument: existingDocument.id.isNotEmpty ? existingDocument : null,
        ),
      ),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Meus Documentos',
          style: TextStyle(
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.lightPrimary,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  color: AppColors.lightPrimary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 24),
                        _buildDocumentsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Erro desconhecido',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadDocuments,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: AppColors.lightOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_documentationStatus == null) return const SizedBox.shrink();

    final isComplete = _documentationStatus!['isComplete'] as bool;
    final totalRequired = _documentationStatus!['totalRequired'] as int;
    final totalApproved = _documentationStatus!['totalApproved'] as int;
    final pendingCount = (_documentationStatus!['pendingDocuments'] as List).length;
    final rejectedCount = (_documentationStatus!['rejectedDocuments'] as List).length;
    final missingCount = (_documentationStatus!['missingDocuments'] as List).length;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (isComplete) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Documentação Completa';
      statusDescription = 'Todos os documentos foram aprovados';
    } else if (rejectedCount > 0) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
      statusText = 'Documentos Rejeitados';
      statusDescription = '$rejectedCount documento(s) precisam ser reenviados';
    } else if (pendingCount > 0) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'Aguardando Análise';
      statusDescription = '$pendingCount documento(s) em análise';
    } else {
      statusColor = AppColors.info;
      statusIcon = Icons.upload_file;
      statusText = 'Documentos Pendentes';
      statusDescription = '$missingCount documento(s) precisam ser enviados';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: totalApproved / totalRequired,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$totalApproved/$totalRequired',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    final documentTypes = [
      {
        'type': DocumentType.cnhFront,
        'title': 'CNH - Frente',
        'description': 'Carteira Nacional de Habilitação (frente)',
        'icon': Icons.credit_card,
        'requiresExpiry': true,
      },
      {
        'type': DocumentType.cnhBack,
        'title': 'CNH - Verso',
        'description': 'Carteira Nacional de Habilitação (verso)',
        'icon': Icons.credit_card,
        'requiresExpiry': true,
      },
      {
        'type': DocumentType.crlv,
        'title': 'CRLV',
        'description': 'Certificado de Registro e Licenciamento do Veículo',
        'icon': Icons.description,
        'requiresExpiry': true,
      },
      {
        'type': DocumentType.vehicleFront,
        'title': 'Foto do Veículo - Frente',
        'description': 'Foto frontal do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
      },
      {
        'type': DocumentType.vehicleBack,
        'title': 'Foto do Veículo - Traseira',
        'description': 'Foto traseira do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
      },
      {
        'type': DocumentType.vehicleLeft,
        'title': 'Foto do Veículo - Lateral Esquerda',
        'description': 'Foto lateral esquerda do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
      },
      {
        'type': DocumentType.vehicleRight,
        'title': 'Foto do Veículo - Lateral Direita',
        'description': 'Foto lateral direita do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos Obrigatórios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...documentTypes.map((docType) {
          final document = _documents.firstWhere(
            (doc) => doc.documentType == (docType['type'] as DocumentType).name,
            orElse: () => DriverDocument(
              id: '',
              driverId: _driverId,
              documentType: (docType['type'] as DocumentType).name,
              fileUrl: '',
              status: 'missing',
              isCurrent: false,
              createdAt: DateTime.now(),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDocumentTile(
              docType,
              document,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDocumentTile(
    Map<String, dynamic> docType,
    DriverDocument document,
  ) {
    final type = docType['type'] as DocumentType;
    final title = docType['title'] as String;
    final description = docType['description'] as String;
    final icon = docType['icon'] as IconData;
    final requiresExpiry = docType['requiresExpiry'] as bool;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool showExpiry = false;
    bool isExpired = false;

    switch (document.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Aprovado';
        if (requiresExpiry && document.expiryDate != null) {
          showExpiry = true;
          isExpired = document.expiryDate!.isBefore(DateTime.now());
          if (isExpired) {
            statusColor = AppColors.error;
            statusIcon = Icons.error;
            statusText = 'Expirado';
          }
        }
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        statusText = 'Em análise';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejeitado';
        break;
      default:
        statusColor = AppColors.gray400;
        statusIcon = Icons.upload_file;
        statusText = 'Enviar';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToCapture(type),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.gray600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightOnSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showExpiry && document.expiryDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExpired 
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpired ? Icons.warning : Icons.schedule,
                          color: isExpired ? AppColors.error : AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired 
                              ? 'Expirado em ${_formatDate(document.expiryDate!)}'
                              : 'Válido até ${_formatDate(document.expiryDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isExpired ? AppColors.error : AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (document.status == 'rejected' && document.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Motivo da rejeição: ${document.rejectionReason}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}