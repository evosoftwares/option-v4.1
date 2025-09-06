import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/supabase/driver_document.dart';
import '../utils/supabase_helper.dart';
import 'firebase_file_upload_service.dart';

class DriverDocumentService {
  static SupabaseClient get _supabase {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw Exception('Supabase não foi inicializado. Verifique a configuração antes de usar DriverDocumentService.');
    }
    return client;
  }
  static const String _tableName = 'driver_documents';
  // Firebase Storage - não precisa de bucket específico

  /// Cria um novo documento do motorista
  static Future<DriverDocument> createDocument({
    required String driverId,
    required DocumentType documentType,
    required File imageFile,
    DateTime? expiryDate,
  }) async {
    print('🔄 DriverDocumentService.createDocument iniciado');
    print('  - driverId: $driverId');
    print('  - documentType: $documentType');
    print('  - expiryDate: $expiryDate');

    try {
      // Validar se a imagem é válida
      final isValid = await FirebaseFileUploadService.isValidImage(imageFile);
      if (!isValid) {
        throw DocumentException('Arquivo de imagem inválido');
      }

      // Obter informações da imagem
      final imageInfo = await FirebaseFileUploadService.getImageInfo(imageFile);
      if (imageInfo == null) {
        throw DocumentException('Não foi possível obter informações da imagem');
      }

      // Gerar caminho único para o arquivo
      final fileName = imageFile.path.split('/').last;
      final filePath = FirebaseFileUploadService.generateDriverDocumentPath(
        userId: driverId,
        documentType: documentType.name,
        fileName: fileName,
      );

      print('🔄 Fazendo upload da imagem...');
      // Fazer upload da imagem
      final fileUrl = await FirebaseFileUploadService.uploadImage(
        file: imageFile,
        folder: 'driver-documents',
        path: filePath,
      );

      print('✅ Upload concluído: $fileUrl');

      // Marcar documentos anteriores do mesmo tipo como não atuais
      await _markPreviousDocumentsAsNotCurrent(driverId, documentType);

      // Criar registro no banco de dados
      final documentData = {
        'driver_id': driverId,
        'document_type': documentType.value,
        'file_url': fileUrl,
        'file_size': imageInfo['size'],
        'mime_type': imageInfo['mimeType'],
        'expiry_date': expiryDate?.toIso8601String(),
        'status': DocumentStatus.pending.name,
        'is_current': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('🔄 Criando registro no banco de dados...');
      print('📋 Dados que serão enviados:');
      print('   - document_type: ${documentType.value}');
      print('   - driver_id: $driverId');
      print('   - file_url: $fileUrl');
      print('   - status: ${DocumentStatus.pending.name}');
      
      // Verificar se o driver_id existe na tabela drivers
      print('🔍 Verificando se driver_id existe na tabela drivers...');
      final driverCheck = await _supabase
          .from('drivers')
          .select('id, user_id')
          .eq('id', driverId)
          .maybeSingle();
      
      if (driverCheck == null) {
        print('❌ ERRO: driver_id $driverId NÃO EXISTE na tabela drivers!');
        throw DocumentException('Driver ID $driverId não encontrado na tabela drivers');
      } else {
        print('✅ Driver encontrado: id=${driverCheck['id']}, user_id=${driverCheck['user_id']}');
      }
      final response = await _supabase
          .from(_tableName)
          .insert(documentData)
          .select()
          .single();

      print('✅ Documento criado com sucesso: ${response['id']}');
      return DriverDocument.fromJson(response);

    } on PostgrestException catch (e) {
      print('❌ Erro do banco de dados: ${e.message}');
      throw DocumentException('Erro ao salvar documento: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      if (e is DocumentException) rethrow;
      throw DocumentException('Erro inesperado ao criar documento: $e');
    }
  }

  /// Lista todos os documentos de um motorista
  static Future<List<DriverDocument>> getDriverDocuments(String driverId) async {
    print('🔄 DriverDocumentService.getDriverDocuments iniciado');
    print('  - driverId: $driverId');

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      print('✅ Documentos encontrados: ${response.length}');
      return response.map(DriverDocument.fromJson).toList();

    } on PostgrestException catch (e) {
      print('❌ Erro ao buscar documentos: ${e.message}');
      throw DocumentException('Erro ao buscar documentos: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DocumentException('Erro inesperado ao buscar documentos: $e');
    }
  }

  /// Obtém os documentos atuais de um motorista (um por tipo) com URLs frescas
  static Future<List<DriverDocument>> getCurrentDriverDocuments(String driverId) async {
    print('🔄 DriverDocumentService.getCurrentDriverDocuments iniciado');
    print('  - driverId: $driverId');

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('driver_id', driverId)
          .eq('is_current', true)
          .order('created_at', ascending: false);

      final documents = response.map(DriverDocument.fromJson).toList();
      
      // Atualiza URLs para versões assinadas frescas
      for (int i = 0; i < documents.length; i++) {
        final freshUrl = await _getFreshSignedUrl(documents[i].fileUrl, documents[i].id);
        if (freshUrl != null) {
          documents[i] = documents[i].copyWith(fileUrl: freshUrl);
        }
      }

      print('✅ Documentos atuais encontrados com URLs frescas: ${documents.length}');
      return documents;

    } on PostgrestException catch (e) {
      print('❌ Erro ao buscar documentos atuais: ${e.message}');
      throw DocumentException('Erro ao buscar documentos atuais: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DocumentException('Erro inesperado ao buscar documentos atuais: $e');
    }
  }

  /// Obtém um documento específico por tipo
  static Future<DriverDocument?> getDocumentByType(String driverId, DocumentType documentType) async {
    print('🔄 DriverDocumentService.getDocumentByType iniciado');
    print('  - driverId: $driverId');
    print('  - documentType: $documentType');

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('driver_id', driverId)
          .eq('document_type', documentType.value)
          .eq('is_current', true)
          .maybeSingle();

      if (response == null) {
        print('ℹ️ Documento não encontrado');
        return null;
      }

      print('✅ Documento encontrado: ${response['id']}');
      return DriverDocument.fromJson(response);

    } on PostgrestException catch (e) {
      print('❌ Erro ao buscar documento: ${e.message}');
      throw DocumentException('Erro ao buscar documento: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DocumentException('Erro inesperado ao buscar documento: $e');
    }
  }

  /// Atualiza o status de um documento
  static Future<DriverDocument> updateDocumentStatus({
    required String documentId,
    required DocumentStatus status,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    print('🔄 DriverDocumentService.updateDocumentStatus iniciado');
    print('  - documentId: $documentId');
    print('  - status: $status');
    print('  - rejectionReason: $rejectionReason');

    try {
      final updateData = {
        'status': status.name,
        'rejection_reason': rejectionReason,
        'reviewed_by': reviewedBy,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', documentId)
          .select()
          .single();

      print('✅ Status do documento atualizado');
      return DriverDocument.fromJson(response);

    } on PostgrestException catch (e) {
      print('❌ Erro ao atualizar status: ${e.message}');
      throw DocumentException('Erro ao atualizar status: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DocumentException('Erro inesperado ao atualizar status: $e');
    }
  }

  /// Remove um documento (marca como não atual e remove arquivo)
  static Future<bool> deleteDocument(String documentId) async {
    print('🔄 DriverDocumentService.deleteDocument iniciado');
    print('  - documentId: $documentId');

    try {
      // Buscar o documento para obter a URL do arquivo
      final docResponse = await _supabase
          .from(_tableName)
          .select('file_url')
          .eq('id', documentId)
          .single();

      final fileUrl = docResponse['file_url'] as String;
      
      // Extrair o caminho do arquivo da URL do Firebase Storage
      final fileName = fileUrl.split('/').last.split('?').first; // Remove query parameters
      
      // Remover arquivo do Firebase Storage
      await FirebaseFileUploadService.deleteFile(
        folder: 'driver-documents',
        path: fileName,
      );

      // Marcar documento como não atual
      await _supabase
          .from(_tableName)
          .update({
            'is_current': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);

      print('✅ Documento removido com sucesso');
      return true;

    } on PostgrestException catch (e) {
      print('❌ Erro ao remover documento: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Erro inesperado: $e');
      return false;
    }
  }

  /// Verifica se um motorista tem todos os documentos obrigatórios
  static Future<Map<String, dynamic>> getDocumentationStatus(String driverId) async {
    print('🔄 DriverDocumentService.getDocumentationStatus iniciado');
    print('  - driverId: $driverId');

    try {
      final documents = await getCurrentDriverDocuments(driverId);
      print('📋 Documentos encontrados: ${documents.length}');
      for (final doc in documents) {
        print('  - ${doc.documentType}: ${doc.status} (current: ${doc.isCurrent})');
      }
      
      // Buscar dados do driver para obter data de criação
      final driverResponse = await _supabase
          .from('drivers')
          .select('created_at')
          .eq('id', driverId)
          .single();
      
      final driverCreatedAt = DateTime.parse(driverResponse['created_at'] as String);
      
      // Documentos obrigatórios (remover CNH e CRLV da lista de documentos a serem enviados)
      final requiredTypes = [
        DocumentType.vehicleFront,
        DocumentType.vehicleBack,
        DocumentType.vehicleLeft,
        DocumentType.vehicleRight,
        DocumentType.vehicleInterior,
      ];

      final documentsByType = <String, DriverDocument>{};
      for (final doc in documents) {
        documentsByType[doc.documentType] = doc;
      }

      final missingDocuments = <String>[];
      final pendingDocuments = <String>[];
      final rejectedDocuments = <String>[];
      final approvedDocuments = <String>[];
      final expiredDocuments = <String>[];

      for (final type in requiredTypes) {
        final typeName = type.value;  // Usar .value em vez de .name
        final doc = documentsByType[typeName];
        
        if (doc == null) {
          missingDocuments.add(typeName);
        } else {
          // Verificar se está expirado
          if (doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now())) {
            expiredDocuments.add(typeName);
          } else {
            switch (doc.status) {
              case 'pending':
                pendingDocuments.add(typeName);
                break;
              case 'approved':
                approvedDocuments.add(typeName);
                break;
              case 'rejected':
                rejectedDocuments.add(typeName);
                break;
            }
          }
        }
      }

      // Verificar CNH e CRLV na tabela driver_documents
      final cnhFrontDoc = documentsByType[DocumentType.cnhFront.value];
      final cnhBackDoc = documentsByType[DocumentType.cnhBack.value];
      final crlvDoc = documentsByType[DocumentType.crlv.value];
      
      if (cnhFrontDoc != null && cnhFrontDoc.status == 'approved' &&
          cnhBackDoc != null && cnhBackDoc.status == 'approved') {
        approvedDocuments.addAll([DocumentType.cnhFront.value, DocumentType.cnhBack.value]);
      }
      
      if (crlvDoc != null && crlvDoc.status == 'approved') {
        approvedDocuments.add(DocumentType.crlv.value);
      }

      final isComplete = missingDocuments.isEmpty && 
                        pendingDocuments.isEmpty && 
                        rejectedDocuments.isEmpty && 
                        expiredDocuments.isEmpty;

      final result = {
        'isComplete': isComplete,
        'totalRequired': requiredTypes.length + 3, // Adicionar CNH (frente e verso) e CRLV
        'totalApproved': approvedDocuments.length,
        'missingDocuments': missingDocuments,
        'pendingDocuments': pendingDocuments,
        'rejectedDocuments': rejectedDocuments,
        'expiredDocuments': expiredDocuments,
        'approvedDocuments': approvedDocuments,
      };

      print('✅ Status da documentação calculado:');
      print('  - isComplete: $isComplete');
      print('  - totalRequired: ${requiredTypes.length + 3}');
      print('  - totalApproved: ${approvedDocuments.length}');
      print('  - approvedDocuments: $approvedDocuments');
      print('  - pendingDocuments: $pendingDocuments'); 
      print('  - missingDocuments: $missingDocuments');
      print('  - rejectedDocuments: $rejectedDocuments');
      return result;

    } catch (e) {
      print('❌ Erro ao verificar status da documentação: $e');
      throw DocumentException('Erro ao verificar status da documentação: $e');
    }
  }

  /// Marca documentos anteriores do mesmo tipo como não atuais
  static Future<void> _markPreviousDocumentsAsNotCurrent(
    String driverId, 
    DocumentType documentType,
  ) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'is_current': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('driver_id', driverId)
          .eq('document_type', documentType.value)
          .eq('is_current', true);

      print('✅ Documentos anteriores marcados como não atuais');
    } catch (e) {
      print('⚠️ Erro ao marcar documentos anteriores: $e');
      // Não falha o processo principal
    }
  }

  /// Obtém documentos que estão próximos do vencimento
  static Future<List<DriverDocument>> getExpiringDocuments(
    String driverId, {
    int daysBeforeExpiry = 30,
  }) async {
    print('🔄 DriverDocumentService.getExpiringDocuments iniciado');
    print('  - driverId: $driverId');
    print('  - daysBeforeExpiry: $daysBeforeExpiry');

    try {
      final expiryThreshold = DateTime.now().add(Duration(days: daysBeforeExpiry));
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('driver_id', driverId)
          .eq('is_current', true)
          .not('expiry_date', 'is', null)
          .lte('expiry_date', expiryThreshold.toIso8601String())
          .order('expiry_date', ascending: true);

      final documents = response.map(DriverDocument.fromJson).toList();
      
      // Atualiza URLs para versões assinadas frescas
      for (int i = 0; i < documents.length; i++) {
        final freshUrl = await _getFreshSignedUrl(documents[i].fileUrl, documents[i].id);
        if (freshUrl != null) {
          documents[i] = documents[i].copyWith(fileUrl: freshUrl);
        }
      }

      print('✅ Documentos próximos do vencimento: ${documents.length}');
      return documents;

    } on PostgrestException catch (e) {
      print('❌ Erro ao buscar documentos próximos do vencimento: ${e.message}');
      throw DocumentException('Erro ao buscar documentos próximos do vencimento: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DocumentException('Erro inesperado ao buscar documentos próximos do vencimento: $e');
    }
  }

  /// Gera URL assinada fresca do Supabase Storage
  static Future<String?> _getFreshSignedUrl(String fileUrl, String docId) async {
    try {
      // Remove o bucket da URL se presente
      final cleanPath = fileUrl.replaceFirst(RegExp(r'^[^/]+/'), '');
      
      // Gera URL assinada válida por 1 hora
      final response = await _supabase.storage
          .from('driver-documents')
          .createSignedUrl(cleanPath, 3600); // 1 hour

      return response;
    } catch (e) {
      print('❌ Erro ao gerar URL assinada para documento $docId: $e');
      return fileUrl; // Retorna URL original se falhar
    }
  }
}

/// Exceção personalizada para erros de documentos
class DocumentException implements Exception {
  
  DocumentException(this.message);
  final String message;
  
  @override
  String toString() => 'DocumentException: $message';
}