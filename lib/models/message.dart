enum MessageType {
  text,
  image,
  voice,
  location,
  system
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}

enum UserType {
  customer,
  driver
}

class ChatMessage {
  final String id;
  final String tripId;
  final String senderId;
  final String senderName;
  final UserType senderType;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.readAt,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['senderType']}',
        orElse: () => UserType.customer,
      ),
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status']}',
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType.toString().split('.').last,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? senderName,
    UserType? senderType,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFromCustomer => senderType == UserType.customer;
  bool get isFromDriver => senderType == UserType.driver;
  bool get isRead => readAt != null;
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isSent => status == MessageStatus.sent || isDelivered;
  bool get isFailed => status == MessageStatus.failed;
  bool get isPending => status == MessageStatus.sending;
}

class ChatParticipant {
  final String id;
  final String name;
  final UserType type;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.type,
    this.profileImage,
    required this.isOnline,
    this.lastSeen,
    this.isTyping = false,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['type']}',
        orElse: () => UserType.customer,
      ),
      profileImage: map['profileImage'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
      isTyping: map['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isTyping': isTyping,
    };
  }

  ChatParticipant copyWith({
    String? id,
    String? name,
    UserType? type,
    String? profileImage,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      profileImage: profileImage ?? this.profileImage,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatRoom {
  final String id;
  final String tripId;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatRoom({
    required this.id,
    required this.tripId,
    required this.participants,
    required this.messages,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      participants: (map['participants'] as List<dynamic>?)
          ?.map((p) => ChatParticipant.fromMap(p))
          .toList() ?? [],
      messages: (map['messages'] as List<dynamic>?)
          ?.map((m) => ChatMessage.fromMap(m))
          .toList() ?? [],
      lastMessage: map['lastMessage'] != null 
          ? ChatMessage.fromMap(map['lastMessage']) 
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? tripId,
    List<ChatParticipant>? participants,
    List<ChatMessage>? messages,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ChatParticipant? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;
}
