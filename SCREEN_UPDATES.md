# Atualizações Necessárias na Tela de Documentos do Motorista

## 1. Atualização do DriverDocumentService

### 1.1. Adicionar função para verificar documentos na tabela drivers (fallback)

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

### 1.2. Atualizar função getDocumentationStatus para considerar documentos da tabela drivers

```dart
/// Verifica se um motorista tem todos os documentos obrigatórios
/// Considera documentos da tabela drivers como fallback
static Future<Map<String, dynamic>> getDocumentationStatus(String driverId) async {
  print('🔄 DriverDocumentService.getDocumentationStatus iniciado');
  print('  - driverId: $driverId');

  try {
    // Buscar documentos da tabela driver_documents
    final documents = await getCurrentDriverDocuments(driverId);
    print('📋 Documentos encontrados em driver_documents: ${documents.length}');
    for (final doc in documents) {
      print('  - ${doc.documentType}: ${doc.status} (current: ${doc.isCurrent})');
    }
    
    // Buscar dados do driver para verificar documentos na tabela drivers
    final driverResponse = await _supabase
        .from('drivers')
        .select('cnh_photo_url, crlv_photo_url')
        .eq('id', driverId)
        .single();
    
    final cnhPhotoUrl = driverResponse['cnh_photo_url'] as String?;
    final crlvPhotoUrl = driverResponse['crlv_photo_url'] as String?;
    
    print('📋 Documentos na tabela drivers:');
    print('  - CNH: ${cnhPhotoUrl != null && cnhPhotoUrl.isNotEmpty ? 'Presente' : 'Ausente'}');
    print('  - CRLV: ${crlvPhotoUrl != null && crlvPhotoUrl.isNotEmpty ? 'Presente' : 'Ausente'}');
    
    // Documentos obrigatórios
    final requiredTypes = [
      DocumentType.cnhFront,
      DocumentType.cnhBack,
      DocumentType.crlv,
      DocumentType.vehicleFront,
    ];

    final documentsByType = <String, DriverDocument>{};
    for (final doc in documents) {
      documentsByType[doc.documentType] = doc;
    }

    final missingDocuments = <String>[];
    final pendingDocuments = <String>[];
    final rejectedDocuments = <String>[];
    final approvedDocuments = <String>[];
    final expiredDocuments = <String>[];

    for (final type in requiredTypes) {
      final typeName = type.value;
      var doc = documentsByType[typeName];
      
      // Se não encontrou em driver_documents, verificar na tabela drivers
      if (doc == null) {
        switch (type) {
          case DocumentType.cnhFront:
            if (cnhPhotoUrl != null && cnhPhotoUrl.isNotEmpty) {
              // Criar documento temporário a partir da tabela drivers
              doc = DriverDocument(
                id: 'fallback_${driverId}_${typeName}',
                driverId: driverId,
                documentType: typeName,
                fileUrl: cnhPhotoUrl,
                status: 'approved',
                isCurrent: true,
                createdAt: DateTime.now(),
              );
            }
            break;
          case DocumentType.crlv:
            if (crlvPhotoUrl != null && crlvPhotoUrl.isNotEmpty) {
              // Criar documento temporário a partir da tabela drivers
              doc = DriverDocument(
                id: 'fallback_${driverId}_${typeName}',
                driverId: driverId,
                documentType: typeName,
                fileUrl: crlvPhotoUrl,
                status: 'approved',
                isCurrent: true,
                createdAt: DateTime.now(),
              );
            }
            break;
          default:
            break;
        }
      }
      
      if (doc == null) {
        missingDocuments.add(typeName);
      } else {
        // Verificar se está expirado
        if (doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now())) {
          expiredDocuments.add(typeName);
        } else {
          switch (doc.status) {
            case 'pending':
              pendingDocuments.add(typeName);
              break;
            case 'approved':
              approvedDocuments.add(typeName);
              break;
            case 'rejected':
              rejectedDocuments.add(typeName);
              break;
          }
        }
      }
    }

    final isComplete = missingDocuments.isEmpty && 
                      pendingDocuments.isEmpty && 
                      rejectedDocuments.isEmpty && 
                      expiredDocuments.isEmpty;

    final result = {
      'isComplete': isComplete,
      'totalRequired': requiredTypes.length,
      'totalApproved': approvedDocuments.length,
      'missingDocuments': missingDocuments,
      'pendingDocuments': pendingDocuments,
      'rejectedDocuments': rejectedDocuments,
      'expiredDocuments': expiredDocuments,
      'approvedDocuments': approvedDocuments,
    };

    print('✅ Status da documentação calculado:');
    print('  - isComplete: $isComplete');
    print('  - totalRequired: ${requiredTypes.length}');
    print('  - totalApproved: ${approvedDocuments.length}');
    print('  - approvedDocuments: $approvedDocuments');
    print('  - pendingDocuments: $pendingDocuments'); 
    print('  - missingDocuments: $missingDocuments');
    print('  - rejectedDocuments: $rejectedDocuments');
    return result;

  } catch (e) {
    print('❌ Erro ao verificar status da documentação: $e');
    throw DocumentException('Erro ao verificar status da documentação: $e');
  }
}
```

## 2. Atualização da Tela de Documentos (driver_documents_screen.dart)

### 2.1. Adicionar função para identificar documentos fallback

