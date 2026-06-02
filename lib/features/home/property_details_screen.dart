import 'package:flutter/material.dart';
import '../../models/admin_post_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/property_card.dart';
import '../../widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  AdminPostModel? _property;

  @override
  void initState() {
    super.initState();
    _fetchProperty();
  }

  Future<void> _fetchProperty() async {
    final property = await _firestoreService.getAdminPostById(widget.propertyId);
    if (mounted) {
      setState(() {
        _property = property;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 800,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _property == null
                  ? const Center(child: Text('Property not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: PropertyCard(property: _property!),
                    ),
        ),
      ),
    );
  }
}
