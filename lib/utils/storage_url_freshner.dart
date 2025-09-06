import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class to manage fresh URLs from Supabase Storage
/// Prevents cache dependency by always using signed URLs
class StorageUrlFreshner {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Cache de URLs assinadas para evitar chamadas repetidas
  static final Map<String, _SignedUrlCache> _urlCache = {};

  /// Tempo de expiração das URLs assinadas (55 minutos para renovar antes de expirar)
  static const Duration _signedUrlExpiry = Duration(minutes: 55);

  /// Gera URL assinada fresca para um arquivo no storage
  static Future<String?> getFreshSignedUrl({
    required String bucket,
    required String filePath,
    Duration? expiryDuration,
  }) async {
    try {
      final cacheKey = '$bucket/$filePath';
      final now = DateTime.now();

      // Verifica se temos uma URL válida em cache
      if (_urlCache.containsKey(cacheKey)) {
        final cached = _urlCache[cacheKey]!;
        if (cached.expiresAt.isAfter(now)) {
          print('📎 Usando URL assinada em cache para: $filePath');
          return cached.url;
        }
      }

      // Limpa o path removendo o bucket se estiver incluído
      final cleanPath = filePath.replaceFirst(RegExp(r'^[^/]+/'), '');

      // Gera nova URL assinada
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(
            cleanPath,
            (expiryDuration ?? _signedUrlExpiry).inSeconds,
          );

      // Armazena no cache
      _urlCache[cacheKey] = _SignedUrlCache(
        url: signedUrl,
        expiresAt: now.add(expiryDuration ?? _signedUrlExpiry),
      );

      print('✅ URL assinada gerada para: $filePath');
      return signedUrl;

    } catch (e) {
      print('❌ Erro ao gerar URL assinada: $e');
      return null;
    }
  }

  /// Gera URLs assinadas frescas para múltiplos arquivos
  static Future<Map<String, String>> getFreshSignedUrls({
    required String bucket,
    required List<String> filePaths,
    Duration? expiryDuration,
  }) async {
    final Map<String, String> results = {};

    for (final path in filePaths) {
      final url = await getFreshSignedUrl(
        bucket: bucket,
        filePath: path,
        expiryDuration: expiryDuration,
      );
      
      if (url != null) {
        results[path] = url;
      }
    }

    return results;
  }

  /// Busca documentos do motorista com URLs frescas
  static Future<List<Map<String, dynamic>>> getDriverDocumentsWithFreshUrls(
    String driverId
  ) async {
    try {
      final documents = await _supabase
          .from('driver_documents')
          .select('''
            id,
            document_type,
            file_url,
            file_size,
            mime_type,
            expiry_date,
            status,
            reviewed_at,
            created_at,
            updated_at
          ''')
          .eq('driver_id', driverId)
          .eq('is_current', true)
          .order('created_at', ascending: false);

      // Processa cada documento para ter URL fresca
      final List<Map<String, dynamic>> processedDocs = [];

      for (final doc in documents) {
        final originalUrl = doc['file_url'] as String;
        
        // Extrai o path do storage a partir da URL completa
        final storagePath = _extractStoragePath(originalUrl);
        
        if (storagePath != null) {
          final freshUrl = await getFreshSignedUrl(
            bucket: 'driver-documents',
            filePath: storagePath,
          );

          processedDocs.add({
            ...doc,
            'file_url': freshUrl ?? originalUrl,
            'is_fresh_url': freshUrl != null,
            'original_url': originalUrl,
          });
        } else {
          processedDocs.add(doc);
        }
      }

      return processedDocs;

    } catch (e) {
      print('❌ Erro ao buscar documentos com URLs frescas: $e');
      return [];
    }
  }

  /// Extrai o path do storage a partir da URL completa
  static String? _extractStoragePath(String fullUrl) {
    try {
      final uri = Uri.parse(fullUrl);
      final pathSegments = uri.pathSegments;
      
      // Remove o bucket name do início do path
      if (pathSegments.length > 1) {
        return pathSegments.sublist(1).join('/');
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao extrair path do storage: $e');
      return null;
    }
  }

  /// Limpa o cache de URLs
  static void clearCache() {
    _urlCache.clear();
    print('🧹 Cache de URLs limpo');
  }

  /// Remove uma URL específica do cache
  static void removeFromCache(String bucket, String filePath) {
    final cacheKey = '$bucket/$filePath';
    _urlCache.remove(cacheKey);
    print('🗑️ URL removida do cache: $cacheKey');
  }

  /// Retorna estatísticas do cache
  static Map<String, int> getCacheStats() {
    final now = DateTime.now();
    final validUrls = _urlCache.values.where((cache) => cache.expiresAt.isAfter(now)).length;
    final expiredUrls = _urlCache.values.where((cache) => cache.expiresAt.isBefore(now)).length;

    return {
      'total_cached': _urlCache.length,
      'valid_urls': validUrls,
      'expired_urls': expiredUrls,
    };
  }
}

/// Cache interno para URLs assinadas
class _SignedUrlCache {
  final String url;
  final DateTime expiresAt;

  _SignedUrlCache({
    required this.url,
    required this.expiresAt,
  });
}