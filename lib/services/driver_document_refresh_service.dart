import 'package:supabase_flutter/supabase_flutter.dart';

class DriverDocumentRefreshService {
  final SupabaseClient _supabase;

  DriverDocumentRefreshService(this._supabase);

  /// Busca URLs frescas dos documentos do motorista
  /// Evita dependência de cache ao sempre buscar do Supabase Storage
  Future<Map<String, String>> getFreshDocumentUrls(String driverId) async {
    try {
      // Busca documentos atuais do motorista
      final response = await _supabase
          .from('driver_documents')
          .select('id, document_type, file_url, updated_at')
          .eq('driver_id', driverId)
          .eq('is_current', true)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return {};
      }

      final Map<String, String> freshUrls = {};

      for (final doc in response) {
        final documentType = doc['document_type'] as String;
        final fileUrl = doc['file_url'] as String;
        final docId = doc['id'] as String;

        // Gera URL assinada fresca do Supabase Storage
        final freshUrl = await _getSignedUrl(fileUrl, docId);
        
        if (freshUrl != null) {
          freshUrls[documentType] = freshUrl;
        }
      }

      return freshUrls;
    } catch (e) {
      print('Erro ao buscar URLs frescas dos documentos: $e');
      return {};
    }
  }

  /// Gera URL assinada fresca do Supabase Storage
  Future<String?> _getSignedUrl(String filePath, String docId) async {
    try {
      // Remove o bucket da URL se presente
      final cleanPath = filePath.replaceFirst(RegExp(r'^[^/]+/'), '');
      
      // Gera URL assinada válida por 1 hora
      final response = await _supabase.storage
          .from('driver-documents')
          .createSignedUrl(cleanPath, 3600); // 1 hour

      return response;
    } catch (e) {
      print('Erro ao gerar URL assinada para documento $docId: $e');
      return null;
    }
  }

  /// Busca URL fresca para um tipo específico de documento
  Future<String?> getFreshDocumentUrl(
    String driverId, 
    String documentType
  ) async {
    try {
      final response = await _supabase
          .from('driver_documents')
          .select('id, file_url')
          .eq('driver_id', driverId)
          .eq('document_type', documentType)
          .eq('is_current', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      final doc = response.first;
      final fileUrl = doc['file_url'] as String;
      final docId = doc['id'] as String;

      return await _getSignedUrl(fileUrl, docId);
    } catch (e) {
      print('Erro ao buscar URL fresca para $documentType: $e');
      return null;
    }
  }

  /// Invalida URLs antigas e força busca de novas
  Future<void> invalidateDocumentUrls(String driverId) async {
    try {
      // Chama a função do Supabase para invalidar URLs
      await _supabase.rpc('invalidate_driver_document_urls', params: {
        'target_driver_id': driverId,
      });
    } catch (e) {
      print('Erro ao invalidar URLs dos documentos: $e');
    }
  }

  /// Busca documentos com URLs garantidamente frescas
  Future<List<Map<String, dynamic>>> getDocumentsWithFreshUrls(
    String driverId
  ) async {
    try {
      // Primeiro, invalida URLs antigas
      await invalidateDocumentUrls(driverId);

      // Depois busca documentos com URLs frescas
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

      // Substitui URLs por versões assinadas frescas
      final List<Map<String, dynamic>> documentsWithFreshUrls = [];
      
      for (final doc in documents) {
        final freshUrl = await _getSignedUrl(
          doc['file_url'] as String, 
          doc['id'] as String
        );
        
        if (freshUrl != null) {
          documentsWithFreshUrls.add({
            ...doc,
            'file_url': freshUrl,
            'is_fresh_url': true,
          });
        }
      }

      return documentsWithFreshUrls;
    } catch (e) {
      print('Erro ao buscar documentos com URLs frescas: $e');
      return [];
    }
  }
}