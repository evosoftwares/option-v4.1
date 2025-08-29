import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/saved_places_controller.dart';
import '../models/favorite_location.dart';
import '../services/favorite_locations_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_branding.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  static const routeName = '/saved_places';

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  late SavedPlacesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SavedPlacesController();
    _loadSavedPlaces();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlaces() async {
    await _controller.loadSavedPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const StandardAppBar(
          title: 'Locais favoritos',
          showMenuIcon: false,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Consumer<SavedPlacesController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const _LoadingView();
              }

              if (controller.error != null) {
                return _ErrorView(
                  error: controller.error!,
                  onRetry: _loadSavedPlaces,
                  onClearError: controller.clearError,
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Adicione seus locais favoritos',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione seus locais favoritos para viagens rápidas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: !controller.hasPlaces
                           ? _buildEmptyState()
                           : _SavedPlacesList(
                              places: controller.savedPlaces,
                              onEdit: _showEditPlaceDialog,
                              onDelete: _showDeleteConfirmation,
                              onRefresh: _loadSavedPlaces,
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddPlaceScreen,
                        icon: const Icon(Icons.add_location),
                        label: const Text('Adicionar local'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddPlaceScreen() {
    _showAddPlaceDialog();
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
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
            'Nenhum local favorito ainda',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar seu primeiro local',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    var selectedCategory = LocationType.home;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Local'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do local',
                    hintText: 'Ex: Minha Casa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    hintText: 'Ex: Rua Principal, 123',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<LocationType>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de local',
                    border: OutlineInputBorder(),
                  ),
                  items: LocationType.values.map((type) => 
                    DropdownMenuItem<LocationType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(type.label),
                        ],
                      ),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && 
                    addressController.text.isNotEmpty) {
                  Navigator.pop(context);
                  
                  final success = await _controller.addSavedPlace(
                    label: nameController.text,
                    address: addressController.text,
                    latitude: 0, // Coordenadas padrão - podem ser melhoradas futuramente
                    longitude: 0,
                    category: selectedCategory,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                          ? 'Local adicionado com sucesso!' 
                          : 'Erro ao adicionar local',),
                        backgroundColor: success 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPlaceDialog(SavedPlace place) async {
    final favoriteLocation = FavoriteLocation(
      id: place.id,
      name: place.label,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      type: place.category,
      userId: place.userId,
    );
    
    final result = await showDialog<FavoriteLocation>(
      context: context,
      builder: (context) => _EditPlaceDialog(place: favoriteLocation, onSave: (p) => Navigator.pop(context, p)),
    );

    if (result != null && mounted) {
      await _controller.updateSavedPlace(
        id: result.id ?? '',
        label: result.name,
        address: result.address,
        latitude: result.latitude ?? 0.0,
        longitude: result.longitude ?? 0.0,
        category: result.type,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local atualizado com sucesso!')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(SavedPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir "${place.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed ?? false && mounted) {
      await _controller.removeSavedPlace(place.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local excluído com sucesso!')),
        );
      }
    }
  }
}

class _CategorySelector extends StatelessWidget {

  const _CategorySelector({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });
  final LocationType selectedCategory;
  final Function(LocationType) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: LocationType.values.length,
            itemBuilder: (context, index) {
              final category = LocationType.values[index];
              final isSelected = category == selectedCategory;
              
              return InkWell(
                onTap: () => onCategoryChanged(category),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colorScheme.primaryContainer 
                        : colorScheme.surface,
                    border: Border.all(
                      color: isSelected 
                          ? colorScheme.primary 
                          : colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurface,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(category),
                        style: TextStyle(
                          color: isSelected 
                              ? colorScheme.onPrimaryContainer 
                              : colorScheme.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(LocationType type) {
    switch (type) {
      case LocationType.home:
        return Icons.home;
      case LocationType.work:
        return Icons.work;
      case LocationType.favorite:
        return Icons.favorite;
      case LocationType.other:
        return Icons.place;
      case LocationType.school:
        return Icons.school;
      case LocationType.gym:
        return Icons.fitness_center;
      case LocationType.restaurant:
        return Icons.restaurant;
      case LocationType.shopping:
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }

  String _getCategoryName(LocationType type) {
    switch (type) {
      case LocationType.home:
        return 'Casa';
      case LocationType.work:
        return 'Trabalho';
      case LocationType.favorite:
        return 'Favorito';
      case LocationType.other:
        return 'Outro';
      case LocationType.school:
        return 'Escola';
      case LocationType.gym:
        return 'Academia';
      case LocationType.restaurant:
        return 'Restaurante';
      case LocationType.shopping:
        return 'Compras';
      default:
        return 'Outro';
    }
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(),
    );
}

class _ErrorView extends StatelessWidget {

  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onClearError,
  });
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onClearError;

  @override
  Widget build(BuildContext context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Erro ao carregar locais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
}

class _EmptyStateView extends StatelessWidget {

  const _EmptyStateView({
    required this.onAddPlace,
  });
  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) => _EmptyStateView(
      onAddPlace: onAddPlace,
    );
}

class _SavedPlacesList extends StatelessWidget {

  const _SavedPlacesList({
    required this.places,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });
  final List<SavedPlace> places;
  final Function(SavedPlace) onEdit;
  final Function(SavedPlace) onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Icon(_getCategoryIcon(place.category)),
              title: Text(place.label),
              subtitle: Text(place.address),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: AppSpacing.sm),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Excluir', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(place);
                  } else if (value == 'delete') {
                    onDelete(place);
                  }
                },
              ),
            ),
          );
        },
      ),
    );

  IconData _getCategoryIcon(LocationType type) {
    switch (type) {
      case LocationType.home:
        return Icons.home;
      case LocationType.work:
        return Icons.work;
      case LocationType.favorite:
        return Icons.favorite;
      case LocationType.other:
        return Icons.place;
      default:
        return Icons.place;
    }
  }
}

class _EditPlaceDialog extends StatefulWidget {

  const _EditPlaceDialog({
    required this.place,
    required this.onSave,
  });
  final FavoriteLocation place;
  final Function(FavoriteLocation) onSave;

  @override
  State<_EditPlaceDialog> createState() => _EditPlaceDialogState();
}

class _EditPlaceDialogState extends State<_EditPlaceDialog> {
  late TextEditingController _nameController;
  late LocationType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _selectedType = widget.place.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('Editar Local'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do local',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CategorySelector(
            selectedCategory: _selectedType,
            onCategoryChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedPlace = widget.place.copyWith(
              name: _nameController.text,
              type: _selectedType,
            );
            widget.onSave(updatedPlace);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
}

class _AddPlaceDialog extends StatefulWidget {

  const _AddPlaceDialog({
    required this.onSave,
  });
  final Function(FavoriteLocation) onSave;

  @override
  State<_AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<_AddPlaceDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  LocationType _selectedCategory = LocationType.other;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('Adicionar Local'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do local',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CategorySelector(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
              final newPlace = FavoriteLocation(
                id: '',
                name: _nameController.text,
                address: _addressController.text,
                latitude: 0,
                longitude: 0,
                type: _selectedCategory,
                userId: '',
              );
              widget.onSave(newPlace);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
}