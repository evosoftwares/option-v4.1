import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/logo_branding.dart';

class AdditionalStopScreen extends StatefulWidget {
  const AdditionalStopScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  factory AdditionalStopScreen.fromArgs(Map<String, dynamic>? args) {
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};

    // Fallbacks para pré-visualização direta via URL sem argumentos
    final origin = originJson.isNotEmpty
        ? originJson
        : _createDefaultLocation('origin-preview', 'Origem', 'Selecione a origem');

    final destination = destinationJson.isNotEmpty
        ? destinationJson
        : _createDefaultLocation('destination-preview', 'Destino', 'Selecione o destino');

    return AdditionalStopScreen(
      origin: origin,
      destination: destination,
    );
  }

  static const String routeName = '/additional_stop';

  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;

  @override
  State<AdditionalStopScreen> createState() => _AdditionalStopScreenState();
}

Map<String, dynamic> _createDefaultLocation(String id, String name, String address) {
  return {
    'id': id,
    'name': name,
    'address': address,
    'latitude': null,
    'longitude': null,
    'placeId': null,
  };
}

class _AdditionalStopScreenState extends State<AdditionalStopScreen> {
  final TextEditingController _stopController = TextEditingController();

  @override
  void dispose() {
    _stopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final origem = (widget.origin['name'] as String?)?.isNotEmpty == true
        ? widget.origin['name'] as String
        : ((widget.origin['address'] as String?)?.isNotEmpty == true ? widget.origin['address'] as String : 'origem');
    final destino = (widget.destination['name'] as String?)?.isNotEmpty == true
        ? widget.destination['name'] as String
        : ((widget.destination['address'] as String?)?.isNotEmpty == true ? widget.destination['address'] as String : 'destino');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Parada adicional', showMenuIcon: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pergunta
              Text(
                'Você deseja incluir alguma parada adicional nesta viagem entre $origem e $destino?',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Campo: Parada Adicional
              TextField(
                controller: _stopController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Parada Adicional',
                  hintText: 'Ex.: Padaria Central, Av. Brasil 123',
                  prefixIcon: Icon(
                    Icons.add_location_alt_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              const Spacer(),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Agora não'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = _stopController.text.trim();
                        Navigator.pop(context, value.isEmpty ? null : value);
                      },
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}