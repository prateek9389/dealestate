class BuyerRequirementModel {
  final String id;
  final String userId;
  final String userName;
  final String transactionType; // "buy" or "rent"
  final double minBudget;
  final double maxBudget;
  final String preferredLocation;
  final String propertyType;
  final String? duration; // only for rent
  final String description;
  final String contactPhone;
  final String contactEmail;
  final String status; // "pending", "in_progress", "fulfilled"
  final DateTime createdAt;

  BuyerRequirementModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.transactionType,
    required this.minBudget,
    required this.maxBudget,
    required this.preferredLocation,
    required this.propertyType,
    this.duration,
    required this.description,
    required this.contactPhone,
    required this.contactEmail,
    required this.status,
    required this.createdAt,
  });

  factory BuyerRequirementModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return BuyerRequirementModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      transactionType: data['requirementType'] ?? '',
      minBudget: (data['minBudget'] ?? 0).toDouble(),
      maxBudget: (data['maxBudget'] ?? 0).toDouble(),
      preferredLocation: data['preferredLocation'] ?? '',
      propertyType: data['propertyType'] ?? '',
      duration: data['duration'],
      description: data['description'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'requirementType': transactionType,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'preferredLocation': preferredLocation,
      'propertyType': propertyType,
      'duration': duration,
      'description': description,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
