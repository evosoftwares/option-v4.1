import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';
import '../../services/driver_document_service.dart';
import '../../models/supabase/driver.dart';
import '../../models/supabase/driver_document.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

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
      if (user == null) return;

      // Buscar dados do motorista
      // Assumindo que existe um método para buscar driver por user_id
      // _driver = await DriverService.getDriverByUserId(user.id);

      // Buscar documentos do motorista
      if (_driver != null) {
        _documents =
            await DriverDocumentService.getDriverDocuments(_driver!.id);
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do motorista: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await _loadDriverData();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Status da Aprovação'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Aguardando Aprovação'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshStatus,
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card Principal
              _buildStatusCard(context),

              SizedBox(height: AppSpacing.lg),

              // Processo de Aprovação
              _buildApprovalProcessCard(context),

              SizedBox(height: AppSpacing.lg),

              // Documentos Enviados
              _buildDocumentsCard(context),

              SizedBox(height: AppSpacing.lg),

              // Próximos Passos
              _buildNextStepsCard(context),

              SizedBox(height: AppSpacing.lg),

              // Contato e Suporte
              _buildSupportCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: AppSpacing.paddingLg,
      child: Column(
        children: [
          // Ícone de status
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top,
              size: 40,
              color: Colors.orange[700],
            ),
          ),

          SizedBox(height: AppSpacing.md),

          Text(
            'Cadastro Realizado com Sucesso! 🎉',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Sua solicitação para se tornar motorista parceiro foi recebida e está sendo analisada por nossa equipe.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppSpacing.lg),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: Colors.orange[700],
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Status: Aguardando Aprovação',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
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

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Processo de Aprovação',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
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
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Tempo estimado: 1-3 dias úteis',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Você será notificado assim que a análise for concluída',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
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
    if (isCompleted) stepColor = Colors.green;
    if (isActive) stepColor = Colors.orange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : isActive
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Center(
                          child: Text(
                            '$step',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: Colors.grey[300],
                margin: EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isActive
                      ? colorScheme.onSurface
                      : Colors.grey[600],
                ),
              ),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Documentos Enviados',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildDocumentItem(
            context,
            title: 'CNH (Carteira de Motorista)',
            status: 'Enviado',
            icon: Icons.badge,
            statusColor: Colors.green,
          ),
          _buildDocumentItem(
            context,
            title: 'CRLV (Documento do Veículo)',
            status: 'Enviado',
            icon: Icons.directions_car,
            statusColor: Colors.green,
          ),
          _buildDocumentItem(
            context,
            title: 'Informações do Veículo',
            status: 'Completo',
            icon: Icons.info,
            statusColor: Colors.blue,
          ),
          SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/driver_documents');
            },
            child: Text('Ver/Atualizar Documentos'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    required Color statusColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
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

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Próximos Passos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildNextStep(
            context,
            icon: Icons.notifications,
            title: 'Aguarde a notificação',
            description:
                'Você receberá uma notificação push quando a aprovação for concluída.',
          ),
          _buildNextStep(
            context,
            icon: Icons.email,
            title: 'Verifique seu e-mail',
            description:
                'Também enviaremos um e-mail com o resultado da análise.',
          ),
          _buildNextStep(
            context,
            icon: Icons.drive_eta,
            title: 'Comece a dirigir',
            description:
                'Após aprovação, você poderá ficar online e receber corridas.',
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
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Precisa de Ajuda?',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Nossa equipe está aqui para ajudar durante o processo de aprovação.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Implementar contato por WhatsApp
                  },
                  icon: Icon(Icons.message, size: 18),
                  label: Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Implementar contato por e-mail
                  },
                  icon: Icon(Icons.email, size: 18),
                  label: Text('E-mail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
