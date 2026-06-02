import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/buyer_requirement_model.dart';
import '../../services/firestore_service.dart';

class SubmitRequirementScreen extends StatefulWidget {
  const SubmitRequirementScreen({super.key});

  @override
  State<SubmitRequirementScreen> createState() =>
      _SubmitRequirementScreenState();
}

class _SubmitRequirementScreenState extends State<SubmitRequirementScreen> {
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
        _userEmail = user.email; // Capture email
        if (user.phone.isNotEmpty) {
          _phoneController.text = user.phone;
        }
      });
    }
  }

  int _transactionType = 0; // 0 for Want to Buy, 1 for Want to Rent
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

  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequirement() async {
    final budgetText = _budgetController.text.trim();
    final location = _locationController.text.trim();
    final duration = _durationController.text.trim();
    final description = _descriptionController.text.trim();

    final phone = _phoneController.text.trim();

    if (budgetText.isEmpty ||
        location.isEmpty ||
        description.isEmpty ||
        phone.isEmpty ||
        selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Very simple max/min parser placeholder!
    final double budget =
        double.tryParse(budgetText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _isLoading = true;
    });

    try {
      final docId = FirebaseFirestore.instance
          .collection('buyer_requirements')
          .doc()
          .id;
      final requirement = BuyerRequirementModel(
        id: docId,
        userId: user.uid,
        userName: _userName ?? user.displayName ?? 'User',
        transactionType: _transactionType == 0 ? 'buy' : 'rent',
        minBudget: budget * 0.8, // Basic mock range logic
        maxBudget: budget,
        preferredLocation: location,
        propertyType: selectedPropertyType!,
        duration: _transactionType == 1 && duration.isNotEmpty
            ? duration
            : null,
        description: description,
        contactPhone: phone,
        contactEmail: _userEmail ?? user.email ?? '', // Pass email
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirestoreService().submitRequirement(requirement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Requirement Submitted successfully! Broker will contact soon.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Submitting Requirement: $e')),
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
      appBar: AppBar(title: const Text('Submit Requirement')),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToggleSwitch(
                optionText1: 'Want to Buy',
                optionText2: 'Want to Rent',
                onToggle: (index) {
                  setState(() {
                    _transactionType = index;
                  });
                },
              ),
              const SizedBox(height: AppSizes.p24),
              AppTextField(
                controller: _budgetController,
                hintText: 'Target Budget / Maximum Limit',
                prefixIcon: Icons.attach_money,
              ),
              AppTextField(
                controller: _locationController,
                hintText: 'Preferred Location (City, Area)',
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
              if (_transactionType == 1)
                AppTextField(
                  controller: _durationController,
                  hintText: 'Duration (months/years)',
                  prefixIcon: Icons.timer_outlined,
                ),
              AppTextField(
                controller: _descriptionController,
                hintText: 'Special Requirements / Description',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              AppTextField(
                controller: _phoneController,
                hintText: 'Contact Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.p32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Submit Requirement',
                      onPressed: _submitRequirement,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
