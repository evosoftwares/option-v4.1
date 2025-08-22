import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/favorite_location.dart';
import '../../services/location_service.dart';
import '../../theme/app_spacing.dart';

class FavoritesStep extends StatefulWidget {

  const FavoritesStep({
    super.key,
    required this.initialFavorites,
    required this.onSave,
    required this.onNext,
  });
  final List<FavoriteLocation> initialFavorites;
  final Function(List<FavoriteLocation>) onSave;
  final VoidCallback onNext;

  @override
  State<FavoritesStep> createState() => _FavoritesStepState();
}

class _FavoritesStepState extends State<FavoritesStep> {
  final List<FavoriteLocation> _favoritePlaces = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritePlaces.addAll(widget.initialFavorites);
  }

  Future<void> _handleNext() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    widget.onSave(_favoritePlaces);
    widget.onNext();
  }

  Future<void> _addFavoritePlace() async {
    final result = await _showAddFavoriteBottomSheet();

    if (result is FavoriteLocation) {
      setState(() {
        final exists = _favoritePlaces.any((f) =>
            (f.placeId != null && f.placeId == result.placeId) ||
            (f.latitude == result.latitude && f.longitude == result.longitude),);
        if (!exists) {
          _favoritePlaces.add(result);
        }
      });
    }
  }

  Future<FavoriteLocation?> _showAddFavoriteBottomSheet() async {
    return await showModalBottomSheet<FavoriteLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const FractionallySizedBox(
          heightFactor: 0.85,
          child: _AddFavoriteBottomSheet(),
        ),
      ),
    );
  }

  void _removeFavoritePlace(int index) {
    setState(() {
      _favoritePlaces.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Locais favoritos',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus locais favoritos para viagens mais rápidas',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addFavoritePlace,
              icon: Icon(Icons.add, color: colorScheme.onSurface),
              label: Text(
                'Adicionar local',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _favoritePlaces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum local favorito ainda',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoritePlaces.length,
                    itemBuilder: (context, index) {
                      final loc = _favoritePlaces[index];
                      return Card(
                        color: colorScheme.surfaceContainerHighest,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            loc.type.icon,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            loc.name,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            loc.address,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _removeFavoritePlace(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Finalizar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                widget.onSave(_favoritePlaces);
                widget.onNext();
              },
              child: Text(
                'Pular esta etapa',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteBottomSheet extends StatefulWidget {
  const _AddFavoriteBottomSheet();

  @override
  State<_AddFavoriteBottomSheet> createState() => _AddFavoriteBottomSheetState();
}

class _AddFavoriteBottomSheetState extends State<_AddFavoriteBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final LocationService _locationService;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  bool _isLoading = false;
  FavoriteLocation? _selectedLocation;
  LocationType? _selectedType;
  List<FavoriteLocation> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _locationService.searchPlaces(query);
    if (!mounted) return;

    final locations = <FavoriteLocation>[];
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

  void _selectLocation(FavoriteLocation location) {
    setState(() => _selectedLocation = location);
  }

  void _selectType(LocationType type) {
    setState(() => _selectedType = type);
  }

  Future<void> _saveFavorite() async {
    if (_selectedLocation != null && _selectedType != null) {
      final updatedLocation = _selectedLocation!.copyWith(type: _selectedType);
      await _animationController.reverse();
      if (mounted) {
        Navigator.of(context).pop(updatedLocation);
      }
    }
  }

  Future<void> _cancel() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Adicionar Favorito',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                onPressed: _cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _searchPlaces,
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Buscar endereço...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Digite um endereço para buscar',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        final isSelected = _selectedLocation?.id == location.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          child: ListTile(
            leading: Icon(
              Icons.place,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
            title: Text(
              location.name,
              style: textTheme.titleSmall?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              location.address,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer)
                : null,
            onTap: () => _selectLocation(location),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_selectedLocation == null) return const SizedBox.shrink();

    final types = LocationType.values.where((type) => type != LocationType.favorite).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tipo do local',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = _selectedType == type;

              return InkWell(
                onTap: () => _selectType(type),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type.icon,
                        size: AppSpacing.iconSm,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    final canSave = _selectedLocation != null && _selectedType != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: canSave ? _saveFavorite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.md),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSearchResults(),
                      _buildTypeSelector(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}