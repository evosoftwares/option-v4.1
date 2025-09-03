import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../exceptions/app_exceptions.dart';
import '../../models/favorite_location.dart';
import '../../models/supabase/driver_excluded_zone.dart';
import '../../services/secure_driver_excluded_zones_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../place_picker_screen.dart';

class DriverUnavailableNeighborhoodsScreen extends StatefulWidget {
  const DriverUnavailableNeighborhoodsScreen({super.key});

  static const routeName = '/driver_unavailable_neighborhoods';

  @override
  State<DriverUnavailableNeighborhoodsScreen> createState() => _DriverUnavailableNeighborhoodsScreenState();
}

class _DriverUnavailableNeighborhoodsScreenState extends State<DriverUnavailableNeighborhoodsScreen> {
  late final SecureDriverExcludedZonesService _service;
  
  List<DriverExcludedZone> _unavailableNeighborhoods = [];
  bool _isLoading = true;
  String? _driverId;
  StreamSubscription<List<DriverExcludedZone>>? _neighborhoodsSubscription;

  @override
  void initState() {
    super.initState();
    _service = SecureDriverExcludedZonesService(Supabase.instance.client);
    _loadDriverData();
  }

  @override
  void dispose() {
    _neighborhoodsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user?.userType == 'driver') {
        _driverId = user!.id;
        _setupRealtimeSubscription();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados do motorista: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    if (_driverId == null) return;
    
    _neighborhoodsSubscription?.cancel();
    _neighborhoodsSubscription = _service.streamDriverExcludedZones(_driverId!).listen(
      (neighborhoods) {
        if (mounted) {
          setState(() {
            _unavailableNeighborhoods = neighborhoods;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _showErrorSnackBar('Erro ao carregar bairros: $error');
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _loadUnavailableNeighborhoods() async {
    if (_driverId == null) {
      return;
    }
    
    try {
      final neighborhoods = await _service.getDriverExcludedZones(_driverId!);
      if (mounted) {
        setState(() {
          _unavailableNeighborhoods = neighborhoods;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar bairros indisponíveis: $e');
      }
    }
  }

  Future<void> _addNeighborhood() async {
    if (_driverId == null) {
      return;
    }

    // Verificar limite de 50 zonas
    if (_unavailableNeighborhoods.length >= 50) {
      _showErrorSnackBar('Limite máximo de 50 bairros atingido.');
      return;
    }

    try {
      final result = await Navigator.push<FavoriteLocation>(
        context,
        MaterialPageRoute(
          builder: (context) => const PlacePickerScreen(
            title: 'Selecionar Bairro',

          ),
        ),
      );

      if (result != null && mounted) {
        await _addSelectedNeighborhood(result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao abrir seleção de bairro: $e');
      }
    }
  }

  Future<void> _addSelectedNeighborhood(FavoriteLocation location) async {
    if (_driverId == null) {
      return;
    }

    try {
      // Extrair informações do endereço
      final addressParts = _parseAddress(location.address);
      
      // Validar dados antes de enviar
      final neighborhood = addressParts['neighborhood'] ?? location.name;
      final city = addressParts['city'] ?? 'Cidade não identificada';
      final state = addressParts['state'] ?? 'SP';
      
      // Validação adicional
      if (neighborhood.trim().isEmpty) {
        _showErrorSnackBar('Nome do bairro não pode estar vazio.');
        return;
      }
      
      if (city.trim().isEmpty) {
        _showErrorSnackBar('Nome da cidade não pode estar vazio.');
        return;
      }
      
      if (!_isValidBrazilianState(state)) {
        _showErrorSnackBar('Estado inválido: $state. Usando SP como padrão.');
      }
      
      await _service.addExcludedZone(
        driverId: _driverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: _isValidBrazilianState(state) ? state : 'SP',
      );
      
      if (mounted) {
        _showSuccessSnackBar('Bairro adicionado à lista de indisponíveis!');
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
        _showErrorSnackBar('Erro inesperado ao adicionar bairro. Tente novamente.');
      }
    }
  }

  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',');
    final result = <String, String>{};
    
    if (parts.isNotEmpty) {
      // Primeiro parte geralmente é o nome do local/bairro
      result['neighborhood'] = parts[0].trim();
    }
    
    if (parts.length > 1) {
      // Última parte geralmente contém cidade e estado
      final lastPart = parts.last.trim();
      final cityStateParts = lastPart.split(' - ');
      
      if (cityStateParts.length >= 2) {
        result['city'] = cityStateParts[0].trim();
        final stateCandidate = cityStateParts[1].trim();
        // Validar se o estado é válido antes de atribuir
        if (_isValidBrazilianState(stateCandidate)) {
          result['state'] = stateCandidate.toUpperCase();
        } else {
          result['state'] = 'SP'; // Estado padrão como fallback
        }
      } else {
        // Tentar extrair estado dos últimos caracteres
        final words = lastPart.split(' ');
        if (words.isNotEmpty) {
          final lastWord = words.last;
          if (lastWord.length == 2 && _isValidBrazilianState(lastWord)) {
            result['state'] = lastWord.toUpperCase();
            result['city'] = words.take(words.length - 1).join(' ');
          } else {
            result['city'] = lastPart;
            result['state'] = 'SP'; // Estado padrão como fallback
          }
        }
      }
    }
    
    // Garantir que sempre temos valores válidos
    result['neighborhood'] = result['neighborhood'] ?? 'Bairro não identificado';
    result['city'] = result['city'] ?? 'Cidade não identificada';
    result['state'] = result['state'] ?? 'SP';
    
    return result;
  }
  
  /// Valida se o código/nome do estado é válido para o Brasil
  bool _isValidBrazilianState(String state) {
    final normalizedState = state.toLowerCase().trim();
    
    // Códigos de estado válidos
    const validStateCodes = {
      'ac', 'al', 'ap', 'am', 'ba', 'ce', 'df', 'es', 'go',
      'ma', 'mt', 'ms', 'mg', 'pa', 'pb', 'pr', 'pe', 'pi',
      'rj', 'rn', 'rs', 'ro', 'rr', 'sc', 'sp', 'se', 'to',
    };
    
    // Nomes de estado válidos (alguns exemplos comuns)
    const validStateNames = {
      'acre', 'alagoas', 'amapa', 'amazonas', 'bahia', 'ceara',
      'distrito federal', 'espirito santo', 'goias', 'maranhao',
      'mato grosso', 'mato grosso do sul', 'minas gerais', 'para',
      'paraiba', 'parana', 'pernambuco', 'piaui', 'rio de janeiro',
      'rio grande do norte', 'rio grande do sul', 'rondonia',
      'roraima', 'santa catarina', 'sao paulo', 'sergipe', 'tocantins',
    };
    
    return validStateCodes.contains(normalizedState) || 
           validStateNames.contains(normalizedState);
  }

  Future<void> _removeNeighborhood(DriverExcludedZone neighborhood) async {
    try {
      await _service.removeExcludedZone(neighborhood.id);
      
      if (mounted) {
        _showSuccessSnackBar('Bairro removido da lista de indisponíveis!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao remover bairro: $e');
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

  void _showRemoveConfirmation(DriverExcludedZone neighborhood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Bairro'),
        content: Text(
          'Deseja remover "${neighborhood.neighborhoodName}, ${neighborhood.city} - ${neighborhood.state}" da lista de bairros indisponíveis?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeNeighborhood(neighborhood);
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bairros Indisponíveis'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<DriverExcludedZone>>(
        stream: _driverId != null ? _service.streamDriverExcludedZones(_driverId!) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Erro ao carregar bairros',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final neighborhoods = snapshot.data ?? [];
          
          return Column(
            children: [
              // Header com informações
              Container(
                width: double.infinity,
                margin: AppSpacing.screenMargin,
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          color: colorScheme.onPrimaryContainer,
                          size: AppSpacing.iconMd,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Bairros Indisponíveis',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Selecione os bairros onde você não deseja realizar atendimentos. Use o botão "+" para buscar e adicionar novos bairros à lista.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Bairros cadastrados: ${neighborhoods.length}/50',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de bairros indisponíveis
              Expanded(
                child: neighborhoods.isEmpty
                    ? _buildEmptyState(colorScheme, textTheme)
                    : _buildNeighborhoodsList(neighborhoods, colorScheme, textTheme),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<DriverExcludedZone>>(
        stream: _driverId != null ? _service.streamDriverExcludedZones(_driverId!) : null,
        builder: (context, snapshot) {
          final neighborhoods = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          
          return isLoading
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  onPressed: neighborhoods.length >= 50 ? null : _addNeighborhood,
                  icon: const Icon(Icons.add_location_alt),
                  label: Text(neighborhoods.length >= 50 ? 'Limite Atingido' : 'Adicionar Bairro'),
                  backgroundColor: neighborhoods.length >= 50 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  foregroundColor: neighborhoods.length >= 50 
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) => Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum bairro indisponível',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Você ainda não definiu nenhum bairro como indisponível. Toque no botão "+" para buscar e adicionar.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildNeighborhoodsList(List<DriverExcludedZone> neighborhoods, ColorScheme colorScheme, TextTheme textTheme) => ListView.builder(
      padding: AppSpacing.screenMargin,
      itemCount: neighborhoods.length,
      itemBuilder: (context, index) {
        final neighborhood = neighborhoods[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.errorContainer,
              child: Icon(
                Icons.location_off,
                color: colorScheme.onErrorContainer,
                size: AppSpacing.iconSm,
              ),
            ),
            title: Text(
              neighborhood.neighborhoodName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${neighborhood.city} - ${neighborhood.state}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
              ),
              onPressed: () => _showRemoveConfirmation(neighborhood),
              tooltip: 'Remover bairro indisponível',
            ),
          ),
        );
      },
    );
}