import 'package:flutter/material.dart';
import '../../models/supabase/driver_document.dart';
import '../../services/driver_document_service.dart';
import '../../widgets/stepper_progress_indicator.dart';
import 'driver_vehicle_photo_step.dart';

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

  // Atualizar as labels para incluir apenas documentos do veículo
  final List<String> _stepLabels = [
    'Foto do Veículo - Frente',
    'Foto do Veículo - Trás',
    'Foto do Veículo - Esquerda',
    'Foto do Veículo - Direita',
    'Interior do Veículo',
  ];

  // Tipos de documentos do veículo correspondentes
  final List<DocumentType> _documentTypes = [
    DocumentType.vehicleFront,
    DocumentType.vehicleBack,
    DocumentType.vehicleLeft,
    DocumentType.vehicleRight,
    DocumentType.vehicleInterior,
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
                          'Documentos Obrigatórios',
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
            
            // Conteúdo do stepper - atualizado para mostrar apenas documentos do veículo
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Steps de fotos do veículo
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: _documentTypes[0],
                    onNext: _nextStep,
                    isLoading: _isLoading,
                  ),
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: _documentTypes[1],
                    onNext: _nextStep,
                    isLoading: _isLoading,
                  ),
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: _documentTypes[2],
                    onNext: _nextStep,
                    isLoading: _isLoading,
                  ),
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: _documentTypes[3],
                    onNext: _nextStep,
                    isLoading: _isLoading,
                  ),
                  DriverVehiclePhotoStep(
                    driverId: widget.driverId,
                    documentType: _documentTypes[4],
                    onNext: _completeDocumentation,
                    isLoading: _isLoading,
                  ),
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