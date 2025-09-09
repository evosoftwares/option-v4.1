import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/location_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_branding.dart';

String _getLocationTypeLabel(String type) {
  switch (type) {
    case 'home': return 'Casa';
    case 'work': return 'Trabalho';
    case 'school': return 'Escola';
    case 'gym': return 'Academia';
    default: return 'Outro';
  }
}

IconData _getLocationTypeIcon(String type) {
  switch (type) {
    case 'home': return Icons.home;
    case 'work': return Icons.work;
    case 'school': return Icons.school;
    case 'gym': return Icons.fitness_center;
    default: return Icons.location_on;
  }
}

class PlacePickerScreen extends StatefulWidget {

  const PlacePickerScreen({
    super.key,
    this.title,
    this.allowMultiple = false,
    this.initialPlaces,
    this.apiKey,
  });
  final String? title;
  final bool allowMultiple;
  final List<Map<String, dynamic>>? initialPlaces;
  final String? apiKey;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isLoading = false;
  late final LocationService _locationService;
  Map<String, dynamic>? _selectedDetails;
  Map<String, dynamic>? _selectedLocation;
  // Multi-select support
  final List<Map<String, dynamic>> _multiSelected = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: widget.apiKey ?? AppConfig.googleMapsApiKey,
    );
    
    print('LocationService inicializado com API key: ${widget.apiKey ?? AppConfig.googleMapsApiKey}');

    if (widget.initialPlaces != null) {
      _multiSelected.addAll(widget.initialPlaces!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _selectLocation(Map<String, dynamic> location) {
    if (widget.allowMultiple) {
      setState(() {
        if (_multiSelected.any((l) => l['id'] == location['id'])) {
          _multiSelected.removeWhere((l) => l['id'] == location['id']);
        } else {
          _multiSelected.add(location);
        }
      });
    } else {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    final results = await _locationService.searchPlaces(query);
    if (!mounted) return;

    // Convert search results to location maps
    final locations = <Map<String, dynamic>>[];
    for (final result in results) {
      final placeId = result['placeId'] as String?;
      if (placeId != null) {
        final details = await _locationService.getPlaceDetails(placeId);
        if (details != null) {
          final lat = details['lat'] as num?;
          final lng = details['lng'] as num?;
          if (lat != null && lng != null) {
            final name = (result['mainText'] as String?) ?? 'Local';
            final address = (result['description'] as String?) ?? '';
            
            locations.add({
              'id': placeId,
              'name': placeId.startsWith('manual_') ? address : name,
              'address': placeId.startsWith('manual_') ? 'Endereço digitado manualmente' : address,
              'type': 'other',
              'latitude': lat.toDouble(),
              'longitude': lng.toDouble(),
              'placeId': placeId,
              'userId': '', // Temporary empty userId for search results
            });
          }
        }
      }
    }

    setState(() {
      _searchResults = locations;
      _isLoading = false;
    });
  }



  Future<String?> _chooseType() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final locationTypes = [
      {'value': 'home', 'label': 'Casa', 'icon': Icons.home, 'description': 'Sua residência'},
      {'value': 'work', 'label': 'Trabalho', 'icon': Icons.work, 'description': 'Seu local de trabalho'},
      {'value': 'school', 'label': 'Escola', 'icon': Icons.school, 'description': 'Sua escola ou universidade'},
      {'value': 'gym', 'label': 'Academia', 'icon': Icons.fitness_center, 'description': 'Sua academia'},
      {'value': 'other', 'label': 'Outro', 'icon': Icons.location_on, 'description': 'Outro tipo de local'},
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Selecione o tipo', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final type in locationTypes)
                      ListTile(
                        leading: Icon(type['icon'] as IconData, color: colorScheme.primary),
                        title: Text(type['label'] as String, style: TextStyle(color: colorScheme.onSurface)),
                        subtitle: Text(type['description'] as String, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        onTap: () => Navigator.pop(context, type['value'] as String),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Future<void> _savePlaces() async {
    // If multiple selection mode, return all selected places
    if (widget.allowMultiple) {
      if (_multiSelected.isNotEmpty) {
        Navigator.of(context).pop(_multiSelected);
      }
      return;
    }

    // Single selection mode
    if (_selectedLocation != null) {
      // Para seleção de origem/destino, não exibir seleção de tipo
      // e manter o tipo detectado (padrão: other)
      final type = _selectedLocation!['type'] as String? ?? 'other';

      final updatedLocation = {
        'id': _selectedLocation!['id'],
        'name': _selectedLocation!['name'],
        'address': _selectedLocation!['address'],
        'type': type,
        'latitude': _selectedLocation!['latitude'],
        'longitude': _selectedLocation!['longitude'],
        'placeId': _selectedLocation!['placeId'],
        'userId': _selectedLocation!['userId'],
      };
      
      if (!mounted) return;
      Navigator.of(context).pop(updatedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(
        title: widget.title ?? 'Selecionar local',
        showMenuIcon: false,
        actions: [
          if ((widget.allowMultiple && _multiSelected.isNotEmpty) || 
              (!widget.allowMultiple && _selectedLocation != null))
            TextButton(
              onPressed: _savePlaces,
              child: Text(
                'Salvar',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _searchPlaces,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Digite o nome do local ou endereço...',
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs * 3, horizontal: AppSpacing.md),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _searchResults.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final location = _searchResults[index];
                      final isSelected = widget.allowMultiple
                          ? _multiSelected.any((l) => l['id'] == location['id'])
                          : _selectedLocation?['id'] == location['id'];
                      
                      return AppCard(
                        elevation: isSelected ? 4 : 1,
                        backgroundColor: isSelected ? colorScheme.primary : null,
                        borderColor: isSelected ? colorScheme.primary : null,
                        child: ListTile(
                          leading: Icon(
                            _getLocationTypeIcon(location['type'] as String? ?? 'other'),
                            color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                          ),
                          title: Text(
                            location['name'] as String? ?? 'Local',
                            style: textTheme.titleMedium?.copyWith(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            location['address'] as String? ?? '',
                            style: textTheme.bodyMedium?.copyWith(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: widget.allowMultiple
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _selectLocation(location),
                                  fillColor: isSelected
                                      ? WidgetStateProperty.all(colorScheme.onPrimary)
                                      : null,
                                  checkColor: isSelected
                                      ? colorScheme.primary
                                      : null,
                                )
                              : isSelected
                                  ? Icon(Icons.check_circle, color: colorScheme.onPrimary)
                                  : null,
                          onTap: () => _selectLocation(location),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Digite um local',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Digite o nome do local ou endereço completo que você deseja adicionar',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: ((widget.allowMultiple && _multiSelected.isNotEmpty) || 
                                (!widget.allowMultiple && _selectedLocation != null))
          ? FloatingActionButton.extended(
              onPressed: _savePlaces,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
            )
          : null,
    );
  }
}