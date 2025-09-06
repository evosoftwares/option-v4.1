# Mudanças Necessárias no Frontend

## Visão Geral

Com a implementação da solução técnica para eliminar a duplicidade de documentos, precisamos atualizar o frontend para refletir essas mudanças e melhorar a experiência do usuário. Esta documentação descreve as alterações necessárias em detalhes.

## 1. Serviços

### 1.1. Atualização do DriverDocumentService

#### Nova função para verificar documentos existentes na tabela drivers (fallback)
```dart
/// Verifica se um documento existe na tabela drivers como fallback
static Future<DriverDocument?> getDocumentFromDriverTable(
  String driverId, 
  DocumentType documentType
) async {
  try {
    // Buscar dados do driver
    final driverResponse = await _supabase
        .from('drivers')
        .select('cnh_photo_url, crlv_photo_url, created_at')
        .eq('id', driverId)
        .single();

    String? fileUrl;
    switch (documentType) {
      case DocumentType.cnhFront:
        fileUrl = driverResponse['cnh_photo_url'] as String?;
        break;
      case DocumentType.crlv:
        fileUrl = driverResponse['crlv_photo_url'] as String?;
        break;
      default:
        return null;
    }

    // Se encontrou URL na tabela drivers, criar um DriverDocument temporário
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return DriverDocument(
        id: 'fallback_${driverId}_${documentType.value}',
        driverId: driverId,
        documentType: documentType.value,
        fileUrl: fileUrl,
        status: 'approved', // Considerar como aprovado já que veio do cadastro
        isCurrent: true,
        createdAt: DateTime.parse(driverResponse['created_at'] as String),
      );
    }

    return null;
  } catch (e) {
    print('⚠️ Erro ao buscar documento da tabela drivers: $e');
    return null;
  }
}
```

#### Atualização da função getDocumentByType
```dart
/// Obtém um documento específico por tipo, verificando primeiro em driver_documents
/// e depois usando a tabela drivers como fallback
static Future<DriverDocument?> getDocumentByType(
  String driverId, 
  DocumentType documentType
) async {
  print('🔄 DriverDocumentService.getDocumentByType iniciado');
  print('  - driverId: $driverId');
  print('  - documentType: $documentType');

  try {
    // Primeiro, tentar buscar em driver_documents
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('driver_id', driverId)
        .eq('document_type', documentType.value)
        .eq('is_current', true)
        .maybeSingle();

    if (response != null) {
      print('✅ Documento encontrado em driver_documents: ${response['id']}');
      return DriverDocument.fromJson(response);
    }

    // Se não encontrou em driver_documents, verificar na tabela drivers como fallback
    print('ℹ️ Documento não encontrado em driver_documents, verificando tabela drivers...');
    final fallbackDocument = await getDocumentFromDriverTable(driverId, documentType);
    
    if (fallbackDocument != null) {
      print('✅ Documento encontrado na tabela drivers (fallback)');
      return fallbackDocument;
    }

    print('ℹ️ Documento não encontrado');
    return null;

  } on PostgrestException catch (e) {
    print('❌ Erro ao buscar documento: ${e.message}');
    throw DocumentException('Erro ao buscar documento: ${e.message}');
  } catch (e) {
    print('❌ Erro inesperado: $e');
    throw DocumentException('Erro inesperado ao buscar documento: $e');
  }
}
```

## 2. Telas

### 2.1. Atualização da Tela de Documentos do Motorista (driver_documents_screen.dart)

#### Modificação na função _buildDocumentTile
```dart
Widget _buildDocumentTile(
  Map<String, dynamic> docType,
  DriverDocument document, {
  bool isMissing = false,
  bool isFallback = false, // Novo parâmetro
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

  // Verificar se é um documento fallback
  if (isFallback) {
    statusColor = AppColors.info;
    statusIcon = Icons.info;
    statusText = 'Enviado no Cadastro';
  } else {
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
  }

  // Restante do código permanece igual...
}
```

#### Nova tela para documentos já enviados no cadastro
```dart
Widget _buildFallbackDocumentTile(
  Map<String, dynamic> docType,
  DriverDocument document,
) {
  final type = docType['type'] as DocumentType;
  final title = docType['title'] as String;
  final description = docType['description'] as String;
  final icon = docType['icon'] as IconData;

  return DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.info.withOpacity(0.3),
        width: 1.0,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDocumentDetail(document, isFallback: true),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.info,
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
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Enviado no Cadastro',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este documento foi enviado durante o cadastro e está aguardando aprovação.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
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
```

### 2.2. Remoção dos Steps de CNH e CRLV do Stepper

