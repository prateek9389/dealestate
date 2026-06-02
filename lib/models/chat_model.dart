class ChatModel {
  final String id;
  final String userId;
  final String adminId;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCountAdmin;
  final int unreadCountUser;

  ChatModel({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCountAdmin = 0,
    this.unreadCountUser = 0,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatModel(
      id: documentId,
      userId: data['userId'] ?? '',
      adminId: data['adminId'] ?? 'admin',
      lastMessage: data['lastMessage'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? data['updatedAt'].toDate()
          : DateTime.now(),
      unreadCountAdmin: data['unreadCountAdmin'] ?? 0,
      unreadCountUser: data['unreadCountUser'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'adminId': adminId,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt,
      'unreadCountAdmin': unreadCountAdmin,
      'unreadCountUser': unreadCountUser,
    };
  }
}
