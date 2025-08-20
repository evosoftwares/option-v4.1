import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../models/favorite_location.dart';
import '../../services/location_service.dart';
import 'place_search_screen.dart';

class Step3LocationsScreen extends StatefulWidget {
  const Step3LocationsScreen({super.key});

  @override
  State<Step3LocationsScreen> createState() => _Step3LocationsScreenState();
}

class _Step3LocationsScreenState extends State<Step3LocationsScreen> {
  final LocationService _locationService = LocationService(
    apiKey: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
  );

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    // Os locais já estão disponíveis no controller
    // Não precisa carregar, pois são gerenciados localmente
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StepperController>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            'Adicione seus locais favoritos',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esses locais serão usados para sugerir rotas personalizadas',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Lista de locais
          Expanded(
            child: controller.favoriteLocations.isEmpty
                ? _buildEmptyState()
                : _buildLocationsList(controller),
          ),
          // Botão flutuante substituído por botão fixo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddLocationDialog(context),
              icon: const Icon(Icons.add_location),
              label: const Text('Adicionar Local'),
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
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum local adicionado ainda',
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

  Widget _buildLocationsList(StepperController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.favoriteLocations.length,
      itemBuilder: (context, index) {
        final location = controller.favoriteLocations[index];
        return _buildLocationCard(location, controller);
      },
    );
  }

  Widget _buildLocationCard(FavoriteLocation location, StepperController controller) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            location.type.icon,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(location.address),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.primary),
              onPressed: () => _showEditLocationDialog(context, location),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error),
              onPressed: () => _deleteLocation(controller, location.id),
            ),
          ],
        ),
      ),
    );
  }

  // Método removido - navegação será gerenciada pelo stepper

  void _showAddLocationDialog(BuildContext context) {
    _showLocationDialog(context);
  }

  void _showEditLocationDialog(BuildContext context, FavoriteLocation location) {
    _showLocationDialog(context, location: location);
  }

  void _showLocationDialog(BuildContext context, {FavoriteLocation? location}) {
    final isEditing = location != null;
    final controller = Provider.of<StepperController>(context, listen: false);
    
    final nameController = TextEditingController(text: isEditing ? location.name : '');
    final addressController = TextEditingController(text: isEditing ? location.address : '');
    LocationType selectedType = isEditing ? location.type : LocationType.home;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Local' : 'Adicionar Local'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do local',
                        hintText: 'Ex: Minha Casa',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        hintText: 'Ex: Rua Principal, 123',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LocationType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de local',
                      ),
                      items: LocationType.values.map((type) {
                        return DropdownMenuItem<LocationType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(type.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && 
                        addressController.text.isNotEmpty) {
                      if (isEditing) {
                        controller.updateLocationById(
                          location!.id,
                          nameController.text,
                          addressController.text,
                          selectedType,
                        );
                      } else {
                        controller.addLocationWithDetails(
                          nameController.text,
                          addressController.text,
                          selectedType,
                        );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLocation(StepperController controller, String id) {
    controller.removeLocationById(id);
  }
}