import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../models/trip.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final Trip trip;

  const ChatScreen({super.key, required this.trip});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _chatService.createChatRoom(widget.trip);
    
    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markMessagesAsRead(widget.trip.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _chatService.sendMessage(widget.trip.id, content);
    _messageController.clear();
    _scrollToBottom();
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

  void _startCall() {
    _chatService.startCall(widget.trip.id);
  }

  void _endCall() {
    _chatService.endCall(widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driver = widget.trip.driver;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Colors.blue[800],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver?.name ?? l10n.driver,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Consumer<ChatService>(
                    builder: (context, chatService, child) {
                      final chatRoom = chatService.getChatRoom(widget.trip.id);
                      final otherParticipant = chatRoom?.getOtherParticipant(chatService.currentUserId);
                      
                      if (otherParticipant?.isTyping == true) {
                        return Text(
                          l10n.typing,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        );
                      }
                      
                      return Text(
                        otherParticipant?.isOnline == true ? l10n.online : l10n.offline,
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ChatService>(
            builder: (context, chatService, child) {
              final callStatus = chatService.callStatus;
              
              if (callStatus == CallStatus.connected) {
                return Row(
                  children: [
                    Text(
                      _formatCallDuration(chatService.callDuration),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end),
                      color: Colors.red,
                    ),
                  ],
                );
              } else if (callStatus == CallStatus.calling || callStatus == CallStatus.ringing) {
                return Row(
                  children: [
                    Text(
                      callStatus == CallStatus.calling ? l10n.calling : l10n.ringing,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end),
                      color: Colors.red,
                    ),
                  ],
                );
              } else {
                return IconButton(
                  onPressed: _startCall,
                  icon: const Icon(Icons.call),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Call status banner
          Consumer<ChatService>(
            builder: (context, chatService, child) {
              final callStatus = chatService.callStatus;
              
              if (callStatus != CallStatus.idle && callStatus != CallStatus.ended) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: _getCallStatusColor(callStatus),
                  child: Row(
                    children: [
                      Icon(
                        _getCallStatusIcon(callStatus),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getCallStatusText(l10n, callStatus),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      if (callStatus == CallStatus.connected) ...[
                        const Spacer(),
                        Text(
                          _formatCallDuration(chatService.callDuration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
          
          // Messages list
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final chatRoom = chatService.getChatRoom(widget.trip.id);
                
                if (chatRoom == null || chatRoom.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMessages,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.startConversation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatRoom.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatRoom.messages[index];
                    return _buildMessageBubble(message, l10n);
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) {
                      if (text.isNotEmpty) {
                        _chatService.startTyping(widget.trip.id);
                      } else {
                        _chatService.stopTyping(widget.trip.id);
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, AppLocalizations l10n) {
    final isFromMe = message.senderId == _chatService.currentUserId;
    final isSystem = message.type == MessageType.system;
    
    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe ? Colors.blue[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isFromMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isFromMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatCallDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getCallStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.calling:
      case CallStatus.ringing:
        return Colors.orange;
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.ended:
        return Colors.grey;
      case CallStatus.failed:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCallStatusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.calling:
      case CallStatus.ringing:
        return Icons.call;
      case CallStatus.connected:
        return Icons.call;
      case CallStatus.ended:
        return Icons.call_end;
      case CallStatus.failed:
        return Icons.call_end;
      default:
        return Icons.call;
    }
  }

  String _getCallStatusText(AppLocalizations l10n, CallStatus status) {
    switch (status) {
      case CallStatus.calling:
        return l10n.calling;
      case CallStatus.ringing:
        return l10n.ringing;
      case CallStatus.connected:
        return l10n.connected;
      case CallStatus.ended:
        return l10n.callEnded;
      case CallStatus.failed:
        return l10n.callFailed;
      default:
        return '';
    }
  }
}
