import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../models/favorite_location.dart';
import '../place_picker_screen.dart';

class PlacesStep extends StatefulWidget {

  const PlacesStep({
    super.key,
    required this.onNext,
    this.onSave,
  });
  final VoidCallback onNext;
  final Function(List<FavoriteLocation>)? onSave;

  @override
  State<PlacesStep> createState() => _PlacesStepState();
}

class _PlacesStepState extends State<PlacesStep> {
  bool _isLoading = false;

  Future<void> _addPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlacePickerScreen(
          isForFavorites: true,
        ),
      ),
    );

    if (result != null && result is FavoriteLocation) {
      final controller = Provider.of<StepperController>(context, listen: false);
      controller.addLocation(result);
    }
  }

  void _removePlace(int index) {
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.removeLocation(index);
  }

  Future<void> _submitPlaces() async {
    final controller = Provider.of<StepperController>(context, listen: false);
    
    if (controller.favoriteLocations.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, adicione pelo menos um local favorito para continuar.'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSave?.call(controller.favoriteLocations);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao salvar locais. Por favor, tente novamente mais tarde.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<StepperController>(
      builder: (context, controller, child) => Padding(
          padding: const EdgeInsets.all(24.0),
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
                'Adicione seus locais favoritos para viagens rápidas',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addPlace,
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
                child: controller.favoriteLocations.isEmpty
                    ? Center(
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
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.favoriteLocations.length,
                        itemBuilder: (context, index) {
                          final location = controller.favoriteLocations[index];
                          return Card(
                            color: colorScheme.surfaceVariant,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: colorScheme.onSurface,
                              ),
                              title: Text(
                                location.name,
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                location.address,
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                onPressed: () => _removePlace(index),
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
                  onPressed: _isLoading ? null : _submitPlaces,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                          ),
                        )
                      : const Text(
                          'Finalizar cadastro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
    );
  }
}