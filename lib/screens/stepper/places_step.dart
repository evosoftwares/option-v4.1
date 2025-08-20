import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../models/favorite_location.dart';
import '../../theme/app_theme.dart';
import '../place_picker_screen.dart';

class PlacesStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(List<FavoriteLocation>)? onSave;

  const PlacesStep({
    super.key,
    required this.onNext,
    this.onSave,
  });

  @override
  State<PlacesStep> createState() => _PlacesStepState();
}

class _PlacesStepState extends State<PlacesStep> {
  bool _isLoading = false;

  Future<void> _addPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlacePickerScreen(),
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
    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<StepperController>(context, listen: false);
      
      widget.onSave?.call(controller.favoriteLocations);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar locais: $e'),
            backgroundColor: AppTheme.uberRed,
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
    return Consumer<StepperController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Locais favoritos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione seus locais favoritos para viagens rápidas',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.uberLightGray,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addPlace,
                icon: const Icon(Icons.add, color: AppTheme.uberBlack),
                label: const Text(
                  'Adicionar local',
                  style: TextStyle(color: AppTheme.uberBlack),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.uberWhite,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                              color: AppTheme.uberMediumGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum local favorito ainda',
                              style: TextStyle(
                                color: AppTheme.uberLightGray,
                                fontSize: 16,
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
                            color: AppTheme.uberDarkGray,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: AppTheme.uberWhite,
                              ),
                              title: Text(
                                location.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                location.address,
                                style: TextStyle(color: AppTheme.uberLightGray),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.uberRed,
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
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPlaces,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.uberWhite,
                    foregroundColor: AppTheme.uberBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uberBlack),
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
        );
      },
    );
  }
}