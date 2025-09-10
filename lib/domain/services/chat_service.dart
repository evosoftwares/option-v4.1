import 'dart:async';
import 'dart:developer' as dev;

import '../../data/models/chat_message.dart';
import '../../data/models/supabase/trip_chat.dart';
import '../../core/utils/supabase_helper.dart';

class ChatService {
  
  factory ChatService() => _instance;
  
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  
  StreamSubscription<List<Map<String, dynamic>>>? _chatSubscription;
  final StreamController<List<ChatMessage>> _messagesController = StreamController.broadcast();
  final Map<String, List<ChatMessage>> _messagesCache = {};
  
  String? _currentTripId;
  String? _currentUserId;
  bool _isPassenger = false;

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  Future<void> initializeChat({
    required String tripId,
    required String currentUserId,
    required bool isPassenger,
  }) async {
    try {
      dev.log('🔄 Inicializando chat para trip: $tripId', name: 'ChatService');
      
      _currentTripId = tripId;
      _currentUserId = currentUserId;
      _isPassenger = isPassenger;

      await _setupRealtimeSubscription();
      await _loadChatHistory();
      
      dev.log('✅ Chat inicializado com sucesso', name: 'ChatService');
    } catch (e) {
      dev.log('❌ Erro ao inicializar chat: $e', name: 'ChatService');
      throw Exception('Falha ao inicializar chat: $e');
    }
  }

