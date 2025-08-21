import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/location_service.dart';
import '../models/favorite_location.dart';

class PlacePickerScreen extends StatefulWidget {

  const PlacePickerScreen({
    super.key,
    this.title,
    this.allowMultiple = false,
    this.initialPlaces,
    this.apiKey,
    this.isForFavorites = false,
  });
  final String? title;
  final bool allowMultiple;
  final List<FavoriteLocation>? initialPlaces;
  final String? apiKey;
  final bool isForFavorites;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isLoading = false;
  late final LocationService _locationService;
  Map<String, dynamic>? _selectedDetails;
  FavoriteLocation? _selectedLocation;
  // Multi-select support
  final List<FavoriteLocation> _multiSelected = [];
  List<FavoriteLocation> _searchResults = [];

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

  void _selectLocation(FavoriteLocation location) {
    if (widget.allowMultiple) {
      setState(() {
        if (_multiSelected.any((l) => l.id == location.id)) {
          _multiSelected.removeWhere((l) => l.id == location.id);
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

    // Convert search results to FavoriteLocation objects
    final List<FavoriteLocation> locations = [];
    for (final result in results) {
      final placeId = result['placeId'] as String?;
      if (placeId != null) {
        final details = await _locationService.getPlaceDetails(placeId);
        if (details != null) {
          final lat = details['lat'] as num?;
          final lng = details['lng'] as num?;
          if (lat != null && lng != null) {
            locations.add(FavoriteLocation(
              id: placeId,
              name: (result['mainText'] as String?) ?? 'Local',
              address: (result['description'] as String?) ?? '',
              type: LocationType.other,
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              placeId: placeId,
            ));
          }
        }
      }
    }

    setState(() {
      _searchResults = locations;
      _isLoading = false;
    });
  }



  Future<LocationType?> _chooseType() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<LocationType>(
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
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final type in LocationType.values)
                      if (type != LocationType.favorite) // Filtrar 'favorite' da seleção manual
                        ListTile(
                          leading: Icon(type.icon, color: colorScheme.primary),
                          title: Text(type.label, style: TextStyle(color: colorScheme.onSurface)),
                          subtitle: Text(type.description, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          onTap: () => Navigator.pop(context, type),
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
      LocationType type;
      
      if (widget.isForFavorites) {
        // Para favoritos, permitir escolha do tipo
        final selectedType = await _chooseType();
        if (selectedType == null) return;
        type = selectedType;
      } else {
        // Para seleção de origem/destino, não exibir seleção de tipo
        // e manter o tipo detectado (padrão: other)
        type = _selectedLocation!.type;
      }

      final updatedLocation = FavoriteLocation(
        id: _selectedLocation!.id,
        name: _selectedLocation!.name,
        address: _selectedLocation!.address,
        type: type,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        placeId: _selectedLocation!.placeId,
      );
      
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
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        title: Text(
          widget.title ?? 'Selecionar local',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
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
                hintText: 'Buscar lugares... ',
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final location = _searchResults[index];
                      final isSelected = widget.allowMultiple 
                          ? _multiSelected.any((l) => l.id == location.id)
                          : _selectedLocation?.id == location.id;
                      
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
                        child: ListTile(
                          leading: Icon(
                            location.type.icon,
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.primary,
                          ),
                          title: Text(
                            location.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            location.address,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: widget.allowMultiple
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _selectLocation(location),
                                )
                              : isSelected
                                  ? Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer)
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
                          Icons.search,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Busque por locais',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Digite o nome ou endereço para encontrar locais',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
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