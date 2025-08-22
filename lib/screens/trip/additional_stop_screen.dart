import 'package:flutter/material.dart';
import '../../models/favorite_location.dart';
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
        ? FavoriteLocation.fromJson(originJson)
        : FavoriteLocation(
            id: 'origin-preview',
            name: 'Origem',
            address: 'Selecione a origem',
            type: LocationType.other,
          );

    final destination = destinationJson.isNotEmpty
        ? FavoriteLocation.fromJson(destinationJson)
        : FavoriteLocation(
            id: 'destination-preview',
            name: 'Destino',
            address: 'Selecione o destino',
            type: LocationType.other,
          );

    return AdditionalStopScreen(
      origin: origin,
      destination: destination,
    );
  }

  static const String routeName = '/additional_stop';

  final FavoriteLocation origin;
  final FavoriteLocation destination;

  @override
  State<AdditionalStopScreen> createState() => _AdditionalStopScreenState();
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

    final origem = widget.origin.name.isNotEmpty
        ? widget.origin.name
        : (widget.origin.address.isNotEmpty ? widget.origin.address : 'origem');
    final destino = widget.destination.name.isNotEmpty
        ? widget.destination.name
        : (widget.destination.address.isNotEmpty ? widget.destination.address : 'destino');

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
                      onPressed: () => Navigator.pop(context, null),
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