#### Atualização do driver_documents_stepper.dart
```dart
class _DriverDocumentsStepperState extends State<DriverDocumentsStepper> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Atualizar as labels para remover CNH e CRLV
  final List<String> _stepLabels = [
    'Foto do Veículo - Frente',
    // Adicionar outros documentos adicionais conforme necessário
  ];

  @override
  Widget build(BuildContext context) {
    // Atualizar o PageView para remover os steps de CNH e CRLV
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: Column(
          children: [
            // Header com progresso
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousStep,
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Documentos Adicionais',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_currentStep + 1} de ${_stepLabels.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearStepperProgressIndicator(
                    currentStep: _currentStep,
                    totalSteps: _stepLabels.length,
                    showLabels: true,
                    stepLabels: _stepLabels,
                  ),
                ],
              ),
            ),
            
            // Conteúdo do stepper - atualizar para mostrar apenas documentos adicionais
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Adicionar os steps para documentos adicionais
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: DocumentType.vehicleFront,
                    onNext: _nextStep,
                    isLoading: _isLoading,
                  ),
                  // Adicionar outros steps conforme necessário
                ],
              ),
            ),
            
            // Mensagem de erro se houver
            if (_error != null)
              Container(
                margin: const EdgeInsets.all(16),
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
          ],
        ),
      ),
    );
  }
}
```

## 3. Componentes

### 3.1. Nova tela de detalhe de documento

Criar uma nova tela para mostrar detalhes de documentos que já foram enviados no cadastro:

```dart
/// Tela para mostrar detalhes de documentos enviados no cadastro
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.isFallback,
  });

  final DriverDocument document;
  final bool isFallback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          _getDocumentTitle(document.documentType),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFallback) ...[
              _buildFallbackInfoCard(),
              const SizedBox(height: 24),
            ],
            
            // Mostrar a imagem do documento
            _buildDocumentImage(document.fileUrl),
            const SizedBox(height: 24),
            
            // Informações do documento
            _buildDocumentInfo(document),
            
            const SizedBox(height: 32),
            
            // Botão Voltar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFallbackInfoCard() {
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documento já enviado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este documento foi enviado durante o cadastro e está aguardando aprovação.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.info.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentImage(String fileUrl) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fileUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Não foi possível carregar a imagem',
                    style: TextStyle(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildDocumentInfo(DriverDocument document) {
    final colors = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do Documento',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        if (document.expiryDate != null) ...[
          _buildInfoRow(
            'Data de Validade',
            _formatDate(document.expiryDate!),
            Icons.calendar_today,
          ),
          const SizedBox(height: 16),
        ],
        
        _buildInfoRow(
          'Status',
          _getStatusText(document.status),
          _getStatusIcon(document.status),
          statusColor: _getStatusColor(document.status),
        ),
        
        const SizedBox(height: 16),
        
        _buildInfoRow(
          'Data de Envio',
          _formatDateTime(document.createdAt),
          Icons.access_time,
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor?.withOpacity(0.1) ?? AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: statusColor ?? AppColors.gray600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? AppColors.lightOnSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getDocumentTitle(String documentType) {
    switch (documentType) {
      case 'CNH_FRONT':
        return 'CNH - Frente';
      case 'CNH_BACK':
        return 'CNH - Verso';
      case 'CRLV':
        return 'CRLV';
      case 'VEHICLE_FRONT':
        return 'Foto do Veículo - Frente';
      default:
        return 'Documento';
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Aguardando Aprovação';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
  
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
      
  String _formatDateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
```

## 4. Integração

### 4.1. Atualização da navegação

Atualizar a função `_navigateToCapture` para lidar com documentos fallback:

```dart
Future<void> _navigateToCapture(DocumentType documentType, {bool isFallback = false}) async {
  // Verificar se é um documento fallback
  if (isFallback) {
    // Buscar o documento fallback
    final fallbackDocument = await DriverDocumentService.getDocumentFromDriverTable(
      _driverId, 
      documentType
    );
    
    if (fallbackDocument != null) {
      // Navegar para a tela de detalhe do documento
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailScreen(
            document: fallbackDocument,
            isFallback: true,
          ),
        ),
      );
    }
    return;
  }
  
  // Restante do código para documentos normais...
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

  if (result ?? false) {
    _loadDocuments();
  }
}
```

## 5. Testes

### 5.1. Testes necessários

1. Verificar que documentos enviados no cadastro aparecem corretamente na tela de documentos
2. Garantir que o status "Enviado no Cadastro" seja exibido corretamente
3. Testar a navegação para a tela de detalhe de documentos fallback
4. Verificar que documentos adicionais ainda podem ser enviados normalmente
5. Testar a funcionalidade de refresh da tela de documentos
6. Garantir que a contagem de documentos aprovados/pendentes esteja correta

## 6. Considerações Finais

Estas mudanças no frontend melhoram significativamente a experiência do usuário ao eliminar a duplicidade de documentos, mantendo a funcionalidade completa do sistema. A implementação mantém compatibilidade com versões anteriores e fornece um feedback claro ao usuário sobre o status de seus documentos.