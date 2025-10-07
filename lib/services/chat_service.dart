import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/trip.dart';
import 'notification_service.dart';

enum CallStatus {
  idle,
  calling,
  ringing,
  connected,
  ended,
  failed
}

class ChatService extends ChangeNotifier {
  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, StreamController<ChatMessage>> _messageStreams = {};
  Timer? _typingTimer;
  Timer? _autoResponseTimer;
  CallStatus _callStatus = CallStatus.idle;
  DateTime? _callStartTime;
  Timer? _callTimer;
  BuildContext? _context;

  // Current user info (in real app, get from auth service)
  String get currentUserId => 'current_user';
  UserType get currentUserType => UserType.customer;

  // Set context for notifications
  void setContext(BuildContext context) {
    _context = context;
  }
  
  CallStatus get callStatus => _callStatus;
  DateTime? get callStartTime => _callStartTime;
  
  // Get chat room for a trip
  ChatRoom? getChatRoom(String tripId) {
    return _chatRooms[tripId];
  }
  
  // Create or get chat room for a trip
  ChatRoom createChatRoom(Trip trip) {
    if (_chatRooms.containsKey(trip.id)) {
      return _chatRooms[trip.id]!;
    }
    
    final participants = [
      ChatParticipant(
        id: currentUserId,
        name: 'You', // In real app, get from user profile
        type: currentUserType,
        isOnline: true,
      ),
      if (trip.driver != null)
        ChatParticipant(
          id: trip.driver!.id,
          name: trip.driver!.name,
          type: UserType.driver,
          isOnline: true,
        ),
    ];
    
    final chatRoom = ChatRoom(
      id: 'chat_${trip.id}',
      tripId: trip.id,
      participants: participants,
      messages: [],
      createdAt: DateTime.now(),
    );
    
    _chatRooms[trip.id] = chatRoom;
    _messageStreams[trip.id] = StreamController<ChatMessage>.broadcast();
    
    // Send welcome message
    _sendSystemMessage(trip.id, 'Chat started. You can now communicate with your driver.');
    
    return chatRoom;
  }
  
  // Send a message
  Future<void> sendMessage(String tripId, String content, {MessageType type = MessageType.text}) async {
    final chatRoom = _chatRooms[tripId];
    if (chatRoom == null) return;
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      senderId: currentUserId,
      senderName: 'You',
      senderType: currentUserType,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    
    // Add message to room
    final updatedMessages = [...chatRoom.messages, message];
    final updatedRoom = chatRoom.copyWith(
      messages: updatedMessages,
      lastMessage: message,
      updatedAt: DateTime.now(),
    );
    
    _chatRooms[tripId] = updatedRoom;
    _messageStreams[tripId]?.add(message);
    notifyListeners();
    
    // Simulate message delivery
    await Future.delayed(const Duration(milliseconds: 500));
    _updateMessageStatus(tripId, message.id, MessageStatus.sent);
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _updateMessageStatus(tripId, message.id, MessageStatus.delivered);
    
    // Simulate driver auto-response
    _scheduleAutoResponse(tripId);
  }
  
