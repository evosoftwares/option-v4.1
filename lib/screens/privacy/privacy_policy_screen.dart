import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Política de Privacidade do OPTION',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Última atualização: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSection(
                context,
                '1. Informações Gerais',
                'O OPTION valoriza a privacidade e a proteção dos dados pessoais de seus usuários. Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos suas informações quando você utiliza nosso aplicativo de mobilidade urbana.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '2. Dados Coletados',
                'Coletamos os seguintes tipos de informações:\n\n'
                '• Informações de registro: nome, e-mail, telefone\n'
                '• Informações de localização: para fornecer serviços de transporte\n'
                '• Informações de pagamento: para processar transações\n'
                '• Informações do veículo: para motoristas (marca, modelo, placa)\n'
                '• Documentos: CNH, CRLV (exclusivamente para motoristas)\n'
                '• Dados de uso: informações sobre como você utiliza o app',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '3. Uso das Informações',
                'Utilizamos seus dados para:\n\n'
                '• Fornecer e melhorar nossos serviços de transporte\n'
                '• Conectar passageiros e motoristas\n'
                '• Processar pagamentos e transações\n'
                '• Verificar a identidade dos usuários\n'
                '• Comunicar sobre atualizações e promoções (com consentimento)\n'
                '• Melhorar a experiência do usuário (com consentimento para analytics)\n'
                '• Cumprir obrigações legais e regulatórias',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '4. Compartilhamento de Dados',
                'Seus dados podem ser compartilhados apenas com:\n\n'
                '• Motoristas (quando você solicita uma corrida)\n'
                '• Passageiros (quando você oferece uma corrida)\n'
                '• Parceiros de pagamento (para processar transações)\n'
                '• Autoridades legais (quando exigido por lei)\n\n'
                'Não vendemos, alugamos ou comercializamos seus dados pessoais.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '5. Consentimento para Analytics',
                'Você pode optar por compartilhar dados anônimos de uso para nos ajudar a melhorar o aplicativo. Esta opção pode ser alterada a qualquer momento nas configurações do app.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '6. Segurança',
                'Implementamos medidas de segurança técnicas e organizacionais para proteger seus dados contra acesso não autorizado, alteração, divulgação ou destruição.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '7. Seus Direitos',
                'Você tem o direito de:\n\n'
                '• Acessar seus dados pessoais\n'
                '• Corrigir informações incorretas\n'
                '• Solicitar a exclusão dos seus dados\n'
                '• Retirar seu consentimento a qualquer momento\n'
                '• Obter uma cópia dos seus dados\n\n'
                'Para exercer esses direitos, entre em contato conosco através do telefone: (65) 9257-7217',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '8. Alterações nesta Política',
                'Podemos atualizar esta Política de Privacidade periodicamente. Notificaremos você sobre alterações significativas através do aplicativo ou por e-mail.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                context,
                '9. Contato',
                'Se você tiver dúvidas sobre esta Política de Privacidade, entre em contato conosco:\n\n'
                'Telefone: (65) 9257-7217',
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  '© ${DateTime.now().year} OPTION. Todos os direitos reservados.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}