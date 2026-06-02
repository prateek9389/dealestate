import 'package:flutter/material.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/admin_post_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

import '../../models/seller_submission_model.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class AdminCreateListingScreen extends StatefulWidget {
  final bool isTab;
  final SellerSubmissionModel? initialData;
  const AdminCreateListingScreen({super.key, this.isTab = false, this.initialData});

  @override
  State<AdminCreateListingScreen> createState() => _AdminCreateListingScreenState();
}

class _AdminCreateListingScreenState extends State<AdminCreateListingScreen> {
  late int _transactionType; 
  final List<String> propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Commercial',
    'Land',
  ];
  String? selectedPropertyType;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  List<String> _existingUrls = [];
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialData?.transactionType == 'rent' ? 1 : 0;
    selectedPropertyType = widget.initialData?.propertyType;
    _existingUrls = List.from(widget.initialData?.mediaUrls ?? []);
    
    _titleController = TextEditingController(text: widget.initialData?.title);
    _priceController = TextEditingController(text: widget.initialData?.price.toString());
    _locationController = TextEditingController(text: widget.initialData?.location);
    _descriptionController = TextEditingController(text: widget.initialData?.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingUrl(int index) {
    setState(() {
      _existingUrls.removeAt(index);
    });
  }

  Future<void> _createListing() async {
    final title = _titleController.text.trim();
    final priceText = _priceController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        priceText.isEmpty ||
        location.isEmpty ||
        description.isEmpty ||
        selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> uploadedUrls = [];
      final cloudinaryService = CloudinaryService();
      
      for (var image in _selectedImages) {
        final url = await cloudinaryService.uploadImage(File(image.path));
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      final docId = FirebaseFirestore.instance.collection('admin_posts').doc().id;

      final adminPost = AdminPostModel(
        id: docId,
        ownerId: widget.initialData?.userId,
        title: title,
        price: price,
        location: location,
        propertyType: selectedPropertyType!,
        description: description,
        mediaUrls: [..._existingUrls, ...uploadedUrls],
        transactionType: _transactionType == 0 ? 'buy' : 'rent',
        createdAt: DateTime.now(),
      );

      await FirestoreService().createAdminPost(adminPost);

      // If this listing was created from a seller submission, update its status
      if (widget.initialData != null) {
        await FirebaseFirestore.instance
            .collection('seller_submissions')
            .doc(widget.initialData!.id)
            .update({'status': 'approved'});

        // Notify user via NotificationService
        final notification = NotificationModel(
          id: '',
          title: 'Property Published!',
          body: 'Your property "${widget.initialData!.title}" has been approved and published to the network.',
          type: 'property',
          timestamp: DateTime.now(),
          isRead: false,
          relatedId: docId, // Send them to the public post
        );

        await NotificationService().sendNotification(widget.initialData!.userId, notification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Public Listing Created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Creating Listing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.initialData != null ? 'Verify & Post Listing' : 'Post New Listing',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.isTab,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.initialData != null) ...[
                      const Text(
                        'Seller Information',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1754CF).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1754CF).withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1754CF).withValues(alpha: 0.1),
                              child: Text(
                                widget.initialData!.userName[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF1754CF), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.initialData!.userName,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.initialData!.contactEmail,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.initialData!.contactPhone,
                                    style: const TextStyle(color: Color(0xFF1754CF), fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {}, // Potential for WhatsApp/Call integration
                              icon: const Icon(Icons.contact_phone_rounded, color: Color(0xFF1754CF)),
                              style: IconButton.styleFrom(backgroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    const Text(
                      'Transaction Type',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ToggleSwitch(
                      optionText1: 'Buy',
                      optionText2: 'Rent',
                      onToggle: (index) {
                        setState(() {
                          _transactionType = index;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Property Details',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _titleController,
                      hintText: 'Listing Title',
                      prefixIcon: Icons.title_rounded,
                    ),
                    AppTextField(
                      controller: _priceController,
                      hintText: 'Price (₹)',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    AppTextField(
                      controller: _locationController,
                      hintText: 'Location (City, Area)',
                      prefixIcon: Icons.location_on_rounded,
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPropertyType,
                          hint: const Text('Property Type', style: TextStyle(fontSize: 14)),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1754CF)),
                          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          items: propertyTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPropertyType = value;
                            });
                          },
                        ),
                      ),
                    ),
                    AppTextField(
                      controller: _descriptionController,
                      hintText: 'Write a compelling description...',
                      prefixIcon: Icons.description_rounded,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Media Assets',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: (_selectedImages.isEmpty && _existingUrls.isEmpty) ? 140 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1754CF).withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: (_selectedImages.isEmpty && _existingUrls.isEmpty)
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 30),
                                  Icon(Icons.add_photo_alternate_rounded, size: 40, color: Color(0xFF1754CF)),
                                  SizedBox(height: 12),
                                  Text(
                                    'Add Property Media',
                                    style: TextStyle(color: Color(0xFF1754CF), fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  Text(
                                    'High quality images preferred',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  SizedBox(height: 30),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    // Existing network images from seller
                                    ..._existingUrls.asMap().entries.map((entry) {
                                      int idx = entry.key;
                                      String url = entry.value;
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.network(
                                              url,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeExistingUrl(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withAlpha(180),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    // New local uploads from admin
                                    ..._selectedImages.asMap().entries.map((entry) {
                                      int idx = entry.key;
                                      XFile image = entry.value;
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.file(
                                              File(image.path),
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withAlpha(180),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    // Add more button
                                    GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1754CF).withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFF1754CF).withValues(alpha: 0.2)),
                                        ),
                                        child: const Icon(Icons.add_rounded, color: Color(0xFF1754CF), size: 32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1754CF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _createListing,
                        child: Text(
                          widget.initialData != null ? 'Confirm & Post' : 'Post Property',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
