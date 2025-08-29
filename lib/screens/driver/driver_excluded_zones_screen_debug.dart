import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/driver_excluded_zone.dart';
import '../../services/driver_excluded_zones_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';

/// Versão melhorada da tela de zonas excluídas com debug e melhor gerenciamento de estado
class DriverExcludedZonesScreenDebug extends StatefulWidget {
  const DriverExcludedZonesScreenDebug({super.key});

  static const routeName = '/driver_excluded_zones_debug';

  @override
  State<DriverExcludedZonesScreenDebug> createState() => _DriverExcludedZonesScreenDebugState();
}

class _DriverExcludedZonesScreenDebugState extends State<DriverExcludedZonesScreenDebug> {
  late final DriverExcludedZonesService _service;
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<DriverExcludedZone> _excludedZones = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  String? _driverId;
  final List<String> _debugLogs = [];
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _service = DriverExcludedZonesService(Supabase.instance.client);
    _addDebugLog('🚀 Iniciando tela de zonas excluídas');
    _loadDriverData();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    setState(() {
      _debugLogs.insert(0, logMessage);
      if (_debugLogs.length > 20) {
        _debugLogs.removeLast();
      }
    });
  }

  Future<void> _loadDriverData() async {
    _addDebugLog('📋 Carregando dados do motorista...');
    try {
      final user = await UserService.getCurrentUser();
      if (user?.userType == 'driver') {
        _driverId = user!.id;
        _addDebugLog('✅ Driver ID obtido: $_driverId');
        await _loadExcludedZones();
      } else {
        _addDebugLog('❌ Usuário não é motorista');
      }
    } catch (e) {
      _addDebugLog('❌ Erro ao carregar dados do motorista: $e');
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

  Future<void> _loadExcludedZones({bool isRefresh = false}) async {
    if (_driverId == null) {
      _addDebugLog('⚠️ Driver ID não disponível para carregar zonas');
      return;
    }
    
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    _refreshCount++;
    _addDebugLog('🔄 Carregando zonas excluídas (refresh #$_refreshCount)...');
    
    try {
      final zones = await _service.getDriverExcludedZones(_driverId!);
      _addDebugLog('✅ ${zones.length} zonas carregadas');
      
      if (mounted) {
        setState(() {
          _excludedZones = zones;
          if (isRefresh) {
            _isRefreshing = false;
          }
        });
        
        // Log detalhado das zonas
        for (final zone in zones) {
          _addDebugLog('   - ${zone.displayName} (ID: ${zone.id.substring(0, 8)}...)');
        }
      }
    } catch (e) {
      _addDebugLog('❌ Erro ao carregar zonas: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar zonas excluídas: $e');
        if (isRefresh) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    }
  }

  Future<void> _addExcludedZone() async {
    if (!_formKey.currentState!.validate() || _driverId == null) {
      _addDebugLog('⚠️ Validação falhou ou driver ID não disponível');
      return;
    }

    final neighborhood = _neighborhoodController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    
    _addDebugLog('➕ Iniciando adição de zona: $neighborhood, $city - $state');

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Verificar se já existe antes de adicionar
      final isAlreadyExcluded = await _service.isZoneExcluded(
        driverId: _driverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );
      
      if (isAlreadyExcluded) {
        _addDebugLog('⚠️ Zona já existe na lista');
        _showErrorSnackBar('Esta zona já está na sua lista de exclusões.');
        return;
      }
      
      _addDebugLog('📝 Adicionando zona no banco...');
      final addedZone = await _service.addExcludedZone(
        driverId: _driverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );
      
      _addDebugLog('✅ Zona adicionada com ID: ${addedZone.id.substring(0, 8)}...');
      
      // Limpar formulário
      _neighborhoodController.clear();
      _cityController.clear();
      _stateController.clear();
      
      // Aguardar um pouco antes de recarregar (para garantir consistência)
      _addDebugLog('⏱️ Aguardando 500ms antes de recarregar...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Recarregar zonas
      _addDebugLog('🔄 Recarregando lista de zonas...');
      await _loadExcludedZones();
      
      // Verificar se a zona foi realmente adicionada
      final wasAdded = _excludedZones.any((z) => 
        z.neighborhoodName == neighborhood && 
        z.city == city && 
        z.state == state,
      );
      
      if (wasAdded) {
        _addDebugLog('✅ Zona confirmada na lista após reload');
        if (mounted) {
          _showSuccessSnackBar('Zona excluída adicionada com sucesso!');
        }
      } else {
        _addDebugLog('❌ Zona NÃO encontrada na lista após reload!');
        // Tentar recarregar novamente
        _addDebugLog('🔄 Tentando recarregar novamente...');
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadExcludedZones();
        
        final wasAddedSecondTry = _excludedZones.any((z) => 
          z.neighborhoodName == neighborhood && 
          z.city == city && 
          z.state == state,
        );
        
        if (wasAddedSecondTry) {
          _addDebugLog('✅ Zona encontrada na segunda tentativa');
          if (mounted) {
            _showSuccessSnackBar('Zona excluída adicionada com sucesso!');
          }
        } else {
          _addDebugLog('❌ Zona ainda não encontrada após segunda tentativa');
          if (mounted) {
            _showErrorSnackBar('Zona foi salva mas não aparece na lista. Tente atualizar.');
          }
        }
      }
      
    } catch (e) {
      _addDebugLog('❌ Erro ao adicionar zona: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao adicionar zona excluída: $e');
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
    _addDebugLog('🗑️ Removendo zona: ${zone.displayName}');
    
    try {
      await _service.removeExcludedZone(zone.id);
      _addDebugLog('✅ Zona removida do banco');
      
      // Aguardar um pouco antes de recarregar
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadExcludedZones();
      
      _addDebugLog('✅ Lista recarregada após remoção');
      
      if (mounted) {
        _showSuccessSnackBar('Zona excluída removida com sucesso!');
      }
    } catch (e) {
      _addDebugLog('❌ Erro ao remover zona: $e');
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
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Zona Excluída'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  hintText: 'Ex: Centro, Copacabana',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o bairro';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  hintText: 'Ex: Rio de Janeiro, São Paulo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe a cidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  hintText: 'Ex: RJ, SP, MG',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o estado';
                  }
                  if (value.trim().length != 2) {
                    return 'Estado deve ter 2 caracteres (ex: SP)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () {
              Navigator.of(context).pop();
              _addExcludedZone();
            },
            child: _isSubmitting 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _debugLogs.length,
            itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _debugLogs[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(_debugLogs.clear);
              Navigator.of(context).pop();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Zonas Excluídas (Debug)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showDebugLogs,
            tooltip: 'Ver logs de debug',
          ),
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () => _loadExcludedZones(isRefresh: true),
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    'Driver: ${_driverId?.substring(0, 8) ?? "N/A"}... | '
                    'Zonas: ${_excludedZones.length} | '
                    'Refreshes: $_refreshCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                
                // Lista de zonas
                Expanded(
                  child: _excludedZones.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: AppColors.gray600,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Nenhuma zona excluída',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.gray600,
                                ),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Adicione zonas onde você não deseja receber corridas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _excludedZones.length,
                          itemBuilder: (context, index) {
                            final zone = _excludedZones[index];
                            return AppCard(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: const Icon(Icons.location_off),
                                title: Text(zone.displayName),
                                subtitle: Text(
                                  'Adicionado em ${zone.createdAt.day}/${zone.createdAt.month}/${zone.createdAt.year}\n'
                                  'ID: ${zone.id.substring(0, 8)}...',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                  onPressed: () => _removeExcludedZone(zone),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _showAddZoneDialog,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Icon(Icons.add),
      ),
    );
}