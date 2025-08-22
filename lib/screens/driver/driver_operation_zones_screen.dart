import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase/driver_operation_zone.dart';
import '../../services/driver_operation_zones_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DriverOperationZonesScreen extends StatefulWidget {
  const DriverOperationZonesScreen({super.key});

  static const routeName = '/driver_operation_zones';

  @override
  State<DriverOperationZonesScreen> createState() => _DriverOperationZonesScreenState();
}

class _DriverOperationZonesScreenState extends State<DriverOperationZonesScreen> {
  late final DriverOperationZonesService _service;
  GoogleMapController? _mapController;
  
  List<DriverOperationZone> _operationZones = [];
  List<LatLng> _currentPolygonPoints = [];
  bool _isLoading = true;
  bool _isDrawingMode = false;
  String? _driverId;
  
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};

  // Cores para os polígonos
  static const List<Color> _polygonColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _service = DriverOperationZonesService(Supabase.instance.client);
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user?.userType == 'driver') {
        _driverId = user!.id;
        await _loadOperationZones();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOperationZones() async {
    if (_driverId == null) return;

    try {
      final zones = await _service.getDriverOperationZones(_driverId!);
      if (mounted) {
        setState(() {
          _operationZones = zones;
          _updateMapPolygons();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar áreas: $e');
      }
    }
  }

  void _updateMapPolygons() {
    _polygons.clear();
    
    for (int i = 0; i < _operationZones.length; i++) {
      final zone = _operationZones[i];
      final color = _polygonColors[i % _polygonColors.length];
      
      _polygons.add(
        Polygon(
          polygonId: PolygonId(zone.id),
          points: zone.polygonCoordinates,
          strokeColor: color,
          strokeWidth: 2,
          fillColor: color.withOpacity(zone.isActive ? 0.3 : 0.1),
          consumeTapEvents: true,
          onTap: () => _showZoneDetails(zone),
        ),
      );
    }

    // Adicionar polígono em construção
    if (_currentPolygonPoints.isNotEmpty) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('current_drawing'),
          points: _currentPolygonPoints,
          strokeColor: Colors.black,
          strokeWidth: 3,
          fillColor: Colors.black.withOpacity(0.2),
        ),
      );
    }
  }

  void _onMapTap(LatLng point) {
    if (!_isDrawingMode) return;

    setState(() {
      _currentPolygonPoints.add(point);
      _updateMapPolygons();
      
      // Adicionar marcador para o ponto
      _markers.add(
        Marker(
          markerId: MarkerId('point_${_currentPolygonPoints.length}'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _currentPolygonPoints.clear();
        _markers.clear();
        _updateMapPolygons();
      }
    });
  }

  void _finishDrawing() {
    if (_currentPolygonPoints.length < 3) {
      _showErrorSnackBar('A área deve ter pelo menos 3 pontos');
      return;
    }

    _showCreateZoneDialog();
  }

  void _undoLastPoint() {
    if (_currentPolygonPoints.isNotEmpty) {
      setState(() {
        _currentPolygonPoints.removeLast();
        if (_markers.isNotEmpty) {
          final lastMarker = _markers.last;
          _markers.remove(lastMarker);
        }
        _updateMapPolygons();
      });
    }
  }

  void _showCreateZoneDialog() {
    final nameController = TextEditingController();
    final multiplierController = TextEditingController(text: '1.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Área de Atuação'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da área',
                  hintText: 'Ex: Centro, Zona Sul',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome da área';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: multiplierController,
                decoration: const InputDecoration(
                  labelText: 'Multiplicador de preço',
                  hintText: '1.0 = normal, 1.5 = +50%',
                  suffixText: 'x',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o multiplicador';
                  }
                  final multiplier = double.tryParse(value);
                  if (multiplier == null || multiplier < 0.1 || multiplier > 10.0) {
                    return 'Multiplicador deve estar entre 0.1 e 10.0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Área: ${_currentPolygonPoints.length} pontos',
                style: AppTypography.bodySmall,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _createZone(
                  nameController.text.trim(),
                  double.parse(multiplierController.text),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createZone(String name, double multiplier) async {
    if (_driverId == null) return;

    try {
      await _service.addOperationZone(
        driverId: _driverId!,
        zoneName: name,
        polygonCoordinates: _currentPolygonPoints,
        priceMultiplier: multiplier,
      );

      setState(() {
        _isDrawingMode = false;
        _currentPolygonPoints.clear();
        _markers.clear();
      });

      await _loadOperationZones();
      _showSuccessSnackBar('Área criada com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao criar área: $e');
    }
  }

  void _showZoneDetails(DriverOperationZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone.zoneName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.close, size: 16),
                const SizedBox(width: 4),
                Text('Multiplicador: ${zone.formattedMultiplier}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  zone.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: zone.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(zone.isActive ? 'Ativa' : 'Inativa'),
              ],
            ),
            const SizedBox(height: 8),
            Text('${zone.polygonCoordinates.length} pontos'),
            const SizedBox(height: 8),
            Text('Área aprox.: ${zone.approximateAreaKm2.toStringAsFixed(1)} km²'),
            const SizedBox(height: 8),
            Text(zone.multiplierDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleZoneStatus(zone);
            },
            child: Text(zone.isActive ? 'Desativar' : 'Ativar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteZone(zone);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleZoneStatus(DriverOperationZone zone) async {
    try {
      await _service.toggleZoneStatus(zone.id, !zone.isActive);
      await _loadOperationZones();
      _showSuccessSnackBar(
        zone.isActive ? 'Área desativada' : 'Área ativada',
      );
    } catch (e) {
      _showErrorSnackBar('Erro ao alterar status: $e');
    }
  }

  Future<void> _deleteZone(DriverOperationZone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a área "${zone.zoneName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.removeOperationZone(zone.id);
        await _loadOperationZones();
        _showSuccessSnackBar('Área excluída com sucesso!');
      } catch (e) {
        _showErrorSnackBar('Erro ao excluir área: $e');
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
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas de Atuação'),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.close : Icons.add),
            onPressed: _toggleDrawingMode,
            tooltip: _isDrawingMode ? 'Cancelar desenho' : 'Nova área',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isDrawingMode) _buildDrawingControls(),
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: _onMapTap,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-23.5505, -46.6333), // São Paulo
                      zoom: 11,
                    ),
                    polygons: _polygons,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                _buildZonesList(),
              ],
            ),
    );
  }

  Widget _buildDrawingControls() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _currentPolygonPoints.isEmpty
                  ? 'Toque no mapa para adicionar pontos'
                  : '${_currentPolygonPoints.length} pontos adicionados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (_currentPolygonPoints.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastPoint,
              tooltip: 'Desfazer último ponto',
            ),
            ElevatedButton(
              onPressed: _currentPolygonPoints.length >= 3 ? _finishDrawing : null,
              child: const Text('Finalizar'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    if (_operationZones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const Text(
          'Nenhuma área criada ainda.\nToque no + para criar sua primeira área.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: _operationZones.length,
        itemBuilder: (context, index) {
          final zone = _operationZones[index];
          final color = _polygonColors[index % _polygonColors.length];
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: Card(
              child: InkWell(
                onTap: () => _showZoneDetails(zone),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              zone.zoneName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zone.formattedMultiplier,
                        style: AppTypography.bodyLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            zone.isActive ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: zone.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            zone.isActive ? 'Ativa' : 'Inativa',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}