import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../models/favorite_location.dart';
import '../../services/location_service.dart';
import 'place_search_screen.dart';
import '../../theme/app_theme.dart';

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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Adicione seus locais favoritos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esses locais serão usados para sugerir rotas personalizadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
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
                backgroundColor: AppTheme.uberGreen,
                foregroundColor: Colors.white,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum local adicionado ainda',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar seu primeiro local',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            location.type.icon,
            color: Colors.blue.shade800,
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
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditLocationDialog(context, location),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
                  child: Text(isEditing ? 'SALVAR' : 'ADICIONAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLocation(StepperController controller, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              controller.removeLocationById(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  // Método removido - conclusão será gerenciada pelo stepper
}