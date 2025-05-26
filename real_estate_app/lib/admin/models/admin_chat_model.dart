class Chat {
  final String id;
  final String clientName;
  final String lastMessage;
  final int unreadCount;
  final DateTime timestamp;

  Chat({
    required this.id,
    required this.clientName,
    required this.lastMessage,
    required this.unreadCount,
    required this.timestamp,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    
    return Chat(
      id: json['id'].toString(),
      clientName: '$firstName $lastName'.trim(),
      lastMessage: json['last_message']?.toString() ?? 'No messages yet',
      unreadCount: json['unread_count'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isRead;
  final String messageType;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isRead,
    required this.messageType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      content: json['content'],
      senderId: json['sender'].toString(),
      senderName: json['sender_name'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      messageType: json['message_type'] ?? 'enquiry',
    );
  }
}


