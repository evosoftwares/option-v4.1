import 'dart:async';
import 'dart:developer' as dev;

import '../models/chat_message.dart';
import '../models/supabase/trip_chat.dart';
import '../utils/supabase_helper.dart';

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

    await _chatSubscription?.cancel();

    _chatSubscription = client
        .from('trip_chats')
        .stream(primaryKey: ['id'])
        .eq('trip_id', _currentTripId!)
        .order('created_at')
        .listen(
          _handleRealtimeUpdate,
          onError: (error) {
            dev.log('❌ Erro no stream do chat: $error', name: 'ChatService');
          },
        );
  }

  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    try {
      final tripChats = data
          .map(TripChat.fromJson)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final chatMessages = tripChats
          .map((tripChat) => ChatMessage.fromTripChat(
                tripChat: tripChat,
                currentUserId: _currentUserId!,
                isDriverSender: !_isPassenger,
              ))
          .toList();

      if (_currentTripId != null) {
        _messagesCache[_currentTripId!] = chatMessages;
        _messagesController.add(chatMessages);
      }

      dev.log('📨 Chat atualizado: ${chatMessages.length} mensagens', name: 'ChatService');
    } catch (e) {
      dev.log('❌ Erro ao processar update do chat: $e', name: 'ChatService');
    }
  }

  Future<void> _loadChatHistory() async {
    if (_currentTripId == null) return;

    try {
      final client = SupabaseHelper.client;
      if (client == null) throw Exception('Cliente Supabase não disponível');

      final response = await client
          .from('trip_chats')
          .select()
          .eq('trip_id', _currentTripId!)
          .order('created_at');

      final tripChats = response
          .map<TripChat>(TripChat.fromJson)
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
    } catch (e) {
      dev.log('❌ Erro ao carregar histórico: $e', name: 'ChatService');
      throw Exception('Falha ao carregar histórico: $e');
    }
  }

  Future<bool> sendMessage(String message) async {
    if (_currentTripId == null || _currentUserId == null || message.trim().isEmpty) {
      return false;
    }

    try {
      final client = SupabaseHelper.client;
      if (client == null) throw Exception('Cliente Supabase não disponível');

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
      final tripChat = TripChat(
        id: '', // será gerado pelo banco
        tripId: _currentTripId!,
        senderId: _currentUserId!,
        message: message.trim(),
        createdAt: DateTime.now(),
      );

      await client
          .from('trip_chats')
          .insert(tripChat.toInsertJson());

      // Enviar notificação push se necessário
      await _sendPushNotification(message.trim());

      dev.log('✉️ Mensagem enviada com sucesso', name: 'ChatService');
      return true;
    } catch (e) {
      dev.log('❌ Erro ao enviar mensagem: $e', name: 'ChatService');
      
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
    if (_currentTripId == null || _currentUserId == null) return;

    try {
      final client = SupabaseHelper.client;
      if (client == null) return;

      await client
          .from('trip_chats')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('trip_id', _currentTripId!)
          .neq('sender_id', _currentUserId!)
          .eq('is_read', false);

      dev.log('✅ Mensagens marcadas como lidas', name: 'ChatService');
    } catch (e) {
      dev.log('❌ Erro ao marcar mensagens como lidas: $e', name: 'ChatService');
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