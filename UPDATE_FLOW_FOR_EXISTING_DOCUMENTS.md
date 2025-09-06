# Atualização do Fluxo para Considerar Documentos Enviados no Cadastro

## 1. Visão Geral

Atualizar o fluxo de documentação para considerar documentos CNH e CRLV já enviados durante o cadastro como válidos, eliminando a necessidade de reenvio.

## 2. Atualizações Necessárias

### 2.1. Atualizar DriverDocumentService

#### 2.1.1. Atualizar getDocumentationStatus

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
    
    // Documentos obrigatórios (incluindo os que podem vir da tabela drivers)
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
          case DocumentType.cnhBack:
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

### 2.2. Atualizar DriverOnboardingScreen

#### 2.2.1. Atualizar _startDocumentationProcess

```dart
void _startDocumentationProcess() {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => DriverDocumentsStepper(
        driverId: widget.driverId,
        onCompleted: _checkDocumentationStatus,
      ),
    ),
  );
}
```

#### 2.2.2. Atualizar _buildDocumentationStatus

```dart
Widget _buildDocumentationStatus(Map<String, dynamic> status, ColorScheme colors) {
  final missingDocs = status['missingDocuments'] as List;
  final pendingDocs = status['pendingDocuments'] as List;
  final rejectedDocs = status['rejectedDocuments'] as List;
  final approvedDocs = status['approvedDocuments'] as List;
  final expiredDocs = status['expiredDocuments'] as List;

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Documentos aprovados
        if (approvedDocs.isNotEmpty) ...[
          _buildStatusSection(
            'Aprovados',
            approvedDocs.cast<String>(),
            AppColors.success,
            Icons.check_circle,
          ),
          const SizedBox(height: 16),
        ],
        
        // Documentos pendentes
        if (pendingDocs.isNotEmpty) ...[
          _buildStatusSection(
            'Aguardando Aprovação',
            pendingDocs.cast<String>(),
            colors.primary,
            Icons.schedule,
          ),
          const SizedBox(height: 16),
        ],
        
        // Documentos rejeitados
        if (rejectedDocs.isNotEmpty) ...[
          _buildStatusSection(
            'Rejeitados',
            rejectedDocs.cast<String>(),
            colors.error,
            Icons.error,
          ),
          const SizedBox(height: 16),
        ],
        
        // Documentos expirados
        if (expiredDocs.isNotEmpty) ...[
          _buildStatusSection(
            'Expirados',
            expiredDocs.cast<String>(),
            colors.error,
            Icons.event_busy,
          ),
          const SizedBox(height: 16),
        ],
        
        // Documentos faltantes
        if (missingDocs.isNotEmpty) ...[
          _buildStatusSection(
            'Não Enviados',
            missingDocs.cast<String>(),
            colors.onSurfaceVariant,
            Icons.upload_file,
          ),
        ],
      ],
    ),
  );
}
```

### 2.3. Atualizar DriverDocumentsStepper

#### 2.3.1. Atualizar para mostrar apenas documentos adicionais

```dart
/// Stepper para documentos obrigatórios do motorista
class DriverDocumentsStepper extends StatefulWidget {
  const DriverDocumentsStepper({
    super.key,
    required this.driverId,
    this.onCompleted,
  });

  final String driverId;
  final VoidCallback? onCompleted;

  @override
  State<DriverDocumentsStepper> createState() => _DriverDocumentsStepperState();
}

class _DriverDocumentsStepperState extends State<DriverDocumentsStepper> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Atualizar as labels para mostrar apenas documentos adicionais
  final List<String> _stepLabels = [
    'Foto do Veículo - Frente',
    // Adicionar outros documentos adicionais conforme necessário
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepLabels.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeDocumentation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeDocumentation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Verificar se todos os documentos foram enviados
      final status = await DriverDocumentService.getDocumentationStatus(widget.driverId);
      
      if (status['missingDocuments'].isNotEmpty) {
        setState(() {
          _error = 'Alguns documentos ainda não foram enviados';
          _isLoading = false;
        });
        return;
      }

      // Documentos enviados, aguardando aprovação

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documentos enviados com sucesso! Aguarde a aprovação.'),
            backgroundColor: colors.primary,
          ),
        );
        
        widget.onCompleted?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao finalizar documentação: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
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
            
            // Conteúdo do stepper - mostrar apenas documentos adicionais
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Adicionar steps para documentos adicionais
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: DocumentType.vehicleFront,
                    onNext: _completeDocumentation,
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

### 2.4. Atualizar DriverService

#### 2.4.1. Atualizar verificação de documentação

```dart
// Validação obrigatória: verificar documentos antes de ficar online
if (isOnline ?? false) {
  final documentationStatus = await DriverDocumentService.getDocumentationStatus(driverId);
  
  // Verificar se os documentos obrigatórios estão presentes
  // Considerar CNH e CRLV como válidos se existirem na tabela drivers
  final missingDocs = documentationStatus['missingDocuments'] as List;
  
  if (missingDocs.isNotEmpty) {
    final driverResponse = await _supabase
        .from('drivers')
        .select('cnh_photo_url, crlv_photo_url')
        .eq('id', driverId)
        .single();
    
    final cnhPhotoUrl = driverResponse['cnh_photo_url'] as String?;
    final crlvPhotoUrl = driverResponse['crlv_photo_url'] as String?;
    
    // Remover CNH e CRLV da lista de documentos faltantes se existirem na tabela drivers
    final docsActuallyMissing = missingDocs.where((doc) {
      if ((doc == 'cnhFront' || doc == 'cnhBack') && 
          cnhPhotoUrl != null && cnhPhotoUrl.isNotEmpty) {
        return false;
      }
      if (doc == 'crlv' && crlvPhotoUrl != null && crlvPhotoUrl.isNotEmpty) {
        return false;
      }
      return true;
    }).toList();
    
    if (docsActuallyMissing.isNotEmpty) {
      var errorMessage = 'Não é possível ficar online. ';
      errorMessage += 'Documentos não enviados: ${docsActuallyMissing.join(', ')}. ';
      
      throw DocumentationRequiredException(errorMessage.trim());
    }
  }
}
```

## 3. Testes Necessários

1. **Verificar que documentos enviados no cadastro são reconhecidos como válidos**
2. **Garantir que o status "Documentação Completa" apareça corretamente**
3. **Testar o fluxo com documentos parcialmente enviados**
4. **Verificar que documentos rejeitados ainda exigem reenvio**
5. **Testar a navegação para documentos fallback**
6. **Verificar que motoristas podem ficar online com documentos do cadastro**

## 4. Benefícios

1. **Eliminação da Duplicidade**: Motoristas não precisam enviar os mesmos documentos duas vezes
2. **Melhoria da UX**: Experiência mais fluida e intuitiva
3. **Redução de Fricção**: Menos passos no processo de documentação
4. **Compatibilidade**: Mantém funcionalidade com documentos existentes
5. **Feedback Visual**: Interface clara sobre status dos documentos

Essas atualizações resolverão completamente o problema da duplicidade de documentos, melhorando significativamente a experiência do usuário.