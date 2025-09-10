import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/user_service.dart';
import '../../services/driver_service.dart';
import '../../services/driver_document_service.dart';
import '../../models/supabase/driver.dart';
import '../../models/supabase/driver_document.dart';
import '../../theme/app_spacing.dart';
import '../../utils/supabase_helper.dart';

class DriverApprovalPendingScreen extends StatefulWidget {
  const DriverApprovalPendingScreen({super.key});

  @override
  State<DriverApprovalPendingScreen> createState() =>
      _DriverApprovalPendingScreenState();
}

class _DriverApprovalPendingScreenState
    extends State<DriverApprovalPendingScreen> {
  Driver? _driver;
  List<DriverDocument> _documents = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      setState(() => _isLoading = true);

      final user = await UserService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário não encontrado. Faça login novamente.'),
            ),
          );
        }
        return;
      }

      final supabaseClient = SupabaseHelper.client;
      if (supabaseClient == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro de conexão. Tente novamente.'),
            ),
          );
        }
        return;
      }

      // Buscar dados do motorista
      final driverService = DriverService(supabaseClient);
      _driver = await driverService.getDriverByUserId(user.id);

      if (_driver == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados do motorista não encontrados. Complete seu cadastro primeiro.'),
            ),
          );
          // Redirecionar para o cadastro do motorista se necessário
          Navigator.of(context).pushReplacementNamed('/driver_stepper');
        }
        return;
      }

      // Buscar documentos do motorista
      try {
        _documents =
            await DriverDocumentService.getCurrentDriverDocuments(_driver!.id);
      } catch (e) {
        print('❌ Erro ao carregar documentos: $e');
        // Não é crítico se não conseguir carregar documentos
        _documents = [];
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do motorista: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await _loadDriverData();
    setState(() => _isRefreshing = false);
  }

  Future<void> _openWhatsAppSupport() async {
    const phoneNumber = '556599776524';
    const message = 'Olá! Preciso de ajuda com o processo de aprovação do motorista.';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp. Verifique se o app está instalado.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Status da Aprovação'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aguardando Aprovação',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              onPressed: _isRefreshing ? null : _refreshStatus,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // Status Card Principal
              _buildStatusCard(context),

              const SizedBox(height: AppSpacing.xl),

              // Processo de Aprovação
              _buildApprovalProcessCard(context),

              const SizedBox(height: AppSpacing.xl),

              // Documentos Enviados
              _buildDocumentsCard(context),

              const SizedBox(height: AppSpacing.xl),

              // Próximos Passos
              _buildNextStepsCard(context),

              const SizedBox(height: AppSpacing.xl),

              // Contato e Suporte
              _buildSupportCard(context),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[25] ?? Colors.blue[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone de status modernizado
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[600]!,
                  Colors.blue[800]!,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Cadastro Realizado! 🎉',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Sua solicitação foi recebida e está sendo\nanalisada por nossa equipe.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue[500],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Aguardando Aprovação',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalProcessCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Processo de Aprovação',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildProcessStep(
            context,
            step: 1,
            title: 'Cadastro Realizado',
            description: 'Informações e documentos enviados',
            isCompleted: true,
          ),
          _buildProcessStep(
            context,
            step: 2,
            title: 'Análise de Documentos',
            description: 'Verificação da autenticidade e validade',
            isCompleted: false,
            isActive: true,
          ),
          _buildProcessStep(
            context,
            step: 3,
            title: 'Aprovação Final',
            description: 'Liberação para começar a trabalhar',
            isCompleted: false,
            isLast: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.blue[25] ?? Colors.blue[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tempo estimado: 1-3 dias úteis',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Você será notificado assim que a análise for concluída',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    required bool isCompleted,
    bool isActive = false,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color stepColor = Colors.grey[400]!;
    Color bgColor = Colors.grey[50]!;
    if (isCompleted) {
      stepColor = Colors.blue[600]!;
      bgColor = Colors.blue[50]!;
    }
    if (isActive) {
      stepColor = Colors.black87;
      bgColor = Colors.grey[100]!;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 2),
                ),
                child: isCompleted
                    ? Icon(Icons.check_rounded, size: 18, color: stepColor)
                    : isActive
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: stepColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Center(
                            child: Text(
                              '$step',
                              style: TextStyle(
                                color: stepColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.blue[200] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Documentos Enviados',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_documents.isNotEmpty) ...[
            ..._buildDocumentItems(context),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.description_outlined, 
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nenhum documento enviado',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Complete o envio dos seus documentos',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pushNamed('/driver_documents');
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ver/Atualizar Documentos',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentItems(BuildContext context) {
    final documentMap = <String, DriverDocument>{};
    
    // Agrupar documentos por tipo (pegar apenas o mais recente de cada tipo)
    for (final doc in _documents) {
      documentMap[doc.documentType] = doc;
    }

    final List<Widget> items = [];

    // CNH (verificar se tem frente ou verso)
    final hasCnhFront = documentMap.containsKey('CNH_FRONT');
    final hasCnhBack = documentMap.containsKey('CNH_BACK');
    if (hasCnhFront || hasCnhBack) {
      final cnhDoc = hasCnhFront ? documentMap['CNH_FRONT'] : documentMap['CNH_BACK'];
      items.add(_buildDocumentItem(
        context,
        title: 'CNH (Carteira de Motorista)',
        status: _getStatusText(cnhDoc!.status),
        icon: Icons.badge,
        statusColor: _getStatusColor(cnhDoc.status),
      ));
    }

    // CRLV
    final crlvDoc = documentMap['CRLV'];
    if (crlvDoc != null) {
      items.add(_buildDocumentItem(
        context,
        title: 'CRLV (Documento do Veículo)',
        status: _getStatusText(crlvDoc.status),
        icon: Icons.directions_car,
        statusColor: _getStatusColor(crlvDoc.status),
      ));
    }

    // Fotos do Veículo
    final hasVehiclePhotos = documentMap.keys.any((key) => key.startsWith('VEHICLE_'));
    if (hasVehiclePhotos) {
      final vehicleDoc = documentMap.values.firstWhere((doc) => doc.documentType.startsWith('VEHICLE_'));
      items.add(_buildDocumentItem(
        context,
        title: 'Fotos do Veículo',
        status: _getStatusText(vehicleDoc.status),
        icon: Icons.camera_alt,
        statusColor: _getStatusColor(vehicleDoc.status),
      ));
    }

    return items;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pendente';
      case 'APPROVED':
        return 'Aprovado';
      case 'REJECTED':
        return 'Rejeitado';
      case 'EXPIRED':
        return 'Expirado';
      default:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.blue[600]!;
      case 'APPROVED':
        return Colors.black87;
      case 'REJECTED':
        return Colors.grey[600]!;
      case 'EXPIRED':
        return Colors.grey[400]!;
      default:
        return Colors.grey[500]!;
    }
  }

  Widget _buildDocumentItem(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    required Color statusColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: statusColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              status,
              style: textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[100]!,
                      Colors.blue[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Próximos Passos',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildNextStep(
            context,
            icon: Icons.notifications_rounded,
            title: 'Aguarde a notificação',
            description:
                'Você receberá uma notificação push quando a aprovação for concluída.',
            bgColor: Colors.grey[100]!,
            iconColor: Colors.black87,
          ),
          _buildNextStep(
            context,
            icon: Icons.chat_bubble_rounded,
            title: 'Contato via WhatsApp',
            description:
                'Entre em contato conosco pelo WhatsApp se tiver dúvidas durante o processo.',
            bgColor: Colors.blue[50]!,
            iconColor: Colors.blue[600]!,
          ),
          _buildNextStep(
            context,
            icon: Icons.drive_eta_rounded,
            title: 'Comece a dirigir',
            description:
                'Após aprovação, você poderá ficar online e receber corridas.',
            bgColor: Colors.grey[50]!,
            iconColor: Colors.black87,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    Color? bgColor,
    Color? iconColor,
    bool isLast = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor ?? Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.blue[600],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[25] ?? Colors.blue[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[800]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Precisa de Ajuda?',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nossa equipe está aqui para ajudar durante todo o processo de aprovação.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openWhatsAppSupport,
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: Text(
                'Falar conosco',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
