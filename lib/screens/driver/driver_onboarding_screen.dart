import 'package:flutter/material.dart';

import '../../services/driver_document_service.dart';
import '../../theme/app_colors.dart';
import '../stepper/driver_documents_stepper.dart';

/// Tela de onboarding para motoristas - valida documentação antes de permitir acesso completo
class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({
    super.key,
    required this.driverId,
  });

  final String driverId;

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _documentationStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkDocumentationStatus();
  }

  Future<void> _checkDocumentationStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await DriverDocumentService.getDocumentationStatus(widget.driverId);
      setState(() {
        _documentationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao verificar documentação: $e';
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _checkDocumentationStatus,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _documentationStatus!;
    final isComplete = status['isComplete'] as bool;

    if (isComplete) {
      // Documentação aprovada - permitir acesso ao app
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: colors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Documentação Aprovada!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Parabéns! Seus documentos foram aprovados e você já pode começar a receber corridas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      // Navegar para tela principal do motorista
                      Navigator.of(context).pushReplacementNamed('/driver-home');
                    },
                    child: const Text(
                      'Começar a Dirigir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Documentação incompleta - mostrar status e permitir upload
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Documentação Obrigatória',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para começar a receber corridas, você precisa enviar e aprovar alguns documentos.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: _buildDocumentationStatus(status, colors),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startDocumentationProcess,
                  child: const Text(
                    'Enviar Documentos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildStatusSection(
    String title,
    List<String> documents,
    Color color,
    IconData icon,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...documents.map((doc) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            '• ${_getDocumentDisplayName(doc)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )),
      ],
    );

  String _getDocumentDisplayName(String docType) {
    switch (docType) {
      case 'cnhFront':
        return 'CNH - Frente';
      case 'cnhBack':
        return 'CNH - Verso';
      case 'crlv':
        return 'CRLV';
      case 'vehicleFront':
        return 'Foto do Veículo - Frente';
      default:
        return docType;
    }
  }
}