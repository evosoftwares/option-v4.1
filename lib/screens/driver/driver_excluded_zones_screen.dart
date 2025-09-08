import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../exceptions/app_exceptions.dart';
import '../../models/supabase/driver_excluded_zone.dart';
import '../../services/location_service_factory.dart';
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
  late final LocationServiceBase _locationService;
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<DriverExcludedZone> _excludedZones = [];
  bool _isLoading = true;

  String? _driverId;

  @override
  void initState() {
    super.initState();
    _service = SecureDriverExcludedZonesService(Supabase.instance.client);
    _locationService = LocationServiceFactory.create(apiKey: AppConfig.googleMapsApiKey);
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

  Future<void> _showZoneTypeSelectionDialog({
    required String address,
    required String neighborhood,
    required String city,
    required String state,
  }) async {
    final zoneOptions = [
      {
        'type': 'bairro',
        'icon': Icons.location_city,
        'title': 'Apenas este bairro',
        'subtitle': 'Excluir: $neighborhood',
        'description': 'Não receber corridas apenas neste bairro específico',
        'keyword': neighborhood,
      },
      {
        'type': 'cidade',
        'icon': Icons.location_on,
        'title': 'Toda a cidade',
        'subtitle': 'Excluir: $city',
        'description': 'Não receber corridas em toda a cidade de $city',
        'keyword': city,
      },
      {
        'type': 'estado',
        'icon': Icons.map,
        'title': 'Todo o estado',
        'subtitle': 'Excluir: $state',
        'description': 'Não receber corridas em todo o estado de $state',
        'keyword': state,
      },
    ];

    final selectedOption = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha o tipo de exclusão'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Local selecionado:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text('Selecione o nível de exclusão desejado:'),
                const SizedBox(height: 16),
                ...zoneOptions.map((option) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(option['icon'] as IconData),
                    title: Text(option['title'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['subtitle'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedOption != null && mounted) {
      await _addZoneWithSelectedType(selectedOption, city, state);
    }
  }

  Future<void> _addZoneWithSelectedType(
    Map<String, dynamic> selectedOption,
    String city,
    String state,
  ) async {
    try {
      final zoneType = selectedOption['type'] as String;
      final keyword = selectedOption['keyword'] as String;

      print('DEBUG - Adicionando zona: type=$zoneType, keyword=$keyword');

      final zone = await _service.addExcludedZoneWithType(
        driverId: _driverId!,
        keyword: keyword,
        zoneType: zoneType,
        city: city,
        state: state,
      );

      print('DEBUG - Zona salva com sucesso: ${zone.id}');

      // Recarregar lista
      await _loadExcludedZones();

      _showSuccessSnackBar(
        'Zona excluída adicionada: ${selectedOption['subtitle']}',
      );
    } catch (error) {
      print('DEBUG - Erro ao salvar zona: $error');
      _showErrorSnackBar('Erro ao salvar: ${error.toString()}');
    }
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
            // Fechar dialog de loading e mostrar seleção de tipo
            if (mounted && Navigator.canPop(loadingContext)) {
              Navigator.of(loadingContext).pop();

              // Mostrar dialog para selecionar tipo de exclusão
              await _showZoneTypeSelectionDialog(
                address: address,
                neighborhood: neighborhood,
                city: city,
                state: state,
              );
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
        // Handle any other exceptions that might occur
        print('DEBUG - Erro inesperado: $e');
        if (mounted && Navigator.canPop(loadingContext)) {
          Navigator.of(loadingContext).pop();
          _showErrorSnackBar('Ocorreu um erro inesperado. Por favor, tente novamente.');
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
          'Deseja remover "${zone.displayName}" das suas zonas excluídas?',
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
        showMenuIcon: true,
        showBackButton: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                                    zone.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: zone.isKeywordBased
                                    ? Text('${zone.city}, ${zone.state}')
                                    : Text('${zone.city}, ${zone.state}'),
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
