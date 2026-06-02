class SellerSubmissionModel {
  final String id;
  final String userId;
  final String userName;
  final String transactionType; // "sell" or "rent"
  final String title;
  final double price;
  final double? securityDeposit;
  final String location;
  final String propertyType;
  final String description;
  final List<String> mediaUrls;
  final String contactPhone;
  final String contactEmail;
  final String status; // "pending", "approved", "rejected"
  final DateTime createdAt;

  SellerSubmissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.transactionType,
    required this.title,
    required this.price,
    this.securityDeposit,
    required this.location,
    required this.propertyType,
    required this.description,
    required this.mediaUrls,
    required this.contactPhone,
    required this.contactEmail,
    required this.status,
    required this.createdAt,
  });

  factory SellerSubmissionModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SellerSubmissionModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      transactionType: data['listingType'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      securityDeposit: data['securityDeposit'] != null
          ? (data['securityDeposit']).toDouble()
          : null,
      location: data['location'] ?? '',
      propertyType: data['propertyType'] ?? '',
      description: data['description'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
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
      'id': id,
      'userId': userId,
      'userName': userName,
      'listingType': transactionType,
      'title': title,
      'price': price,
      'securityDeposit': securityDeposit,
      'location': location,
      'propertyType': propertyType,
      'description': description,
      'mediaUrls': mediaUrls,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