  // Update message status
  void _updateMessageStatus(String tripId, String messageId, MessageStatus status) {
    final chatRoom = _chatRooms[tripId];
    if (chatRoom == null) return;
    
    final updatedMessages = chatRoom.messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(status: status);
      }
      return msg;
    }).toList();
    
    final updatedRoom = chatRoom.copyWith(messages: updatedMessages);
    _chatRooms[tripId] = updatedRoom;
    notifyListeners();
  }
  
  // Send system message
  void _sendSystemMessage(String tripId, String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      senderId: 'system',
      senderName: 'System',
      senderType: UserType.driver, // Just for display purposes
      content: content,
      type: MessageType.system,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
    );
    
    final chatRoom = _chatRooms[tripId];
    if (chatRoom != null) {
      final updatedMessages = [...chatRoom.messages, message];
      final updatedRoom = chatRoom.copyWith(
        messages: updatedMessages,
        lastMessage: message,
        updatedAt: DateTime.now(),
      );
      
      _chatRooms[tripId] = updatedRoom;
      _messageStreams[tripId]?.add(message);
      notifyListeners();
    }
  }
  
  // Schedule auto-response from driver
  void _scheduleAutoResponse(String tripId) {
    _autoResponseTimer?.cancel();
    _autoResponseTimer = Timer(const Duration(seconds: 2), () {
      _sendDriverResponse(tripId);
    });
  }
  
  // Send driver auto-response
  void _sendDriverResponse(String tripId) {
    final chatRoom = _chatRooms[tripId];
    if (chatRoom == null || chatRoom.participants.length < 2) return;
    
    final driver = chatRoom.participants.firstWhere(
      (p) => p.type == UserType.driver,
      orElse: () => chatRoom.participants.first,
    );
    
    final responses = [
      "I'm on my way to pick you up!",
      "I'll be there in a few minutes.",
      "Thanks for the message!",
      "I can see your location on the map.",
      "Traffic is light, should be there soon.",
      "Please wait at the pickup location.",
      "I'm driving a ${chatRoom.messages.isNotEmpty ? 'blue sedan' : 'white car'}.",
    ];
    
    final randomResponse = responses[Random().nextInt(responses.length)];
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      senderId: driver.id,
      senderName: driver.name,
      senderType: UserType.driver,
      content: randomResponse,
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
    );
    
    final updatedMessages = [...chatRoom.messages, message];
    final updatedRoom = chatRoom.copyWith(
      messages: updatedMessages,
      lastMessage: message,
      updatedAt: DateTime.now(),
      unreadCount: chatRoom.unreadCount + 1,
    );
    
    _chatRooms[tripId] = updatedRoom;
    _messageStreams[tripId]?.add(message);
    notifyListeners();

    // Show notification if context is available and message is from driver
    if (_context != null && message.senderType == UserType.driver) {
      NotificationService().showMessageNotification(
        _context!,
        message,
        onTap: () {
          // In a real app, navigate to chat screen
        },
      );
    }
  }
  
  // Mark messages as read
  void markMessagesAsRead(String tripId) {
    final chatRoom = _chatRooms[tripId];
    if (chatRoom == null) return;
    
    final updatedMessages = chatRoom.messages.map((msg) {
      if (msg.senderId != currentUserId && !msg.isRead) {
        return msg.copyWith(
          status: MessageStatus.read,
          readAt: DateTime.now(),
        );
      }
      return msg;
    }).toList();
    
    final updatedRoom = chatRoom.copyWith(
      messages: updatedMessages,
      unreadCount: 0,
    );
    
    _chatRooms[tripId] = updatedRoom;
    notifyListeners();
  }
  
  // Start typing indicator
  void startTyping(String tripId) {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping(tripId);
    });
    
    final chatRoom = _chatRooms[tripId];
    if (chatRoom != null) {
      final updatedParticipants = chatRoom.participants.map((p) {
        if (p.id == currentUserId) {
          return p.copyWith(isTyping: true);
        }
        return p;
      }).toList();
      
      final updatedRoom = chatRoom.copyWith(participants: updatedParticipants);
      _chatRooms[tripId] = updatedRoom;
      notifyListeners();
    }
  }
  
  // Stop typing indicator
  void stopTyping(String tripId) {
    _typingTimer?.cancel();
    
    final chatRoom = _chatRooms[tripId];
    if (chatRoom != null) {
      final updatedParticipants = chatRoom.participants.map((p) {
        if (p.id == currentUserId) {
          return p.copyWith(isTyping: false);
        }
        return p;
      }).toList();
      
      final updatedRoom = chatRoom.copyWith(participants: updatedParticipants);
      _chatRooms[tripId] = updatedRoom;
      notifyListeners();
    }
  }
  
  // Start voice call
  Future<void> startCall(String tripId) async {
    if (_callStatus != CallStatus.idle) return;
    
    _callStatus = CallStatus.calling;
    notifyListeners();
    
    // Simulate call connection
    await Future.delayed(const Duration(seconds: 2));
    
    if (_callStatus == CallStatus.calling) {
      _callStatus = CallStatus.ringing;
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (_callStatus == CallStatus.ringing) {
        _callStatus = CallStatus.connected;
        _callStartTime = DateTime.now();
        _startCallTimer();
        notifyListeners();
        
        // Send system message about call
        _sendSystemMessage(tripId, 'Voice call started');
      }
    }
  }
  
  // End voice call
  void endCall(String tripId) {
    if (_callStatus == CallStatus.idle) return;
    
    final duration = _callStartTime != null 
        ? DateTime.now().difference(_callStartTime!).inSeconds
        : 0;
    
    _callStatus = CallStatus.ended;
    _callTimer?.cancel();
    _callStartTime = null;
    notifyListeners();
    
    // Send system message about call end
    _sendSystemMessage(tripId, 'Voice call ended (${duration}s)');
    
    // Reset to idle after a short delay
    Timer(const Duration(seconds: 2), () {
      _callStatus = CallStatus.idle;
      notifyListeners();
    });
  }
  
  // Start call timer
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners(); // Update UI with call duration
    });
  }
  
  // Get call duration
  Duration get callDuration {
    if (_callStartTime == null) return Duration.zero;
    return DateTime.now().difference(_callStartTime!);
  }
  
  // Get message stream for a trip
  Stream<ChatMessage>? getMessageStream(String tripId) {
    return _messageStreams[tripId]?.stream;
  }
  
  // Clean up resources
  void disposeChatRoom(String tripId) {
    _messageStreams[tripId]?.close();
    _messageStreams.remove(tripId);
    _chatRooms.remove(tripId);
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _autoResponseTimer?.cancel();
    _callTimer?.cancel();
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    _messageStreams.clear();
    _chatRooms.clear();
    super.dispose();
  }
}
