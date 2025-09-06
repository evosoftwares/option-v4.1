import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

enum AssetType {
  image,
  audio,
  video,
  data,
}

enum AssetPriority {
  critical,
  high,
  medium,
  low,
}

class AssetInfo {

  const AssetInfo({
    required this.key,
    this.localPath,
    this.cdnUrl,
    required this.type,
    this.priority = AssetPriority.medium,
    this.sizeKB = 0,
    this.isLoaded = false,
    this.lastUsed,
  });
  final String key;
  final String? localPath;
  final String? cdnUrl;
  final AssetType type;
  final AssetPriority priority;
  final double sizeKB;
  final bool isLoaded;
  final DateTime? lastUsed;

  AssetInfo copyWith({
    String? key,
    String? localPath,
    String? cdnUrl,
    AssetType? type,
    AssetPriority? priority,
    double? sizeKB,
    bool? isLoaded,
    DateTime? lastUsed,
  }) => AssetInfo(
    key: key ?? this.key,
    localPath: localPath ?? this.localPath,
    cdnUrl: cdnUrl ?? this.cdnUrl,
    type: type ?? this.type,
    priority: priority ?? this.priority,
    sizeKB: sizeKB ?? this.sizeKB,
    isLoaded: isLoaded ?? this.isLoaded,
    lastUsed: lastUsed ?? this.lastUsed,
  );
}

class DynamicAssetManager {
  factory DynamicAssetManager() => _instance;
  DynamicAssetManager._internal();
  static final DynamicAssetManager _instance = DynamicAssetManager._internal();

  final Map<String, AssetInfo> _assets = {};
  final Map<String, Completer<void>> _loadingAssets = {};
  final Dio _dio = Dio();
  // Usar AppConfig em vez de URL hardcoded
  String get _supabaseUrl => AppConfig.supabaseUrl;
  
  Future<void> initialize() async {
    dev.log('🎨 Inicializando Dynamic Asset Manager...', name: 'AssetManager');
    
    await _registerDefaultAssets();
    await _loadCriticalAssets();
    
    dev.log('✅ Asset Manager inicializado', name: 'AssetManager');
  }

  Future<void> _registerDefaultAssets() async {
    // Imagens críticas (Shell App)
    _assets['logo_horizontal'] = const AssetInfo(
      key: 'logo_horizontal',
      localPath: 'assets/images/logo_horizontal_simple.webp',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Flogo_horizontal.webp?alt=media',
      type: AssetType.image,
      priority: AssetPriority.critical,
      sizeKB: 8,
    );
    
    _assets['logo_vertical'] = const AssetInfo(
      key: 'logo_vertical',
      localPath: 'assets/images/logo_vertical_simple.webp',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Flogo_vertical.webp?alt=media',
      type: AssetType.image,
      priority: AssetPriority.critical,
      sizeKB: 12,
    );
    
    // Imagens carregadas sob demanda
    _assets['passenger_bg'] = const AssetInfo(
      key: 'passenger_bg',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Fpassenger_background.webp?alt=media',
      type: AssetType.image,
      priority: AssetPriority.high,
      sizeKB: 45,
    );
    
    _assets['driver_bg'] = const AssetInfo(
      key: 'driver_bg',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Fdriver_background.webp?alt=media',
      type: AssetType.image,
      priority: AssetPriority.high,
      sizeKB: 50,
    );
    
    // Sons
    _assets['notification_sound'] = const AssetInfo(
      key: 'notification_sound',
      localPath: 'assets/sounds/notification.mp3',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Fnotification.mp3?alt=media',
      type: AssetType.audio,
      sizeKB: 25,
    );
    
    _assets['trip_complete_sound'] = const AssetInfo(
      key: 'trip_complete_sound',
      cdnUrl: 'https://firebasestorage.googleapis.com/v0/b/uber-clone-testing.appspot.com/o/assets%2Ftrip_complete.mp3?alt=media',
      type: AssetType.audio,
      priority: AssetPriority.low,
      sizeKB: 30,
    );
  }

  Future<void> _loadCriticalAssets() async {
    final criticalAssets = _assets.values
        .where((asset) => asset.priority == AssetPriority.critical)
        .toList();
    
    dev.log('📥 Carregando ${criticalAssets.length} assets críticos...', 
        name: 'AssetManager');
    
    final futures = criticalAssets.map((asset) => loadAsset(asset.key));
    await Future.wait(futures);
  }

