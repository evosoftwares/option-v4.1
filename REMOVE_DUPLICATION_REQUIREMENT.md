# Remoção da Exigência de Reenviar CNH e CRLV

## 1. Análise do Problema

Atualmente, o fluxo de documentação adicional exige que motoristas reenviem a CNH e CRLV, mesmo que já tenham sido enviados durante o cadastro. Isso cria fricção na experiência do usuário.

## 2. Solução Proposta

Remover a exigência de reenviar documentos já enviados na tabela `drivers`, considerando-os como válidos para fins de documentação completa.

## 3. Atualizações Necessárias

### 3.1. Atualização do DriverDocumentService

#### 3.1.1. Atualizar getDocumentationStatus para considerar documentos da tabela drivers

```dart
/// Verifica se um motorista tem todos os documentos obrigatórios
/// Considera documentos da tabela drivers como válidos
static Future<Map<String, dynamic>> getDocumentationStatus(String driverId) async {
  print('🔄 DriverDocumentService.getDocumentationStatus iniciado');
  print('  - driverId: $driverId');

  try {
    // Buscar documentos da tabela driver_documents
    final documents = await getCurrentDriverDocuments(driverId);
    print('📋 Documentos encontrados em driver_documents: ${documents.length}');
    
    // Buscar dados do driver para verificar documentos na tabela drivers
    final driverResponse = await _supabase
        .from('drivers')
        .select('cnh_photo_url, crlv_photo_url, created_at')
        .eq('id', driverId)
        .single();
    
    final cnhPhotoUrl = driverResponse['cnh_photo_url'] as String?;
    final crlvPhotoUrl = driverResponse['crlv_photo_url'] as String?;
    final driverCreatedAt = DateTime.parse(driverResponse['created_at'] as String);
    
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
                createdAt: driverCreatedAt,
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
                createdAt: driverCreatedAt,
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

### 3.2. Atualização da Tela de Documentos

#### 3.2.1. Atualizar _buildDocumentsList para refletir documentos da tabela drivers

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

### 3.3. Atualização do Stepper de Documentos

Se houver um stepper para documentos adicionais, ele também precisa ser atualizado para remover CNH e CRLV:

#### 3.3.1. Verificar se há stepper de documentos

```dart
// Se existir um stepper de documentos, atualizar para remover CNH e CRLV
// Exemplo de atualização:
final List<String> _stepLabels = [
  'Foto do Veículo - Frente',
  // Remover 'CNH Frente', 'CNH Verso', 'CRLV'
  // Adicionar outros documentos adicionais conforme necessário
];
```

## 4. Testes Necessários

1. **Verificar que documentos enviados no cadastro são reconhecidos**
2. **Garantir que o status "Documentação Completa" apareça corretamente**
3. **Testar o fluxo com documentos parcialmente enviados**
4. **Verificar que documentos rejeitados ainda exigem reenvio**
5. **Testar a navegação para documentos fallback**

## 5. Benefícios

1. **Eliminação da Duplicidade**: Motoristas não precisam enviar os mesmos documentos duas vezes
2. **Melhoria da UX**: Experiência mais fluida e intuitiva
3. **Redução de Fricção**: Menos passos no processo de documentação
4. **Compatibilidade**: Mantém funcionalidade com documentos existentes
5. **Feedback Visual**: Interface clara sobre status dos documentos

Essas atualizações resolverão completamente o problema da duplicidade de documentos, melhorando significativamente a experiência do usuário.