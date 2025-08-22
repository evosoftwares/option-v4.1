import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/logo_branding.dart';
import '../../services/promo_code_service.dart';
import '../../services/passenger_promo_service.dart';
import '../../services/user_service.dart';
import '../../models/supabase/promo_code.dart';
import '../../models/passenger_promo_code.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen>
    with TickerProviderStateMixin {
  final PromoCodeService _promoCodeService = PromoCodeService();
  final PassengerPromoService _passengerPromoService = PassengerPromoService();
  final TextEditingController _codeController = TextEditingController();
  
  late TabController _tabController;
  
  List<PromoCode> _availablePromoCodes = [];
  List<PassengerPromoCode> _passengerPromoCodes = [];
  bool _isLoading = true;
  bool _isValidating = false;
  String? _error;
  String? _validationMessage;
  bool _isValidationSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPromoCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPromoCodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      // Carregar códigos promocionais gerais disponíveis
      final availableCodes = await _promoCodeService.getAvailablePromoCodesForUser(
        userId: user.id,
        tripValue: 50.0, // Valor padrão para verificação
        isFirstTrip: false, // TODO: Verificar se é primeira viagem
      );

      // Carregar códigos promocionais específicos do passageiro
      final passengerCodes = await _passengerPromoService.getAvailablePromoCodes(user.id);

      setState(() {
        _availablePromoCodes = availableCodes;
        _passengerPromoCodes = passengerCodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _validatePromoCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _validationMessage = 'Digite um código promocional';
        _isValidationSuccess = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      // Primeiro, tentar validar como código geral
      final isValidGeneral = await _promoCodeService.validatePromoCodeForTrip(
        code: code,
        userId: user.id,
        tripValue: 50.0, // Valor padrão para validação
        isFirstTrip: false,
      );

      if (isValidGeneral) {
        final promoCode = await _promoCodeService.getPromoCodeByCode(code);
        if (promoCode != null) {
          setState(() {
            _validationMessage = 'Código válido! ${promoCode.displayDescription}';
            _isValidationSuccess = true;
          });
          _codeController.clear();
          await _loadPromoCodes(); // Recarregar lista
          return;
        }
      }

      // Se não for código geral, tentar validar como código de passageiro
      final passengerPromo = await _passengerPromoService.validatePromoCode(code, user.id);
      if (passengerPromo != null) {
        setState(() {
          _validationMessage = 'Código válido e adicionado à sua conta!';
          _isValidationSuccess = true;
        });
        _codeController.clear();
        await _loadPromoCodes(); // Recarregar lista
      } else {
        setState(() {
          _validationMessage = 'Código inválido ou expirado';
          _isValidationSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _validationMessage = 'Erro ao validar código: ${e.toString()}';
        _isValidationSuccess = false;
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Códigos Promocionais'),
      body: Column(
        children: [
          // Seção de inserir código
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inserir código promocional',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'Digite o código',
                          prefixIcon: Icon(
                            Icons.local_offer_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          suffixIcon: _isValidating
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _validatePromoCode(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton(
                      onPressed: _isValidating ? null : _validatePromoCode,
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
                if (_validationMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: _isValidationSuccess
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isValidationSuccess
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _isValidationSuccess
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _validationMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: _isValidationSuccess
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
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

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: 'Disponíveis'),
              Tab(text: 'Meus Códigos'),
            ],
          ),

          // Conteúdo das tabs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(error: _error!, onRetry: _loadPromoCodes)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _AvailablePromoCodesTab(
                            promoCodes: _availablePromoCodes,
                            onRefresh: _loadPromoCodes,
                          ),
                          _PassengerPromoCodesTab(
                            promoCodes: _passengerPromoCodes,
                            onRefresh: _loadPromoCodes,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _AvailablePromoCodesTab extends StatelessWidget {
  final List<PromoCode> promoCodes;
  final VoidCallback onRefresh;

  const _AvailablePromoCodesTab({
    required this.promoCodes,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (promoCodes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum código disponível',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Não há códigos promocionais disponíveis no momento. Puxe para atualizar.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: promoCodes.length,
        itemBuilder: (context, index) {
          final promoCode = promoCodes[index];
          return _PromoCodeCard(
            title: promoCode.code,
            description: promoCode.description ?? promoCode.displayDescription,
            discount: promoCode.displayDescription,
            validUntil: promoCode.validUntil,
            onTap: () => _copyToClipboard(context, promoCode.code),
          );
        },
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $code copiado!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PassengerPromoCodesTab extends StatelessWidget {
  final List<PassengerPromoCode> promoCodes;
  final VoidCallback onRefresh;

  const _PassengerPromoCodesTab({
    required this.promoCodes,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (promoCodes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum código pessoal',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Você ainda não possui códigos promocionais pessoais. Adicione um código acima.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: promoCodes.length,
        itemBuilder: (context, index) {
          final promoCode = promoCodes[index];
          return _PromoCodeCard(
            title: promoCode.code,
            description: promoCode.displayDescription,
            discount: promoCode.displayDescription,
            validUntil: promoCode.validUntil,
            usageInfo: '${promoCode.usageCount}/${promoCode.usageLimit ?? "∞"} usos',
            onTap: () => _copyToClipboard(context, promoCode.code),
          );
        },
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $code copiado!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PromoCodeCard extends StatelessWidget {
  final String title;
  final String description;
  final String discount;
  final DateTime validUntil;
  final String? usageInfo;
  final VoidCallback onTap;

  const _PromoCodeCard({
    required this.title,
    required this.description,
    required this.discount,
    required this.validUntil,
    this.usageInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isExpired = DateTime.now().isAfter(validUntil);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: isExpired ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        color: isExpired
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isExpired)
                    Icon(
                      Icons.content_copy,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                discount,
                style: textTheme.titleMedium?.copyWith(
                  color: isExpired
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != discount) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    isExpired ? Icons.schedule : Icons.access_time,
                    size: 16,
                    color: isExpired
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isExpired
                        ? 'Expirado'
                        : 'Válido até ${_formatDate(validUntil)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: isExpired
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (usageInfo != null) ...[
                    const Spacer(),
                    Text(
                      usageInfo!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Erro ao carregar códigos',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}