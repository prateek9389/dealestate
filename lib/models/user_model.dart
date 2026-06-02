class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profilePictureUrl;
  final String role;
  final List<String> savedPropertyIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.profilePictureUrl = '',
    required this.role,
    this.savedPropertyIds = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      role: (data['role'] as String?)?.trim().toLowerCase() ?? 'user',
      savedPropertyIds: List<String>.from(data['savedPropertyIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'savedPropertyIds': savedPropertyIds,
      'createdAt': createdAt,
    };
  }
}
