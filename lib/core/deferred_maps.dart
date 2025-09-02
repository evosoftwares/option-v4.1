import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SimpleMapsWidget extends StatefulWidget {
  
  const SimpleMapsWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.onMapTap,
  });
  final double latitude;
  final double longitude;
  final String? title;
  final VoidCallback? onMapTap;

  @override
  State<SimpleMapsWidget> createState() => _SimpleMapsWidgetState();
}

class _SimpleMapsWidgetState extends State<SimpleMapsWidget> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading
          ? _buildLoadingMap()
          : _buildStaticMap(),
    );
  
  Widget _buildLoadingMap() => const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando Google Maps...'),
            Text('Lazy loading em progresso'),
          ],
        ),
      ),
    );
  
  Widget _buildStaticMap() => GestureDetector(
      onTap: () async {
        if (widget.onMapTap != null) {
          widget.onMapTap!();
        } else {
          await _loadFullMap();
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.blue[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Icon(
                Icons.map,
                size: 64,
                color: Colors.blue,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Toque para carregar mapa',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Lazy Load',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  
  Future<void> _loadFullMap() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      dev.log('🗺️ Carregando Google Maps completo...', name: 'DeferredMaps');
      
      // Simular carregamento do Google Maps
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Em implementação real, aqui carregaria o widget do Google Maps
        await _showFullMapDialog();
      }
    } catch (e) {
      dev.log('❌ Erro ao carregar mapa: $e', name: 'DeferredMaps');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar mapa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _showFullMapDialog() async => showDialog(
      context: context,
      builder: (context) => Dialog(
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Google Maps Carregado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Google Maps Ativo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Localização: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                '✅ Módulo carregado dinamicamente',
                                style: TextStyle(color: Colors.green),
                              ),
                              Text(
                                '🚀 Shell App - Otimizado',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
}

class DeferredLocationService {
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      dev.log('❌ Erro ao obter localização: $e', name: 'DeferredLocationService');
      return null;
    }
  }

  static Map<String, double> getDefaultLocation() {
    // São Paulo, Brasil - localização padrão
    return {
      'latitude': -23.5505,
      'longitude': -46.6333,
    };
  }
}