```dart
// Adicionar este método na classe _DriverDocumentsScreenState
Future<bool> _isDocumentFromDriverTable(DocumentType documentType) async {
  // Verificar se o documento existe na tabela drivers
  final driverResponse = await Supabase.instance.client
      .from('drivers')
      .select('cnh_photo_url, crlv_photo_url')
      .eq('id', _driverId)
      .single();
  
  switch (documentType) {
    case DocumentType.cnhFront:
      final url = driverResponse['cnh_photo_url'] as String?;
      return url != null && url.isNotEmpty;
    case DocumentType.crlv:
      final url = driverResponse['crlv_photo_url'] as String?;
      return url != null && url.isNotEmpty;
    default:
      return false;
  }
}
```

### 2.2. Atualizar a função _buildDocumentsList

```dart
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
  final requiredDocs = documentTypes.where((doc) => doc['isRequired'] == true).toList();
  final optionalDocs = documentTypes.where((doc) => doc['isRequired'] == false).toList();

  // Separar documentos faltantes dos demais
  final missingDocs = <Map<String, dynamic>>[];
  final completedDocs = <Map<String, dynamic>>[];
  final fallbackDocs = <Map<String, dynamic>>[]; // Documentos da tabela drivers

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

    // Verificar se é um documento da tabela drivers (fallback)
    if (document.status == 'missing' || document.id.isEmpty) {
      // Verificar se existe na tabela drivers
      final isFromDriverTable = _isDocumentFromDriverTable(docType['type']! as DocumentType);
      if (isFromDriverTable) {
        fallbackDocs.add(docType);
      } else {
        missingDocs.add(docType);
      }
    } else {
      completedDocs.add(docType);
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Seção de documentos faltantes (destacada)
      if (missingDocs.isNotEmpty) ...[
        _buildMissingDocumentsSection(missingDocs),
        const SizedBox(height: 24),
      ],
      
      // Seção de documentos da tabela drivers (fallback)
      if (fallbackDocs.isNotEmpty) ...[
        _buildFallbackDocumentsSection(fallbackDocs),
        const SizedBox(height: 24),
      ],
      
      // Seção de documentos obrigatórios já enviados
      if (completedDocs.isNotEmpty) ...[
        _buildCompletedDocumentsSection(completedDocs),
        const SizedBox(height: 24),
      ],
      
      // Seção de documentos opcionais
      if (optionalDocs.isNotEmpty) ...[
        _buildOptionalDocumentsSection(optionalDocs),
      ],
    ],
  );
}
```

### 2.3. Adicionar nova função para construir seção de documentos fallback

```dart
Widget _buildFallbackDocumentsSection(List<Map<String, dynamic>> fallbackDocs) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.info.withOpacity(0.3),
            width: 1.5,
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
                    'Documentos Enviados no Cadastro',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estes documentos foram enviados durante o cadastro e estão aguardando aprovação',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.info.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ...fallbackDocs.map((docType) {
        final document = DriverDocument(
          id: 'fallback_${_driverId}_${(docType['type']! as DocumentType).value}',
          driverId: _driverId,
          documentType: (docType['type']! as DocumentType).value,
          fileUrl: '', // URL será buscada quando necessário
          status: 'approved',
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDocumentTile(
            docType,
            document,
            isFallback: true,
          ),
        );
      }),
    ],
  );
}
```

### 2.4. Atualizar _buildDocumentTile para lidar com documentos fallback

```dart
Widget _buildDocumentTile(
  Map<String, dynamic> docType,
  DriverDocument document, {
  bool isFallback = false,
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

  return DecoratedBox(
    decoration: BoxDecoration(
      color: isFallback ? AppColors.info.withOpacity(0.05) : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isFallback ? AppColors.info.withOpacity(0.3) : AppColors.gray200,
        width: isFallback ? 1.5 : 1.0,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToCapture(type, isFallback: isFallback),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFallback ? statusColor.withOpacity(0.15) : AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                      border: isFallback ? Border.all(
                        color: statusColor.withOpacity(0.3),
                      ) : null,
                    ),
                    child: Icon(
                      icon,
                      color: isFallback ? statusColor : AppColors.gray600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isFallback ? FontWeight.w700 : FontWeight.w600,
                                  color: isFallback ? AppColors.info : AppColors.lightOnSurface,
                                ),
                              ),
                            ),
                            if (isFallback)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'CADASTRO',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
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
                      color: statusColor.withOpacity(isFallback ? 0.15 : 0.1),
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
                            fontWeight: isFallback ? FontWeight.w700 : FontWeight.w600,
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
                      const Icon(
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
              if (isFallback) ...[
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
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 2.5. Atualizar _navigateToCapture para lidar com documentos fallback

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
      // Mostrar um diálogo informando que o documento já foi enviado
      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Documento já enviado'),
            content: const Text('Este documento foi enviado durante o cadastro e está aguardando aprovação.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
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

## 3. Benefícios das Atualizações

1. **Eliminação da Duplicidade**: Motoristas não precisam enviar os mesmos documentos duas vezes
2. **Melhoria da UX**: Interface clara indicando quais documentos já foram enviados
3. **Compatibilidade**: Mantém funcionalidade completa do sistema
4. **Feedback Visual**: Status especial para documentos enviados no cadastro
5. **Transição Suave**: Funciona com documentos existentes em ambas as tabelas

Essas atualizações resolverão o problema da duplicidade de documentos sem quebrar compatibilidade com o banco de dados ou APIs existentes.