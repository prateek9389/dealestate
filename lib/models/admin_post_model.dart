class AdminPostModel {
  final String id;
  final String? ownerId; // Original submitter ID
  final String title;
  final double price;
  final String location;
  final String propertyType;
  final String description;
  final List<String> mediaUrls;
  final String transactionType; // "buy" or "rent"
  final DateTime createdAt;

  AdminPostModel({
    required this.id,
    this.ownerId,
    required this.title,
    required this.price,
    required this.location,
    required this.propertyType,
    required this.description,
    required this.mediaUrls,
    required this.transactionType,
    required this.createdAt,
  });

  factory AdminPostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AdminPostModel(
      id: documentId,
      ownerId: data['ownerId'],
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      propertyType: data['propertyType'] ?? '',
      description: data['description'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      transactionType: data['listingType'] ?? '',
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'price': price,
      'location': location,
      'propertyType': propertyType,
      'description': description,
      'mediaUrls': mediaUrls,
      'listingType': transactionType,
      'createdAt': createdAt,
    };
  }
}
