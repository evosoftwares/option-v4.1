import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class ChatScreen extends StatefulWidget {

  const ChatScreen({
    super.key,
    required this.tripId,
    required this.currentUserId,
    required this.otherUserName,
    required this.isPassenger,
    this.isReadOnly = false,
  });
  final String tripId;
  final String currentUserId;
  final String otherUserName;
  final bool isPassenger;
  final bool isReadOnly;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      if (!widget.isReadOnly) {
        await _chatService.initializeChat(
          tripId: widget.tripId,
          currentUserId: widget.currentUserId,
          isPassenger: widget.isPassenger,
        );
      }

      _messagesSubscription = _chatService.messagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      });

      // Marcar mensagens como lidas se não for somente leitura
      if (!widget.isReadOnly) {
        await _chatService.markMessagesAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar chat: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final success = await _chatService.sendMessage(message);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao enviar mensagem')),
          );
        }
        _messageController.text = message; // Restaurar texto
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem')),
        );
      }
      _messageController.text = message; // Restaurar texto
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    if (!widget.isReadOnly) {
      _chatService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        centerTitle: true,
        actions: !widget.isReadOnly
            ? [
                IconButton(
                  onPressed: () {
                    // TODO: Implementar chamada telefônica
                  },
                  icon: const Icon(Icons.phone),
                  tooltip: 'Ligar',
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );


  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.black,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildMessagesList(),
        ),
        if (!widget.isReadOnly) _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.isReadOnly 
                  ? 'Nenhuma mensagem foi enviada'
                  : 'Inicie uma conversa',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromCurrentUser = message.isFromCurrentUser;
    final isDelivered = message.status == MessageStatus.delivered || 
                       message.status == MessageStatus.read;
    final isRead = message.status == MessageStatus.read;

    return Align(
      alignment: isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isFromCurrentUser ? AppSpacing.xl * 2 : 0,
          right: isFromCurrentUser ? 0 : AppSpacing.xl * 2,
        ),
        child: Column(
          crossAxisAlignment: isFromCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isFromCurrentUser ? AppColors.black : AppColors.gray100,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: Radius.circular(isFromCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 18),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isFromCurrentUser ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: AppTypography.captionText.copyWith(
                          color: isFromCurrentUser 
                              ? AppColors.gray300 
                              : AppColors.gray600,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        if (message.status == MessageStatus.sending)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.gray300,
                            ),
                          )
                        else if (isRead)
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: AppColors.blue,
                          )
                        else if (isDelivered)
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: AppColors.gray300,
                          )
                        else if (message.status == MessageStatus.failed)
                          const Icon(
                            Icons.error_outline,
                            size: 12,
                            color: AppColors.error,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() => Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray200),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.gray200),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                minLines: 1,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: AppColors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}