  Future<void> _setupRealtimeSubscription() async {
    final client = SupabaseHelper.client;
    if (client == null || _currentTripId == null) return;

    dev.log('📡 Iniciando subscription para tripId: $_currentTripId', name: 'ChatService');
    
    await _chatSubscription?.cancel();

    dev.log('📡 Criando stream para trip_chats com trip_id=$_currentTripId', name: 'ChatService');
    
    try {
      // 🔍 DIAGNÓSTICO: Verificar estrutura da tabela e RLS policies
      dev.log('🔍 DIAGNÓSTICO: Verificando estrutura da tabela e permissões RLS...', name: 'ChatService');
      dev.log('🔍 DIAGNÓSTICO: Trip ID: $_currentTripId, User ID: $_currentUserId, Is Passenger: $_isPassenger', name: 'ChatService');
      
      // 🔍 VALIDAÇÃO: Testar estrutura completa da tabela com query INFORMATION_SCHEMA
      dev.log('🔍 VALIDAÇÃO: Verificando estrutura completa da tabela trip_chats...', name: 'ChatService');
      
      try {
        // Testar leitura básica e verificar estrutura completa da tabela
        final testRead = await client
            .from('trip_chats')
            .select('*')
            .eq('trip_id', _currentTripId!)
            .limit(1);
            
        dev.log('✅ DIAGNÓSTICO: Leitura bem-sucedida, ${testRead.length} registros encontrados', name: 'ChatService');
        
        if (testRead.isNotEmpty) {
          // Verificar quais campos existem na tabela
          final firstRecord = testRead.first;
          dev.log('🔍 DIAGNÓSTICO: Campos disponíveis na tabela: ${firstRecord.keys.toList()}', name: 'ChatService');
          
          // Verificar especificamente os campos críticos
          final hasIsRead = firstRecord.containsKey('is_read');
          final hasReadAt = firstRecord.containsKey('read_at');
          final hasCreatedAt = firstRecord.containsKey('created_at');
          
          dev.log('🔍 DIAGNÓSTICO: Campos críticos - is_read: $hasIsRead, read_at: $hasReadAt, created_at: $hasCreatedAt', name: 'ChatService');
          
          if (!hasIsRead || !hasReadAt) {
            dev.log('❌ DIAGNÓSTICO: ESTRUTURA DA TABELA INCOMPLETA! Campos faltando: ${!hasIsRead ? "is_read " : ""}${!hasReadAt ? "read_at" : ""}', name: 'ChatService');
            dev.log('💡 DIAGNÓSTICO: Execute os comandos SQL para adicionar os campos faltantes', name: 'ChatService');
          }
        }
      } catch (readError) {
        dev.log('❌ DIAGNÓSTICO: Erro na leitura de teste: $readError', name: 'ChatService');
        final errorMsg = readError.toString().toLowerCase();
        
        if (errorMsg.contains('permission') || errorMsg.contains('rls')) {
          dev.log('🔒 DIAGNÓSTICO: Erro de RLS (Row Level Security) detectado', name: 'ChatService');
          dev.log('💡 DIAGNÓSTICO: Verifique as políticas RLS para leitura (SELECT) na tabela trip_chats', name: 'ChatService');
        }
        
        if (errorMsg.contains('column') || errorMsg.contains('does not exist')) {
          dev.log('🔍 DIAGNÓSTICO: Erro de estrutura - campo não encontrado', name: 'ChatService');
          dev.log('💡 DIAGNÓSTICO: A tabela pode estar com colunas faltantes', name: 'ChatService');
        }
      }
      
      // 🔍 DIAGNÓSTICO: Verificar se o stream está funcionando corretamente
      dev.log('🔍 DIAGNÓSTICO: Configurando stream com primaryKey=[id], orderBy=created_at', name: 'ChatService');
      dev.log('🔍 DIAGNÓSTICO: Filtros do stream: trip_id=$_currentTripId', name: 'ChatService');
      
      _chatSubscription = client
          .from('trip_chats')
          .stream(primaryKey: ['id'])
          .eq('trip_id', _currentTripId!)
          .order('created_at')
          .listen(
            (data) {
              dev.log('📨 Dados recebidos no stream: ${data.length} registros', name: 'ChatService');
              dev.log('🔍 Primeiro registro do stream: ${data.isNotEmpty ? data.first : 'vazio'}', name: 'ChatService');
              _handleRealtimeUpdate(data);
            },
            onError: (error, stackTrace) {
              dev.log('❌ Erro no stream do chat: $error\nStackTrace: $stackTrace', name: 'ChatService');
              
              // 🔍 DIAGNÓSTICO: Análise detalhada do erro do stream
              dev.log('🔍 DIAGNÓSTICO: Analisando erro do stream...', name: 'ChatService');
              
              final errorMessage = error.toString().toLowerCase();
              if (errorMessage.contains('stream')) {
                dev.log('🔍 DIAGNÓSTICO: Erro específico do stream detectado', name: 'ChatService');
              }
              if (errorMessage.contains('permission') || errorMessage.contains('rls') || errorMessage.contains('denied')) {
                dev.log('🔒 DIAGNÓSTICO: RLS bloqueando stream - verifique as políticas em tempo real', name: 'ChatService');
                dev.log('💡 DIAGNÓSTICO: As políticas RLS devem permitir streaming para usuários da viagem', name: 'ChatService');
                dev.log('🔧 DIAGNÓSTICO: Verifique se a política RLS tem a cláusula FOR ALL ou FOR SELECT', name: 'ChatService');
              }
              if (errorMessage.contains('connection') || errorMessage.contains('timeout')) {
                dev.log('🔌 DIAGNÓSTICO: Problema de conexão com o banco de dados', name: 'ChatService');
              }
              if (errorMessage.contains('column') || errorMessage.contains('field')) {
                dev.log('🔍 DIAGNÓSTICO: Campo inexistente na tabela - verifique a estrutura', name: 'ChatService');
              }
            },
            onDone: () {
              dev.log('🏁 Stream de tempo real encerrado', name: 'ChatService');
            },
            cancelOnError: false,
          );
          
      dev.log('✅ Subscription configurada com sucesso', name: 'ChatService');
      
      // Testar se o stream está ativo após 3 segundos
      await Future.delayed(const Duration(seconds: 3));
      dev.log('⏱️ Stream configurado há 3 segundos - verificando status...', name: 'ChatService');
      dev.log('🔍 DIAGNÓSTICO: Se não houver dados no stream após 3s, pode haver problema de RLS ou ausência de dados', name: 'ChatService');
      
    } catch (e, stackTrace) {
      dev.log('❌ Erro crítico ao configurar stream: $e\nStackTrace: $stackTrace', name: 'ChatService');
      dev.log('🔍 DIAGNÓSTICO: Erro crítico no setup do stream - verifique configuração do Supabase', name: 'ChatService');
      throw Exception('Falha ao configurar stream de tempo real: $e');
    }
  }

  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    try {
      dev.log('📨 Recebendo atualização realtime: ${data.length} mensagens', name: 'ChatService');
      
      // Validar estrutura dos dados recebidos
      if (data.isNotEmpty) {
        final requiredFields = ['id', 'trip_id', 'sender_id', 'message', 'created_at'];
        final invalidMessages = data.where((msg) {
          return requiredFields.any((field) => msg[field] == null);
        }).toList();
        
        if (invalidMessages.isNotEmpty) {
          dev.log('⚠️ ${invalidMessages.length} mensagens com campos nulos no stream', name: 'ChatService');
          dev.log('🔍 Exemplo de mensagem inválida: ${invalidMessages.first}', name: 'ChatService');
        }
        
        // Verificar tipos de dados do primeiro registro
        final firstMessage = data.first;
        dev.log('🔍 Tipos de dados do primeiro registro no stream:', name: 'ChatService');
        firstMessage.forEach((key, value) {
          dev.log('  $key: ${value?.runtimeType} = $value', name: 'ChatService');
        });
      }
      
      final tripChats = data
          .map((json) {
            try {
              dev.log('🔄 Processando mensagem ID: ${json['id']}', name: 'ChatService');
              
              // Verificar campos obrigatórios antes de converter
              final requiredFields = ['id', 'trip_id', 'sender_id', 'message', 'created_at'];
              final missingFields = requiredFields.where((field) => json[field] == null).toList();
              
              if (missingFields.isNotEmpty) {
                dev.log('❌ Campos obrigatórios ausentes no stream: ${missingFields.join(', ')}', name: 'ChatService');
                dev.log('📄 JSON completo: $json', name: 'ChatService');
                throw Exception('Campos obrigatórios ausentes no stream: ${missingFields.join(', ')}');
              }
              
              return TripChat.fromJson(json);
            } catch (e) {
              dev.log('❌ Erro ao converter mensagem: $e, JSON: $json', name: 'ChatService');
              rethrow;
            }
          })
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      dev.log('✅ Processadas ${tripChats.length} mensagens', name: 'ChatService');
      
      final chatMessages = tripChats.map((tripChat) {
        try {
          dev.log('🔄 Convertendo TripChat ID: ${tripChat.id} para ChatMessage', name: 'ChatService');
          dev.log('📋 Dados do TripChat: senderId=${tripChat.senderId}, message=${tripChat.message}, createdAt=${tripChat.createdAt}', name: 'ChatService');
          
          final chatMessage = ChatMessage.fromTripChat(
            tripChat: tripChat,
            currentUserId: _currentUserId!,
            isDriverSender: !_isPassenger,
          );
          
          dev.log('✅ Conversão bem-sucedida. ChatMessage: isFromCurrentUser=${chatMessage.isFromCurrentUser}, message=${chatMessage.message}', name: 'ChatService');
          return chatMessage;
        } catch (e, stackTrace) {
          dev.log('❌ Erro ao converter TripChat para ChatMessage: $e\nStackTrace: $stackTrace', name: 'ChatService');
          dev.log('📄 Dados do TripChat que falhou: id=${tripChat.id}, senderId=${tripChat.senderId}, message=${tripChat.message}', name: 'ChatService');
          rethrow;
        }
      }).toList();

      if (_currentTripId != null) {
        _messagesCache[_currentTripId!] = chatMessages;
        _messagesController.add(chatMessages);
      }

      dev.log('📤 Emitidas ${chatMessages.length} mensagens para stream', name: 'ChatService');
    } catch (e, stackTrace) {
      dev.log('❌ Erro no _handleRealtimeUpdate: $e\nStackTrace: $stackTrace', name: 'ChatService');
    }
  }

  Future<void> _loadChatHistory() async {
    if (_currentTripId == null) return;

    try {
      final client = SupabaseHelper.client;
      if (client == null) throw Exception('Cliente Supabase não disponível');

      dev.log('📋 Iniciando carregamento do histórico para trip: $_currentTripId', name: 'ChatService');
      
      // 🔍 DIAGNÓSTICO: Verificar estrutura completa da tabela
      dev.log('🔍 DIAGNÓSTICO: Verificando estrutura completa da tabela trip_chats...', name: 'ChatService');
      
      try {
        // Primeiro, verificar se a tabela existe e quais campos estão disponíveis
        final schemaResponse = await client
            .from('trip_chats')
            .select('*')
            .limit(1);
            
        if (schemaResponse.isNotEmpty) {
          dev.log('✅ DIAGNÓSTICO: Tabela trip_chats encontrada', name: 'ChatService');
          dev.log('🔍 DIAGNÓSTICO: Campos disponíveis: ${schemaResponse.first.keys.join(', ')}', name: 'ChatService');
          
          // Verificar especificamente os campos que causam problemas
          final firstRecord = schemaResponse.first;
          final hasIsRead = firstRecord.containsKey('is_read');
          final hasReadAt = firstRecord.containsKey('read_at');
          final hasCreatedAt = firstRecord.containsKey('created_at');
          
          dev.log('🔍 DIAGNÓSTICO: Campos problemáticos:', name: 'ChatService');
          dev.log('   - is_read existe: $hasIsRead', name: 'ChatService');
          dev.log('   - read_at existe: $hasReadAt', name: 'ChatService');
          dev.log('   - created_at existe: $hasCreatedAt', name: 'ChatService');
          
          if (!hasIsRead || !hasReadAt) {
            dev.log('⚠️ DIAGNÓSTICO: Campos is_read ou read_at estão faltando! Isso causará erros.', name: 'ChatService');
          }
        } else {
          dev.log('ℹ️ DIAGNÓSTICO: Tabela existe mas está vazia', name: 'ChatService');
        }
      } catch (schemaError) {
        dev.log('❌ DIAGNÓSTICO: Erro ao verificar estrutura da tabela: $schemaError', name: 'ChatService');
        if (schemaError.toString().contains('permission denied')) {
          dev.log('🔒 DIAGNÓSTICO: Erro de permissão RLS detectado ao verificar estrutura', name: 'ChatService');
        }
      }
      
      // Agora tentar carregar os dados normalmente
      final response = await client
          .from('trip_chats')
          .select('id, trip_id, sender_id, message, created_at') // Selecionar apenas campos básicos
          .eq('trip_id', _currentTripId!)
          .order('created_at')
          .limit(1);

      dev.log('📊 Resposta bruta do Supabase: ${response.toString()}', name: 'ChatService');
      
      if (response.isEmpty) {
        dev.log('ℹ️ Nenhuma mensagem encontrada para esta viagem', name: 'ChatService');
        _messagesCache[_currentTripId!] = [];
        _messagesController.add([]);
        return;
      }

      // Verificar campos do primeiro registro
      final firstRecord = response.first;
      dev.log('🔍 Campos disponíveis no registro: ${firstRecord.keys.join(', ')}', name: 'ChatService');
      dev.log('📄 Dados completos do primeiro registro: $firstRecord', name: 'ChatService');

      // Agora carregar todas as mensagens
      final fullResponse = await client
          .from('trip_chats')
          .select()
          .eq('trip_id', _currentTripId!)
          .order('created_at');

      dev.log('📊 Total de registros encontrados: ${fullResponse.length}', name: 'ChatService');

      // Validar estrutura de todas as mensagens
      if (fullResponse.isNotEmpty) {
        final requiredFields = ['id', 'trip_id', 'sender_id', 'message', 'created_at'];
        final invalidMessages = fullResponse.where((msg) {
          return requiredFields.any((field) => msg[field] == null);
        }).toList();
        
        if (invalidMessages.isNotEmpty) {
          dev.log('⚠️ ${invalidMessages.length} mensagens com campos nulos encontradas', name: 'ChatService');
          dev.log('🔍 Exemplo de mensagem inválida: ${invalidMessages.first}', name: 'ChatService');
          dev.log('📋 Campos obrigatórios: ${requiredFields.join(', ')}', name: 'ChatService');
        }
        
        // Verificar tipos de dados
        final firstMessage = fullResponse.first;
        dev.log('🔍 Tipos de dados do primeiro registro:', name: 'ChatService');
        firstMessage.forEach((key, value) {
          dev.log('  $key: ${value?.runtimeType} = $value', name: 'ChatService');
        });
      }

      final tripChats = fullResponse
          .map<TripChat>((json) {
            try {
              dev.log('🔄 Processando mensagem ID: ${json['id']}', name: 'ChatService');
              
              // Verificar campos obrigatórios antes de converter
              final requiredFields = ['id', 'trip_id', 'sender_id', 'message', 'created_at'];
              final missingFields = requiredFields.where((field) => json[field] == null).toList();
              
              if (missingFields.isNotEmpty) {
                dev.log('❌ Campos obrigatórios ausentes: ${missingFields.join(', ')}', name: 'ChatService');
                dev.log('📄 JSON completo: $json', name: 'ChatService');
                throw Exception('Campos obrigatórios ausentes: ${missingFields.join(', ')}');
              }
              
              return TripChat.fromJson(json);
            } catch (e) {
              dev.log('❌ Erro ao converter TripChat do histórico: $e\nJSON: $json', name: 'ChatService');
              rethrow;
            }
          })
          .toList();

      final chatMessages = tripChats
          .map((tripChat) => ChatMessage.fromTripChat(
                tripChat: tripChat,
                currentUserId: _currentUserId!,
                isDriverSender: !_isPassenger,
              ))
          .toList();

      _messagesCache[_currentTripId!] = chatMessages;
      _messagesController.add(chatMessages);

      dev.log('📋 Histórico carregado: ${chatMessages.length} mensagens', name: 'ChatService');
    } catch (e, stackTrace) {
      dev.log('❌ Erro ao carregar histórico: $e\nStackTrace: $stackTrace', name: 'ChatService');
      throw Exception('Falha ao carregar histórico: $e');
    }
  }

  Future<bool> sendMessage(String message) async {
    if (_currentTripId == null || _currentUserId == null || message.trim().isEmpty) {
      dev.log('⚠️ Parâmetros inválidos para envio de mensagem', name: 'ChatService');
      return false;
    }

    try {
      final client = SupabaseHelper.client;
      if (client == null) throw Exception('Cliente Supabase não disponível');

      dev.log('📤 Iniciando envio de mensagem...', name: 'ChatService');
      dev.log('📋 Parâmetros: tripId=$_currentTripId, senderId=$_currentUserId, isPassenger=$_isPassenger', name: 'ChatService');

      // Verificar se o usuário tem permissão para enviar mensagens nesta viagem
      dev.log('🔍 Verificando permissões do usuário na viagem...', name: 'ChatService');
      
      final tripCheck = await client
          .from('trips')
          .select('driver_id')
          .eq('id', _currentTripId!)
          .maybeSingle();
          
      if (tripCheck == null) {
        dev.log('❌ Viagem não encontrada: $_currentTripId', name: 'ChatService');
        return false;
      }
      
      final driverId = tripCheck['driver_id'] as String;
      dev.log('🔍 Driver da viagem: $driverId, Usuário atual: $_currentUserId', name: 'ChatService');
      
      // Verificar se é motorista ou passageiro autorizado
      if (_isPassenger) {
        // Para passageiro, verificar se existe na trip_passengers
        final passengerCheck = await client
            .from('trip_passengers')
            .select('id')
            .eq('trip_id', _currentTripId!)
            .eq('passenger_id', _currentUserId!)
            .maybeSingle();
            
        if (passengerCheck == null) {
          dev.log('❌ Passageiro não autorizado nesta viagem', name: 'ChatService');
          return false;
        }
        dev.log('✅ Passageiro autorizado encontrado', name: 'ChatService');
      } else {
        // Para motorista, verificar se é o motorista da viagem
        if (driverId != _currentUserId) {
          dev.log('❌ Usuário não é o motorista desta viagem', name: 'ChatService');
          return false;
        }
        dev.log('✅ Motorista verificado com sucesso', name: 'ChatService');
      }

      // Adicionar mensagem temporária (estado "enviando")
      final tempMessage = ChatMessage.sending(
        tripId: _currentTripId!,
        senderId: _currentUserId!,
        message: message.trim(),
        senderType: _isPassenger ? MessageSender.passenger : MessageSender.driver,
      );

      final currentMessages = _messagesCache[_currentTripId!] ?? [];
      _messagesController.add([...currentMessages, tempMessage]);

      // Inserir no Supabase
      dev.log('📤 Enviando mensagem para Supabase...', name: 'ChatService');
      
      // Verificar estrutura da tabela antes de inserir
      dev.log('🔍 Verificando estrutura da tabela trip_chats antes da inserção...', name: 'ChatService');
      
      try {
        final testQuery = await client
            .from('trip_chats')
            .select('id, trip_id, sender_id, message, created_at, is_read, read_at')
            .limit(1);
            
        if (testQuery.isNotEmpty) {
          dev.log('✅ Estrutura da tabela verificada. Campos disponíveis: ${testQuery.first.keys.join(', ')}', name: 'ChatService');
        } else {
          dev.log('ℹ️ Tabela existe mas está vazia', name: 'ChatService');
        }
      } catch (e) {
        dev.log('❌ Erro ao verificar estrutura da tabela: $e', name: 'ChatService');
        if (e.toString().contains('permission denied')) {
          dev.log('🔒 Possível erro de RLS - verifique as permissões', name: 'ChatService');
        }
        rethrow;
      }
      
      final tripChat = TripChat(
        id: '', // será gerado pelo banco
        tripId: _currentTripId!,
        senderId: _currentUserId!,
        message: message.trim(),
        createdAt: DateTime.now(),
      );

      dev.log('📋 Dados da mensagem: tripId=${tripChat.tripId}, senderId=${tripChat.senderId}, message=${tripChat.message}', name: 'ChatService');
      
      final insertData = tripChat.toInsertJson();
      dev.log('📤 JSON de inserção: $insertData', name: 'ChatService');
      
      // Verificar se os campos obrigatórios estão presentes
      if (insertData['trip_id'] == null || insertData['sender_id'] == null || insertData['message'] == null) {
        dev.log('❌ Campos obrigatórios ausentes no JSON de inserção', name: 'ChatService');
        return false;
      }
      
      final response = await client
          .from('trip_chats')
          .insert(insertData)
          .select()
          .single();
          
      dev.log('✅ Mensagem inserida no Supabase com ID: ${response['id']}', name: 'ChatService');
      dev.log('📄 Resposta completa do Supabase: $response', name: 'ChatService');

      // Enviar notificação push se necessário
      await _sendPushNotification(message.trim());

      dev.log('✉️ Mensagem enviada com sucesso', name: 'ChatService');
      return true;
    } catch (e, stackTrace) {
      dev.log('❌ Erro ao enviar mensagem: $e\nStackTrace: $stackTrace', name: 'ChatService');
      
      // Remover mensagem temporária em caso de erro
      final currentMessages = _messagesCache[_currentTripId!] ?? [];
      final filteredMessages = currentMessages
          .where((m) => m.status != MessageStatus.sending)
          .toList();
      _messagesController.add(filteredMessages);
      
      return false;
    }
  }

  Future<void> _sendPushNotification(String message) async {
    try {
      // Implementar lógica para enviar push notification
      // para o outro usuário (passageiro ou motorista)
      dev.log('🔔 Push notification enviada', name: 'ChatService');
    } catch (e) {
      dev.log('⚠️ Erro ao enviar push notification: $e', name: 'ChatService');
    }
  }

  Future<void> markMessagesAsRead() async {
    if (_currentTripId == null || _currentUserId == null) {
      dev.log('⚠️ Parâmetros inválidos para marcação de mensagens como lidas', name: 'ChatService');
      return;
    }

    try {
      dev.log('📖 Iniciando marcação de mensagens como lidas...', name: 'ChatService');
      final client = SupabaseHelper.client;
      if (client == null) {
        dev.log('❌ Cliente Supabase não disponível', name: 'ChatService');
        return;
      }

      dev.log('📋 Parâmetros: tripId=$_currentTripId, userId=$_currentUserId', name: 'ChatService');
      
      // 🔍 DIAGNÓSTICO: Verificar estrutura completa da tabela
      dev.log('🔍 DIAGNÓSTICO: Verificando estrutura completa da tabela trip_chats...', name: 'ChatService');
      
      try {
        final structureTest = await client
            .from('trip_chats')
            .select('*')
            .limit(1);
            
        if (structureTest.isNotEmpty) {
          dev.log('✅ DIAGNÓSTICO: Tabela trip_chats encontrada', name: 'ChatService');
          dev.log('🔍 DIAGNÓSTICO: Campos disponíveis: ${structureTest.first.keys.join(', ')}', name: 'ChatService');
          
          // Verificar especificamente os campos que causam problemas
          final firstRecord = structureTest.first;
          final hasIsRead = firstRecord.containsKey('is_read');
          final hasReadAt = firstRecord.containsKey('read_at');
          final hasCreatedAt = firstRecord.containsKey('created_at');
          final hasId = firstRecord.containsKey('id');
          final hasTripId = firstRecord.containsKey('trip_id');
          final hasSenderId = firstRecord.containsKey('sender_id');
          final hasMessage = firstRecord.containsKey('message');
          
          dev.log('🔍 DIAGNÓSTICO: Verificação de campos obrigatórios:', name: 'ChatService');
          dev.log('   - id: $hasId', name: 'ChatService');
          dev.log('   - trip_id: $hasTripId', name: 'ChatService');
          dev.log('   - sender_id: $hasSenderId', name: 'ChatService');
          dev.log('   - message: $hasMessage', name: 'ChatService');
          dev.log('   - created_at: $hasCreatedAt', name: 'ChatService');
          dev.log('   - is_read: $hasIsRead', name: 'ChatService');
          dev.log('   - read_at: $hasReadAt', name: 'ChatService');
          
          if (!hasIsRead) {
            dev.log('⚠️ DIAGNÓSTICO: Campo is_read NÃO existe na tabela! Isso causará erro.', name: 'ChatService');
            dev.log('💡 DIAGNÓSTICO: Você precisa adicionar o campo is_read à tabela trip_chats', name: 'ChatService');
          }
          if (!hasReadAt) {
            dev.log('⚠️ DIAGNÓSTICO: Campo read_at NÃO existe na tabela!', name: 'ChatService');
          }
        } else {
          dev.log('ℹ️ DIAGNÓSTICO: Tabela existe mas está vazia', name: 'ChatService');
        }
      } catch (structureError) {
        dev.log('❌ DIAGNÓSTICO: Erro ao verificar estrutura da tabela: $structureError', name: 'ChatService');
        if (structureError.toString().contains('permission denied')) {
          dev.log('🔒 DIAGNÓSTICO: Erro de permissão RLS detectado ao verificar estrutura', name: 'ChatService');
        }
      }
      
      // 🔍 DIAGNÓSTICO: Verificar permissões RLS antes da query principal
      dev.log('🔍 DIAGNÓSTICO: Testando permissões de leitura...', name: 'ChatService');
      
      try {
        final readTest = await client
            .from('trip_chats')
            .select('id')
            .eq('trip_id', _currentTripId!)
            .limit(1);
            
        dev.log('✅ DIAGNÓSTICO: Leitura permitida - ${readTest.length} registros encontrados', name: 'ChatService');
      } catch (readError) {
        dev.log('❌ DIAGNÓSTICO: Erro de leitura detectado: $readError', name: 'ChatService');
        if (readError.toString().contains('permission denied')) {
          dev.log('🔒 DIAGNÓSTICO: RLS bloqueando leitura - verifique as políticas', name: 'ChatService');
          return;
        }
      }
      
      // 🔍 DIAGNÓSTICO: Verificar mensagens não lidas com query simplificada
      dev.log('🔍 DIAGNÓSTICO: Verificando mensagens não lidas com query simplificada...', name: 'ChatService');
      
      try {
        // Testar query sem o campo is_read primeiro
        final messagesTest = await client
            .from('trip_chats')
            .select('id, sender_id')
            .eq('trip_id', _currentTripId!)
            .neq('sender_id', _currentUserId!)
            .limit(5);
            
        dev.log('✅ DIAGNÓSTICO: Query simplificada funcionou - ${messagesTest.length} mensagens encontradas', name: 'ChatService');
        
        if (messagesTest.isNotEmpty) {
          dev.log('🔍 DIAGNÓSTICO: Primeira mensagem: ${messagesTest.first}', name: 'ChatService');
        }
      } catch (queryError) {
        dev.log('❌ DIAGNÓSTICO: Erro na query simplificada: $queryError', name: 'ChatService');
      }
      
      // 🔍 VALIDAÇÃO: Tentar query completa com todos os campos
      dev.log('🔍 VALIDAÇÃO: Tentando query completa com is_read e read_at...', name: 'ChatService');
      
      // 🔍 VALIDAÇÃO: Verificar se o problema é específico dos campos opcionais
      try {
        final fullFieldsTest = await client
            .from('trip_chats')
            .select('id, trip_id, sender_id, message, created_at, is_read, read_at')
            .eq('trip_id', _currentTripId!)
            .limit(1);
            
        if (fullFieldsTest.isNotEmpty) {
          final firstRecord = fullFieldsTest.first;
          dev.log('✅ VALIDAÇÃO: Query completa funcionou!', name: 'ChatService');
          dev.log('🔍 VALIDAÇÃO: Campos encontrados: ${firstRecord.keys.toList()}', name: 'ChatService');
          dev.log('🔍 VALIDAÇÃO: Valores - is_read: ${firstRecord['is_read']}, read_at: ${firstRecord['read_at']}', name: 'ChatService');
        } else {
          dev.log('ℹ️ VALIDAÇÃO: Nenhum registro encontrado na query completa', name: 'ChatService');
        }
      } catch (fullTestError) {
        dev.log('❌ VALIDAÇÃO: Erro na query completa: $fullTestError', name: 'ChatService');
        final errorMsg = fullTestError.toString().toLowerCase();
        if (errorMsg.contains('column') && errorMsg.contains('does not exist')) {
          dev.log('🚨 VALIDAÇÃO: CONFIRMADO - Campos is_read ou read_at não existem na tabela!', name: 'ChatService');
          dev.log('🔧 VALIDAÇÃO: SOLUÇÃO: Execute os comandos SQL para adicionar os campos faltantes', name: 'ChatService');
        }
      }
      
      // Primeiro, verificar quantas mensagens não lidas existem
      final unreadCount = await client
          .from('trip_chats')
          .select('id, is_read, read_at')
          .eq('trip_id', _currentTripId!)
          .neq('sender_id', _currentUserId!)
          .eq('is_read', false)
          .count();
          
      dev.log('📊 Encontradas ${unreadCount.count} mensagens não lidas', name: 'ChatService');

      if (unreadCount.count > 0) {
        dev.log('📝 Atualizando mensagens como lidas...', name: 'ChatService');
        
        // Verificar se o campo read_at existe na tabela
        final testQuery = await client
            .from('trip_chats')
            .select('read_at')
            .eq('trip_id', _currentTripId!)
            .limit(1);
            
        final hasReadAt = testQuery.isNotEmpty && testQuery.first.containsKey('read_at');
        dev.log('🔍 Campo read_at existe na tabela: $hasReadAt', name: 'ChatService');
        
        final updateData = <String, dynamic>{
          'is_read': true,
        };
        
        if (hasReadAt) {
          updateData['read_at'] = DateTime.now().toIso8601String();
        }
        
        dev.log('📤 Dados de atualização: $updateData', name: 'ChatService');
        
        // 🔍 DIAGNÓSTICO: Verificar a query de atualização antes de executar
        dev.log('🔍 DIAGNÓSTICO: Preparando query de atualização...', name: 'ChatService');
        dev.log('🔍 DIAGNÓSTICO: Filtros: trip_id=$_currentTripId, sender_id!=$_currentUserId, is_read=false', name: 'ChatService');
        
        // 🔍 DIAGNÓSTICO: Verificar dados completos antes do update
        dev.log('🔍 DIAGNÓSTICO: Preparando update com dados: $updateData', name: 'ChatService');
        dev.log('🔍 DIAGNÓSTICO: Filtros - trip_id: $_currentTripId, sender_id != $_currentUserId, is_read: false', name: 'ChatService');
        
        final response = await client
            .from('trip_chats')
            .update(updateData)
            .eq('trip_id', _currentTripId!)
            .neq('sender_id', _currentUserId!)
            .eq('is_read', false)
            .select();
            
        dev.log('✅ ${response.length} mensagens marcadas como lidas', name: 'ChatService');
        dev.log('📄 Resposta da atualização: $response', name: 'ChatService');
        
        // 🔍 DIAGNÓSTICO: Atualizar cache local
        dev.log('🔍 DIAGNÓSTICO: Atualizando cache local...', name: 'ChatService');
        if (_currentTripId != null && _messagesCache.containsKey(_currentTripId!)) {
          final updatedMessages = _messagesCache[_currentTripId!]!.map((message) {
            if (!message.isFromCurrentUser && message.status != MessageStatus.read) {
              return message.copyWith(status: MessageStatus.read);
            }
            return message;
          }).toList();
          
          _messagesCache[_currentTripId!] = updatedMessages;
          _messagesController.add(updatedMessages);
          dev.log('✅ DIAGNÓSTICO: Cache local atualizado com sucesso', name: 'ChatService');
        }
      } else {
        dev.log('ℹ️ Nenhuma mensagem para marcar como lida', name: 'ChatService');
      }
    } catch (e, stackTrace) {
      dev.log('❌ Erro ao marcar mensagens como lidas: $e\nStackTrace: $stackTrace', name: 'ChatService');
      
      // 🔍 DIAGNÓSTICO: Análise detalhada do erro
      dev.log('🔍 DIAGNÓSTICO: Analisando erro detalhadamente...', name: 'ChatService');
      final errorMessage = e.toString().toLowerCase();
      
      // Verificar se é erro de permissão (RLS)
      if (errorMessage.contains('permission denied') || errorMessage.contains('rls')) {
        dev.log('🔒 DIAGNÓSTICO: Erro de RLS (Row Level Security) detectado', name: 'ChatService');
        dev.log('💡 DIAGNÓSTICO: Verifique as políticas RLS para a tabela trip_chats', name: 'ChatService');
        dev.log('🔧 DIAGNÓSTICO: As políticas devem permitir UPDATE para usuários autorizados da viagem', name: 'ChatService');
      }
      
      // Verificar se é erro de campo inexistente
      if (errorMessage.contains('column') && errorMessage.contains('does not exist')) {
        dev.log('🔍 DIAGNÓSTICO: Erro de estrutura de tabela detectado', name: 'ChatService');
        dev.log('💡 DIAGNÓSTICO: Verifique se todos os campos (is_read, read_at) existem na tabela', name: 'ChatService');
        dev.log('🔧 DIAGNÓSTICO: Execute: ALTER TABLE trip_chats ADD COLUMN is_read BOOLEAN DEFAULT false;', name: 'ChatService');
        dev.log('🔧 DIAGNÓSTICO: Execute: ALTER TABLE trip_chats ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;', name: 'ChatService');
      }
      
      // Verificar outros tipos de erro
      if (errorMessage.contains('syntax')) {
        dev.log('🔍 DIAGNÓSTICO: Erro de sintaxe SQL detectado', name: 'ChatService');
      }
      if (errorMessage.contains('connection')) {
        dev.log('🔍 DIAGNÓSTICO: Erro de conexão detectado', name: 'ChatService');
      }
      if (errorMessage.contains('timeout')) {
        dev.log('🔍 DIAGNÓSTICO: Timeout detectado', name: 'ChatService');
      }
    }
  }

  List<ChatMessage> getCachedMessages(String tripId) => _messagesCache[tripId] ?? [];

  bool get isActive => _currentTripId != null;
  String? get currentTripId => _currentTripId;

  void dispose() {
    _chatSubscription?.cancel();
    _currentTripId = null;
    _currentUserId = null;
    _messagesCache.clear();
    dev.log('🧹 ChatService limpo', name: 'ChatService');
  }

  Future<void> clearCache() async {
    _messagesCache.clear();
    dev.log('🗑️ Cache do chat limpo', name: 'ChatService');
  }
}