  Future<bool> loadAsset(String key) async {
    final asset = _assets[key];
    if (asset == null) {
      dev.log('⚠️ Asset não encontrado: $key', name: 'AssetManager');
      return false;
    }

    if (asset.isLoaded) {
      return true;
    }

    if (_loadingAssets.containsKey(key)) {
      await _loadingAssets[key]!.future;
      return _assets[key]?.isLoaded ?? false;
    }

    final completer = Completer<void>();
    _loadingAssets[key] = completer;

    try {
      dev.log('📦 Carregando asset: $key', name: 'AssetManager');
      
      var success = false;
      
      // Tentar carregar do local primeiro
      if (asset.localPath != null) {
        success = await _loadLocalAsset(asset);
      }
      
      // Se falhar ou não tiver local, carregar do CDN
      if (!success && asset.cdnUrl != null) {
        success = await _loadCdnAsset(asset);
      }

      if (success) {
        _assets[key] = asset.copyWith(
          isLoaded: true,
          lastUsed: DateTime.now(),
        );
        
        await _saveAssetCache(key);
        dev.log('✅ Asset carregado: $key', name: 'AssetManager');
      } else {
        dev.log('❌ Falha ao carregar asset: $key', name: 'AssetManager');
      }

      completer.complete();
      return success;
    } catch (e) {
      dev.log('❌ Erro ao carregar asset $key: $e', name: 'AssetManager');
      completer.completeError(e);
      return false;
    } finally {
      _loadingAssets.remove(key);
    }
  }

  Future<bool> _loadLocalAsset(AssetInfo asset) async {
    try {
      if (asset.type == AssetType.image && asset.localPath != null) {
        // Verificar se o asset existe localmente
        final data = await rootBundle.load(asset.localPath!);
        return data.lengthInBytes > 0;
      }
      return false;
    } catch (e) {
      dev.log('⚠️ Asset local não encontrado: ${asset.localPath}', 
          name: 'AssetManager');
      return false;
    }
  }

  Future<bool> _loadCdnAsset(AssetInfo asset) async {
    try {
      final url = _supabaseUrl + asset.cdnUrl!;
      
      dev.log('🌐 Baixando de CDN: $url', name: 'AssetManager');
      
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200) {
        // Em implementação real, salvaria o asset no cache local
        dev.log('✅ Asset baixado do CDN: ${asset.key}', name: 'AssetManager');
        return true;
      }
      
      return false;
    } catch (e) {
      dev.log('❌ Erro ao baixar asset do CDN: $e', name: 'AssetManager');
      return false;
    }
  }

  Future<void> preloadAssets(List<String> keys) async {
    dev.log('🎯 Preload de ${keys.length} assets...', name: 'AssetManager');
    
    final futures = keys.map(loadAsset);
    await Future.wait(futures);
  }

  Widget buildOptimizedImage(String key, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final asset = _assets[key];
    
    if (asset == null || asset.type != AssetType.image) {
      return errorWidget ?? _buildErrorWidget(key);
    }

    if (!asset.isLoaded) {
      // Carregar asset assincronamente
      loadAsset(key);
      return placeholder ?? _buildPlaceholder(asset);
    }

    // Asset carregado - usar local primeiro, depois CDN
    if (asset.localPath != null) {
      return Image.asset(
        asset.localPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (asset.cdnUrl != null) {
            final url = _supabaseUrl + asset.cdnUrl!;
            return Image.network(
              url,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => 
                  errorWidget ?? _buildErrorWidget(key),
            );
          }
          return errorWidget ?? _buildErrorWidget(key);
        },
      );
    } else if (asset.cdnUrl != null) {
      final url = _supabaseUrl + asset.cdnUrl!;
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => 
            errorWidget ?? _buildErrorWidget(key),
      );
    }

    return errorWidget ?? _buildErrorWidget(key);
  }

  Widget _buildPlaceholder(AssetInfo asset) => DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 8),
          Text(
            'Carregando...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (asset.sizeKB > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${asset.sizeKB.toStringAsFixed(1)}KB',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );

  Widget _buildErrorWidget(String key) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red[400]),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            key,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

  Future<void> _saveAssetCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('asset_loaded_$key', true);
      await prefs.setInt('asset_last_used_$key', 
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      dev.log('⚠️ Erro ao salvar cache do asset $key: $e', name: 'AssetManager');
    }
  }

  void recordAssetUsage(String key) {
    final asset = _assets[key];
    if (asset != null) {
      _assets[key] = asset.copyWith(lastUsed: DateTime.now());
      _saveAssetCache(key);
    }
  }

  List<AssetInfo> getAssetsByType(AssetType type) => _assets.values.where((asset) => asset.type == type).toList();

  List<AssetInfo> getAssetsByPriority(AssetPriority priority) => _assets.values.where((asset) => asset.priority == priority).toList();

  double getTotalCacheSize() => _assets.values
        .where((asset) => asset.isLoaded)
        .fold(0, (sum, asset) => sum + asset.sizeKB);

  void dispose() {
    _assets.clear();
    _loadingAssets.clear();
    _dio.close();
    dev.log('🧹 Asset Manager disposed', name: 'AssetManager');
  }
}