import 'package:flutter/material.dart';
import '../../models/favorite_location.dart';
import 'driver_selection_screen.dart';

class TripOptionsScreen extends StatefulWidget {

  const TripOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  factory TripOptionsScreen.fromArgs(Map<String, dynamic>? args) {
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};
    return TripOptionsScreen(
      origin: FavoriteLocation.fromJson(originJson),
      destination: FavoriteLocation.fromJson(destinationJson),
    );
  }
  static const String routeName = '/trip_options';

  final FavoriteLocation origin;
  final FavoriteLocation destination;

  @override
  State<TripOptionsScreen> createState() => _TripOptionsScreenState();
}

class _TripOptionsScreenState extends State<TripOptionsScreen> {
  String _selectedCategory = 'standard';
  bool _needsPet = false;
  bool _needsGrocery = false;
  bool _needsCondo = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Opções da viagem'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationsSummary(origin: widget.origin, destination: widget.destination),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Categoria do veículo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _categoryChip('standard', 'Econômico'),
                  _categoryChip('premium', 'Premium'),
                  _categoryChip('suv', 'SUV'),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Preferências'),
              const SizedBox(height: 8),
              _prefTile(
                title: 'Levo pet',
                value: _needsPet,
                onChanged: (v) => setState(() => _needsPet = v),
              ),
              _prefTile(
                title: 'Espaço para compras',
                value: _needsGrocery,
                onChanged: (v) => setState(() => _needsGrocery = v),
              ),
              _prefTile(
                title: 'Condomínio (acesso facilitado)',
                value: _needsCondo,
                onChanged: (v) => setState(() => _needsCondo = v),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar motoristas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategory = value),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }

  Widget _prefTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(),
    );
  }

  void _continue() {
    final o = widget.origin;
    final d = widget.destination;
    Navigator.pushNamed(
      context,
      DriverSelectionScreen.routeName,
      arguments: {
        'origin': o.toJson(),
        'destination': d.toJson(),
        'category': _selectedCategory,
        'needsPet': _needsPet,
        'needsGrocery': _needsGrocery,
        'needsCondo': _needsCondo,
      },
    );
  }
}

class _LocationsSummary extends StatelessWidget {
  const _LocationsSummary({required this.origin, required this.destination});
  final FavoriteLocation origin;
  final FavoriteLocation destination;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin.address,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination.address,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
    );
  }
}