import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../controllers/stepper_controller.dart';
import '../../models/favorite_location.dart';
import '../../services/location_service.dart';
import '../../utils/supabase_helper.dart';
import '../../widgets/app_card.dart';
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
  bool _isGettingLocation = false;
  late LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(apiKey: AppConfig.googleMapsApiKey);
  }

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
      print('📍 [DEBUG] Adicionando local do place picker: ${result.name} - ${result.address}');
      final controller = Provider.of<StepperController>(context, listen: false);
      controller.addLocation(result);
      print('📍 [DEBUG] Total de locais agora: ${controller.favoriteLocations.length}');
    } else {
      print('⚠️ [DEBUG] Nenhum local retornado do place picker ou resultado inválido: $result');
    }
  }

  void _removePlace(int index) {
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.removeLocation(index);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      // Verificar e solicitar permissões
      final hasPermission = await _locationService.ensureLocationPermissions();
      if (!hasPermission) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permissão de localização negada. Por favor, habilite nas configurações do dispositivo.'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              action: const SnackBarAction(
                label: 'Configurações',
                onPressed: Geolocator.openAppSettings,
              ),
            ),
          );
        }
        return;
      }

      // Verificar se o serviço de localização está habilitado
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Serviço de localização desabilitado. Por favor, habilite o GPS nas configurações.'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              action: const SnackBarAction(
                label: 'Configurações',
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        return;
      }

      // Obter localização atual com timeout de 30 segundos
      final location = await _locationService.getCurrentLocation()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Timeout ao obter localização', const Duration(seconds: 30));
            },
          );
      
      if (location == null) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Não foi possível obter sua localização atual. Verifique se o GPS está habilitado.'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Fazer geocodificação reversa para obter o endereço com timeout de 15 segundos
      final address = await _locationService.geocodeAddress('${location['lat']},${location['lng']}')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Timeout na geocodificação', const Duration(seconds: 15));
            },
          );
      
      if (address == null) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Não foi possível obter o endereço da sua localização. Verifique sua conexão com a internet.'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Criar FavoriteLocation com a localização atual
       final controller = Provider.of<StepperController>(context, listen: false);
       
       // Obter o userId do usuário autenticado
       final authUser = SupabaseHelper.client?.auth.currentUser;
       if (authUser == null) {
         if (mounted) {
           final colorScheme = Theme.of(context).colorScheme;
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: const Text('Usuário não autenticado. Faça login novamente.'),
               backgroundColor: colorScheme.error,
               behavior: SnackBarBehavior.floating,
             ),
           );
         }
         return;
       }
       
       final currentLocation = FavoriteLocation(
         id: DateTime.now().millisecondsSinceEpoch.toString(),
         userId: authUser.id,
         name: 'Localização Atual',
         address: address['formatted_address'] ?? 'Endereço não disponível',
         type: LocationType.favorite,
         latitude: address['latitude'] ?? location['lat'],
         longitude: address['longitude'] ?? location['lng'],
         placeId: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
         createdAt: DateTime.now(),
       );

      // Adicionar à lista de locais favoritos
      controller.addLocation(currentLocation);
      
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Localização atual adicionada com sucesso!'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout ao obter localização: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message?.contains('geocodificação') ?? false 
                ? 'Timeout na busca do endereço. Verifique sua conexão e tente novamente.'
                : 'Timeout ao obter localização. Verifique se o GPS está funcionando e tente novamente.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PermissionDeniedException catch (e) {
      print('🚫 Permissão de localização negada: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissão de localização negada permanentemente. Habilite nas configurações do dispositivo.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: const SnackBarAction(
              label: 'Configurações',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
    } on LocationServiceDisabledException catch (e) {
      print('📍 Serviço de localização desabilitado: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Serviço de localização desabilitado. Habilite o GPS nas configurações.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: const SnackBarAction(
              label: 'Configurações',
              onPressed: Geolocator.openLocationSettings,
            ),
          ),
        );
      }
    } on PositionUpdateException catch (e) {
      print('📡 Erro ao atualizar posição: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao obter localização. Verifique se o GPS está funcionando corretamente.'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro inesperado ao obter localização atual: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        var errorMessage = 'Erro inesperado ao obter localização atual.';
        
        // Verificar tipos específicos de erro
        if (e.toString().contains('network') || e.toString().contains('internet')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Erro de permissão. Verifique as configurações de localização.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Operação demorou muito para responder. Tente novamente.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
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
                'Adicione seus locais favoritos para viagens rápidas',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _useCurrentLocation,
                      icon: _isGettingLocation
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(Icons.my_location, color: colorScheme.onPrimary),
                      label: Text(
                        'Usar GPS',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
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
                          return AppCard(
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