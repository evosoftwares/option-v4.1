import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../exceptions/app_exceptions.dart';
import '../../models/supabase/driver_excluded_zone.dart';
import '../../services/location_service.dart';
import '../../services/secure_driver_excluded_zones_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/logo_branding.dart';
import '../stepper/place_search_screen.dart';

class DriverExcludedZonesScreen extends StatefulWidget {
  const DriverExcludedZonesScreen({super.key});

  static const routeName = '/driver_excluded_zones';

  @override
  State<DriverExcludedZonesScreen> createState() =>
      _DriverExcludedZonesScreenState();
}

class _DriverExcludedZonesScreenState extends State<DriverExcludedZonesScreen> {
  late final SecureDriverExcludedZonesService _service;
  late final LocationService _locationService;
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<DriverExcludedZone> _excludedZones = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _service = SecureDriverExcludedZonesService(Supabase.instance.client);
    _locationService = LocationService(apiKey: AppConfig.googleMapsApiKey);
    _loadDriverData();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await UserService.getCurrentUser();
      print('DEBUG - Usuário atual: ${user?.id}, tipo: ${user?.userType}');

      if (user?.userType == 'driver') {
        _driverId = user!.id;
        print('DEBUG - Driver ID definido: $_driverId');
        await _loadExcludedZones();
      } else {
        print('DEBUG - Usuário não é motorista ou não encontrado');
      }
    } catch (e) {
      print('DEBUG - Erro ao carregar dados do motorista: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados do motorista: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExcludedZones() async {
    if (_driverId == null) {
      print('DEBUG - Não foi possível carregar zonas: driverId é null');
      return;
    }

    print('DEBUG - Carregando zonas para driver: $_driverId');

    try {
      final zones = await _service.getDriverExcludedZones(_driverId!);
      print('DEBUG - Zonas carregadas: ${zones.length} zonas encontradas');

      if (mounted) {
        setState(() {
          _excludedZones = zones;
        });
      }
    } catch (e) {
      print('DEBUG - Erro ao carregar zonas: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar zonas excluídas: $e');
      }
    }
  }

  Future<void> _addExcludedZone() async {
    if (!_formKey.currentState!.validate() || _driverId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _service.addExcludedZone(
        driverId: _driverId!,
        neighborhoodName: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );

      // Clear form
      _neighborhoodController.clear();
      _cityController.clear();
      _stateController.clear();

      // Reload zones
      await _loadExcludedZones();

      if (mounted) {
        _showSuccessSnackBar('Zona excluída adicionada com sucesso!');
      }
    } on ValidationException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Erro inesperado ao adicionar zona excluída. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _removeExcludedZone(DriverExcludedZone zone) async {
    try {
      await _service.removeExcludedZone(zone.id);
      await _loadExcludedZones();

      if (mounted) {
        _showSuccessSnackBar('Zona excluída removida com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao remover zona excluída: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _showAddZoneDialog() async {
    if (_driverId == null) {
      _showErrorSnackBar('Erro: Motorista não identificado');
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceSearchScreen(
          locationService: _locationService,
        ),
      ),
    );

    if (result != null && mounted) {
      // Debug: Ver o que foi retornado
      print('DEBUG - Resultado da busca: $result');

      // Mostrar loading enquanto processa
      final loadingContext = context;
      showDialog(
        context: loadingContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Extrair informações do local selecionado
        final address = result['address'] as String? ?? '';
        print('DEBUG - Endereço recebido: "$address"');

        final addressParts = _parseAddress(address);
        print('DEBUG - Partes do endereço: $addressParts');

        // Preparar dados para adição com validação robusta
        final neighborhood = (addressParts['neighborhood'] ?? '').trim();
        final city = (addressParts['city'] ?? '').trim();
        final state = (addressParts['state'] ?? '').trim().toUpperCase();

        print(
            'DEBUG - Processado: neighborhood="$neighborhood", city="$city", state="$state"');

        // Validar se temos informações mínimas
        if (neighborhood.isNotEmpty &&
            city.isNotEmpty &&
            state.isNotEmpty &&
            state.length == 2) {
          // Verificar se é uma sigla de estado válida
          final validStates = {
            'AC',
            'AL',
            'AP',
            'AM',
            'BA',
            'CE',
            'DF',
            'ES',
            'GO',
            'MA',
            'MT',
            'MS',
            'MG',
            'PA',
            'PB',
            'PR',
            'PE',
            'PI',
            'RJ',
            'RN',
            'RS',
            'RO',
            'RR',
            'SC',
            'SP',
            'SE',
            'TO'
          };

          if (validStates.contains(state)) {
            print(
                'DEBUG - Tentando salvar zona: driverId=$_driverId, neighborhood=$neighborhood, city=$city, state=$state');

            try {
              // Adicionar diretamente via serviço com driverId
              final zone = await _service.addExcludedZone(
                driverId: _driverId!,
                neighborhoodName: neighborhood,
                city: city,
                state: state,
                fromGooglePlaces: true, // Dados vindos do Google Places
              );

              print('DEBUG - Zona salva com sucesso: ${zone.id}');

              // Recarregar lista
              await _loadExcludedZones();

              if (mounted && Navigator.canPop(loadingContext)) {
                Navigator.of(loadingContext).pop();
                _showSuccessSnackBar(
                    'Zona excluída adicionada: $neighborhood, $city - $state');
              }
            } catch (serviceError) {
              print('DEBUG - Erro do serviço: $serviceError');
              if (mounted && Navigator.canPop(loadingContext)) {
                Navigator.of(loadingContext).pop();
                _showErrorSnackBar(
                    'Erro ao salvar: ${serviceError.toString()}');
              }
            }
          } else {
            // Estado inválido
            if (mounted && Navigator.canPop(loadingContext)) {
              Navigator.of(loadingContext).pop();
              _showErrorSnackBar(
                  'Estado inválido identificado. Por favor, selecione um endereço no Brasil.');
            }
          }
        } else {
          // Informações incompletas
          if (mounted && Navigator.canPop(loadingContext)) {
            Navigator.of(loadingContext).pop();
            _showErrorSnackBar(
                'Não foi possível identificar o endereço completo. Tente um endereço mais específico.');
          }
        }
      } catch (e) {
        if (mounted && Navigator.canPop(loadingContext)) {
          Navigator.of(loadingContext).pop();
          _showErrorSnackBar('Erro ao adicionar zona: ${e.toString()}');
        }
      }
    }
  }

  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((p) => p.trim()).toList();
    final result = <String, String>{};

    print('DEBUG - Partes separadas: $parts');

    if (parts.isEmpty) return result;

    // 1. Identificar o estado (sigla de 2 letras)
    String? state;
    for (int i = parts.length - 1; i >= 0; i--) {
      final stateMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(parts[i]);
      if (stateMatch != null) {
        state = stateMatch.group(1)!;
        result['state'] = state;
        break;
      }
    }

    // 2. Identificar a cidade (busca sistemática)
    String? city;
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i].trim();

      // Pular se for o país
      if (part.toLowerCase().contains('brasil')) continue;

      // Pular se for só CEP
      if (RegExp(r'^\d{5}-?\d{3}$').hasMatch(part)) continue;

      // Limpar CEP da parte
      part = part.replaceAll(RegExp(r'\d{5}-?\d{3}'), '').trim();

      // Se tem estado junto, remover (ex: "Cairu - BA" -> "Cairu")
      if (state != null && part.endsWith(' - $state')) {
        part = part.replaceAll(' - $state', '').trim();
      }

      // Verificar se é uma cidade válida
      if (part.isNotEmpty &&
          part.length > 1 &&
          !RegExp(r'^[A-Z]{2}$').hasMatch(part) && // Não é só sigla do estado
          !part.toLowerCase().contains('brasil')) {
        // Se não tem hífen, é provável que seja cidade
        if (!part.contains(' - ')) {
          // Verificar se não é a primeira parte (que geralmente é bairro)
          if (i > 0 || parts.length <= 2) {
            city = part;
            break;
          }
        }
        // Se tem hífen, pode ser cidade composta (ex: "Rio de Janeiro")
        else {
          // Verificar se parece com nome de cidade (mais de uma palavra sem hífen interno)
          final cityCandidate = part.split(' - ').last.trim();
          if (cityCandidate.split(' ').length >= 2 ||
              cityCandidate.length > 4) {
            city = cityCandidate;
            break;
          }
        }
      }
    }

    // Fallback para cidade: pegar parte não-Brasil, não-CEP, não-primeira-parte
    if (city == null && parts.length > 2) {
      for (int i = 1; i < parts.length - 1; i++) {
        String part = parts[i].replaceAll(RegExp(r'\d{5}-?\d{3}'), '').trim();
        if (state != null) {
          part = part.replaceAll(' - $state', '').trim();
        }

        if (part.isNotEmpty &&
            !part.toLowerCase().contains('brasil') &&
            !RegExp(r'^[A-Z]{2}$').hasMatch(part)) {
          city = part;
          break;
        }
      }
    }

    if (city != null) {
      result['city'] = city;
    }

    // 3. Identificar o bairro (primeira parte, antes do hífen)
    if (parts.isNotEmpty) {
      String neighborhood = parts.first.trim();

      // Se tem hífen, pegar só a primeira parte antes do hífen
      if (neighborhood.contains(' - ')) {
        neighborhood = neighborhood.split(' - ').first.trim();
      }

      if (neighborhood.isNotEmpty &&
          !neighborhood.toLowerCase().contains('brasil') &&
          neighborhood != city &&
          neighborhood != state) {
        result['neighborhood'] = neighborhood;
      }
    }

    print('DEBUG - Resultado do parsing: $result');
    return result;
  }

  void _showRemoveConfirmation(DriverExcludedZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Zona Excluída'),
        content: Text(
          'Deseja remover "${zone.neighborhoodName}, ${zone.city} - ${zone.state}" das suas zonas excluídas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExcludedZone(zone);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Zonas Excluídas',
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        showMenuIcon: true,
        showBackButton: true,
      ),
      floatingActionButton: _driverId != null
          ? FloatingActionButton(
              onPressed: _showAddZoneDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExcludedZones,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Zonas de Exclusão',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Defina áreas onde você não deseja receber corridas',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.9),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Você pode adicionar quantas zonas quiser. O app não enviará corridas com origem nessas áreas.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Excluded Zones List
                    if (_excludedZones.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.location_on,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Nenhuma zona excluída',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Toque no botão + para adicionar uma zona',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zonas Excluídas (${_excludedZones.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _excludedZones.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final zone = _excludedZones[index];
                              return AppCard(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_off,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                  title: Text(
                                    zone.neighborhoodName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('${zone.city}, ${zone.state}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _showRemoveConfirmation(zone),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
