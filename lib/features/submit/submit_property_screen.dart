import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/seller_submission_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

class SubmitPropertyScreen extends StatefulWidget {
  const SubmitPropertyScreen({super.key});

  @override
  State<SubmitPropertyScreen> createState() => _SubmitPropertyScreenState();
}

class _SubmitPropertyScreenState extends State<SubmitPropertyScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        _userName = user.name;
        _userEmail = user.email;
        if (user.phone.isNotEmpty) {
          _phoneController.text = user.phone;
        }
      });
    }
  }

  int _transactionType = 0; // 0 for Sell, 1 for Rent
  String? _userName;
  String? _userEmail;
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
  final ImagePicker _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _securityDepositController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, // Compress slightly
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting images: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProperty() async {
    final title = _titleController.text.trim();
    final priceText = _priceController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final securityDepositText = _securityDepositController.text.trim();

    if (title.isEmpty ||
        priceText.isEmpty ||
        location.isEmpty ||
        description.isEmpty ||
        phone.isEmpty ||
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

    double? securityDeposit;
    if (_transactionType == 1 && securityDepositText.isNotEmpty) {
      securityDeposit = double.tryParse(securityDepositText);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait, you are not logged in!')),
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

      final docId = FirebaseFirestore.instance
          .collection('seller_submissions')
          .doc()
          .id;

      final submission = SellerSubmissionModel(
        id: docId,
        userId: user.uid,
        userName: _userName ?? user.displayName ?? 'User',
        transactionType: _transactionType == 0 ? 'sell' : 'rent',
        title: title,
        price: price,
        securityDeposit: securityDeposit,
        location: location,
        propertyType: selectedPropertyType!,
        description: description,
        mediaUrls: uploadedUrls,
        contactPhone: phone,
        contactEmail: _userEmail ?? user.email ?? '',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirestoreService().submitProperty(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property Submitted for Admin Review successfully!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Submitting Property: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Property')),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToggleSwitch(
                optionText1: 'Sell',
                optionText2: 'Rent',
                onToggle: (index) {
                  setState(() {
                    _transactionType = index;
                  });
                },
              ),
              const SizedBox(height: AppSizes.p24),
              AppTextField(
                controller: _titleController,
                hintText: 'Title (e.g., Modern 2BHK Apartment)',
                prefixIcon: Icons.title,
              ),
              AppTextField(
                controller: _priceController,
                hintText: _transactionType == 0
                    ? 'Price (₹)'
                    : 'Monthly Rent (₹)',
                prefixIcon: Icons.attach_money,
              ),
              if (_transactionType == 1)
                AppTextField(
                  controller: _securityDepositController,
                  hintText: 'Security Deposit (₹)',
                  prefixIcon: Icons.shield_outlined,
                ),
              AppTextField(
                controller: _locationController,
                hintText: 'Location (City, Area)',
                prefixIcon: Icons.location_on_outlined,
              ),
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.p16),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPropertyType,
                    hint: const Text('Property Type'),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: propertyTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
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
                hintText: 'Description',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              AppTextField(
                controller: _phoneController,
                hintText: 'Contact Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.p16),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: _selectedImages.isEmpty ? 120 : null,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImages.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: AppSizes.p8),
                            Text(
                              'Upload Media',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(AppSizes.p8),
                          child: Wrap(
                            spacing: AppSizes.p8,
                            runSpacing: AppSizes.p8,
                            children: [
                              ..._selectedImages.asMap().entries.map((entry) {
                                int idx = entry.key;
                                XFile image = entry.value;
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(image.path),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(idx),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Submit Property',
                      onPressed: _submitProperty,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
