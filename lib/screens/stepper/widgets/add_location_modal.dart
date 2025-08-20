import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/favorite_location.dart';
import '../../../controllers/stepper_controller.dart';
import '../../../models/favorite_location.dart';

class AddLocationModal extends StatefulWidget {
  final FavoriteLocation? location;
  final int? index;

  const AddLocationModal({
    Key? key,
    this.location,
    this.index,
  }) : super(key: key);

  @override
  State<AddLocationModal> createState() => _AddLocationModalState();
}

class _AddLocationModalState extends State<AddLocationModal> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  LocationType _selectedType = LocationType.other;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _nameController.text = widget.location!.name;
      _addressController.text = widget.location!.address;
      _selectedType = widget.location!.type;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      // Simulação de busca - em produção, usar Google Places API
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _searchResults = [
          {
            'name': _searchController.text,
            'address': 'Endereço simulado para ${_searchController.text}',
            'lat': -23.5505,
            'lng': -46.6333,
          }
        ];
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar locais: $e')),
      );
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place;
      _nameController.text = place['name'];
      _addressController.text = place['address'];
      _searchResults.clear();
      _searchController.clear();
    });
  }

  void _saveLocation() {
    if (_formKey.currentState!.validate()) {
      final location = FavoriteLocation(
        id: widget.location?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        address: _addressController.text,
        type: _selectedType,
        latitude: _selectedPlace?['lat'] ?? 0.0,
        longitude: _selectedPlace?['lng'] ?? 0.0,
      );

      final controller = context.read<StepperController>();
      
      if (widget.index != null) {
        // Editar local existente
        final updatedLocations = List<FavoriteLocation>.from(controller.locations);
        updatedLocations[widget.index!] = location;
        controller.updateLocations(updatedLocations);
      } else {
        // Adicionar novo local
        final updatedLocations = List<FavoriteLocation>.from(controller.locations);
        updatedLocations.add(location);
        controller.updateLocations(updatedLocations);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.location != null ? 'Editar Local' : 'Adicionar Local',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo de busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar local',
                    hintText: 'Digite o nome do lugar...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchPlaces,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _searchPlaces(),
                ),
                
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          title: Text(place['name']),
                          subtitle: Text(place['address']),
                          onTap: () => _selectPlace(place),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Nome do local
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do local',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do local';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Endereço
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o endereço';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tipo de local
                DropdownButtonFormField<LocationType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de local',
                    border: OutlineInputBorder(),
                  ),
                  items: LocationType.values.map((type) {
                    return DropdownMenuItem(
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
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveLocation,
                        child: Text(widget.location != null ? 'Salvar' : 'Adicionar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}