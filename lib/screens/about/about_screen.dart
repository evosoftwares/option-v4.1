import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/logo_branding.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Sobre o app'),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo e Nome do App
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/Logotipo Vertical Color.webp',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Option',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Versão 1.0.0',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Descrição do App
            _buildSection(
              context,
              title: 'Sobre o Option',
              content: 'O Option é um aplicativo de transporte inovador que conecta passageiros e motoristas de forma rápida, segura e eficiente. Nossa plataforma oferece uma experiência de viagem confortável e confiável para todos os usuários.',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recursos
            _buildSection(
              context,
              title: 'Principais recursos',
              content: '',
              children: [
                _buildFeatureItem(
                  context,
                  icon: Icons.location_on,
                  title: 'Localização em tempo real',
                  description: 'Acompanhe sua viagem em tempo real com GPS preciso',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.security,
                  title: 'Viagens seguras',
                  description: 'Motoristas verificados e sistema de avaliações',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.payment,
                  title: 'Pagamentos digitais',
                  description: 'Integração com carteira digital e múltiplas formas de pagamento',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.star,
                  title: 'Sistema de avaliações',
                  description: 'Avalie sua experiência e mantenha a qualidade do serviço',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.pets,
                  title: 'Viagens com pets',
                  description: 'Opção especial para viajar com seus animais de estimação',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Transporte de compras',
                  description: 'Facilite o transporte de suas compras e encomendas',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Tecnologia
            _buildSection(
              context,
              title: 'Tecnologia',
              content: 'Desenvolvido com Flutter para garantir uma experiência nativa em Android e iOS. Utilizamos Supabase como backend para oferecer máxima confiabilidade e performance.',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Contato e Suporte
            _buildSection(
              context,
              title: 'Suporte',
              content: 'Nossa equipe está sempre disponível para ajudar. Entre em contato conosco através dos canais de atendimento no menu principal.',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Informações legais
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações legais',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '© 2024 Option. Todos os direitos reservados.\n\nEste aplicativo foi desenvolvido seguindo as melhores práticas de segurança e privacidade de dados. Seus dados são protegidos e utilizados apenas para melhorar sua experiência de viagem.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
        if (children != null) ...[
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: AppSpacing.iconSm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
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
}