import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'document_capture_screen.dart';

/// Tela principal para gerenciamento de documentos do motorista
class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  String _driverId = '';

  List<DriverDocument> _documents = [];
  Map<String, dynamic>? _documentationStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDriver();
  }

  Future<void> _initializeDriver() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
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

      // Garantir que existe um registro de driver
      _driverId = await _ensureDriverExists(user.id);

      // Carregar documentos
      await _loadDocuments();
    } catch (e) {
      setState(() {
        _error = 'Erro ao inicializar: $e';
        _isLoading = false;
      });
    }
  }

  /// Garante que existe um registro de driver para o usuário e retorna o ID
  Future<String> _ensureDriverExists(String userId) async {
    try {
      // Primeiro, tentar buscar driver existente
      final existingDriverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingDriverResponse != null) {
        return existingDriverResponse['id'] as String;
      }

      // Se não existe, criar usando dados básicos
      print('⚠️ Registro de driver não encontrado, criando automaticamente...');

      // Criar registro de driver básico
      final driverData = {
        'user_id': userId,
        'vehicle_brand': 'PENDENTE',
        'vehicle_model': 'PENDENTE',
        'vehicle_year': 2020,
        'vehicle_color': 'PENDENTE',
        'vehicle_plate': 'PENDENTE_${userId.substring(0, 8)}',
        'vehicle_category': 'Comum',
        'approval_status': 'pending',
        'approved_by': null,
        'approved_at': null,
        'is_online': false,
        'accepts_pet': false,
        'pet_fee': 0.0,
        'accepts_grocery': false,
        'grocery_fee': 0.0,
        'accepts_condo': false,
        'condo_fee': 0.0,
        'stop_fee': 0.0,
        'ac_policy': 'on_request',
        'custom_price_per_km': 0.0,
        'custom_price_per_minute': 0.0,
        'bank_account_type': null,
        'bank_code': null,
        'bank_agency': null,
        'bank_account': null,
        'pix_key': '',
        'pix_key_type': 'email',
        'consecutive_cancellations': 0,
        'total_trips': 0,
        'average_rating': null,
        'current_latitude': null,
        'current_longitude': null,
        'last_location_update': null,
      };

      final newDriverResponse = await Supabase.instance.client
          .from('drivers')
          .insert(driverData)
          .select('id')
          .single();

      final driverId = newDriverResponse['id'] as String;
      print('✅ Registro de driver criado com sucesso: $driverId');
      return driverId;
    } catch (e) {
      throw Exception('Erro ao garantir registro de driver: $e');
    }
  }

  Future<void> _loadDocuments() async {
    if (_driverId.isEmpty) {
      setState(() {
        _error = 'Driver ID não disponível';
        _isLoading = false;
      });
      return;
    }

    try {
      final documents =
          await DriverDocumentService.getCurrentDriverDocuments(_driverId);
      final status =
          await DriverDocumentService.getDocumentationStatus(_driverId);

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
          existingDocument:
              existingDocument.id.isNotEmpty ? existingDocument : null,
        ),
      ),
    );

    if (result ?? false) {
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusCard(),
                          SizedBox(height: AppSpacing.xl),
                          _buildDocumentsList(),
                        ],
                      ),
                    ),
                  ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.3),
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

  Widget _buildStatusCard() {
    if (_documentationStatus == null) return const SizedBox.shrink();

    final isComplete = _documentationStatus!['isComplete'] as bool;
    final totalRequired = _documentationStatus!['totalRequired'] as int;
    final totalApproved = _documentationStatus!['totalApproved'] as int;
    final pendingCount =
        (_documentationStatus!['pendingDocuments'] as List).length;
    final rejectedCount =
        (_documentationStatus!['rejectedDocuments'] as List).length;
    final missingCount =
        (_documentationStatus!['missingDocuments'] as List).length;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (isComplete) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Documentação Completa';
      statusDescription = 'Parabéns! Você pode ficar online e receber corridas';
    } else if (rejectedCount > 0) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
      statusText = 'Documentos Rejeitados';
      statusDescription =
          '$rejectedCount documento(s) foram rejeitados e precisam ser reenviados';
    } else if (pendingCount > 0) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'Aguardando Análise';
      statusDescription =
          '$pendingCount documento(s) estão sendo analisados pela nossa equipe';
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.upload_file;
      statusText = 'Documentos Pendentes';
      statusDescription =
          '$missingCount documento(s) obrigatórios precisam ser enviados';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightOnSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          LinearProgressIndicator(
            value: totalRequired > 0 ? totalApproved / totalRequired : 0,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
                    ),
              ),
              Text(
                '$totalApproved de $totalRequired documentos aprovados',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
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
        'isRequired': true,
      },
      {
        'type': DocumentType.cnhBack,
        'title': 'CNH - Verso',
        'description': 'Carteira Nacional de Habilitação (verso)',
        'icon': Icons.credit_card,
        'requiresExpiry': true,
        'isRequired': true,
      },
      {
        'type': DocumentType.crlv,
        'title': 'CRLV',
        'description': 'Certificado de Registro e Licenciamento do Veículo',
        'icon': Icons.description,
        'requiresExpiry': true,
        'isRequired': true,
      },
      {
        'type': DocumentType.vehicleFront,
        'title': 'Foto do Veículo - Frente',
        'description': 'Foto frontal do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
        'isRequired': true,
      },
      {
        'type': DocumentType.vehicleBack,
        'title': 'Foto do Veículo - Traseira',
        'description': 'Foto traseira do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
        'isRequired': false,
      },
      {
        'type': DocumentType.vehicleLeft,
        'title': 'Foto do Veículo - Lateral Esquerda',
        'description': 'Foto lateral esquerda do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
        'isRequired': false,
      },
      {
        'type': DocumentType.vehicleRight,
        'title': 'Foto do Veículo - Lateral Direita',
        'description': 'Foto lateral direita do veículo',
        'icon': Icons.directions_car,
        'requiresExpiry': false,
        'isRequired': false,
      },
    ];

    // Separar documentos obrigatórios e opcionais
    final requiredDocs =
        documentTypes.where((doc) => doc['isRequired'] == true).toList();
    final optionalDocs =
        documentTypes.where((doc) => doc['isRequired'] == false).toList();

    // Separar documentos faltantes dos demais
    final missingDocs = <Map<String, dynamic>>[];
    final completedDocs = <Map<String, dynamic>>[];

    for (final docType in requiredDocs) {
      final document = _documents.firstWhere(
        (doc) => doc.documentType == (docType['type']! as DocumentType).value,
        orElse: () => DriverDocument(
          id: '',
          driverId: _driverId,
          documentType: (docType['type']! as DocumentType).value,
          fileUrl: '',
          status: 'missing',
          isCurrent: false,
          createdAt: DateTime.now(),
        ),
      );

      if (document.status == 'missing' || document.id.isEmpty) {
        missingDocs.add(docType);
      } else {
        completedDocs.add(docType);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de documentos obrigatórios
        Text(
          'Documentos Obrigatórios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.lightOnSurface,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Mostrar documentos faltantes primeiro (se houver)
        if (missingDocs.isNotEmpty) ...[
          ...missingDocs.map((docType) {
            final document = _documents.firstWhere(
              (doc) =>
                  doc.documentType == (docType['type']! as DocumentType).value,
              orElse: () => DriverDocument(
                id: '',
                driverId: _driverId,
                documentType: (docType['type']! as DocumentType).value,
                fileUrl: '',
                status: 'missing',
                isCurrent: false,
                createdAt: DateTime.now(),
              ),
            );

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildDocumentTile(
                docType,
                document,
                isMissing: true,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Documentos obrigatórios já enviados
        ...completedDocs.map((docType) {
          final document = _documents.firstWhere(
            (doc) =>
                doc.documentType == (docType['type']! as DocumentType).value,
            orElse: () => DriverDocument(
              id: '',
              driverId: _driverId,
              documentType: (docType['type']! as DocumentType).value,
              fileUrl: '',
              status: 'missing',
              isCurrent: false,
              createdAt: DateTime.now(),
            ),
          );

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildDocumentTile(
              docType,
              document,
            ),
          );
        }),
        
        const SizedBox(height: AppSpacing.xl),

        // Seção de documentos opcionais
        Text(
          'Documentos Opcionais',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.lightOnSurface,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        ...optionalDocs.map((docType) {
          final document = _documents.firstWhere(
            (doc) =>
                doc.documentType == (docType['type']! as DocumentType).value,
            orElse: () => DriverDocument(
              id: '',
              driverId: _driverId,
              documentType: (docType['type']! as DocumentType).value,
              fileUrl: '',
              status: 'missing',
              isCurrent: false,
              createdAt: DateTime.now(),
            ),
          );

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildDocumentTile(
              docType,
              document,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocumentTile(
    Map<String, dynamic> docType,
    DriverDocument document, {
    bool isMissing = false,
  }) {
    final type = docType['type'] as DocumentType;
    final title = docType['title'] as String;
    final description = docType['description'] as String;
    final icon = docType['icon'] as IconData;
    final requiresExpiry = docType['requiresExpiry'] as bool;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    var showExpiry = false;
    var isExpired = false;

    switch (document.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Aprovado';
        if (requiresExpiry && document.expiryDate != null) {
          showExpiry = true;
          isExpired = document.expiryDate!.isBefore(DateTime.now());
          if (isExpired) {
            statusColor = AppColors.error;
            statusIcon = Icons.error_rounded;
            statusText = 'Expirado';
          }
        }
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
        statusText = 'Em análise';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Rejeitado';
        break;
      default:
        statusColor = isMissing ? AppColors.error : AppColors.gray400;
        statusIcon = Icons.camera_alt_rounded;
        statusText = isMissing ? 'Enviar agora' : 'Enviar';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isMissing
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _navigateToCapture(type),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                
                SizedBox(width: AppSpacing.md),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightOnSurface,
                            ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showExpiry && document.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Válido até ${_formatDate(document.expiryDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isExpired ? AppColors.error : AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(width: AppSpacing.sm),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}