import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

class FieldOfficerProfileScreen extends StatefulWidget {
  const FieldOfficerProfileScreen({super.key});

  @override
  State<FieldOfficerProfileScreen> createState() => _FieldOfficerProfileScreenState();
}

class _FieldOfficerProfileScreenState extends State<FieldOfficerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  bool _isAddressExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to fetch from API first
      try {
        final response = await HttpService.get("field-officer/profile");
        
        // Handle different response structures
        Map<String, dynamic> data = {};
        if (response is Map<String, dynamic>) {
          // ApiResponse format: { "message": "...", "data": {...} }
          if (response.containsKey('data')) {
            final dataValue = response['data'];
            if (dataValue is Map<String, dynamic>) {
              data = dataValue;
            } else {
              data = {};
            }
          } else {
            // Response might be the data directly
            data = response;
          }
        }

        if (mounted && data.isNotEmpty) {
          setState(() {
            _profileData = data;
            _isLoading = false;
          });

          // Also update local storage
          await StorageService.saveAuthDetails(
            email: data['email'] ?? "",
            phone: data['phoneNumber'] ?? "",
          );
          await StorageService.savePersonalDetails(
            firstName: data['firstName'] ?? "",
            lastName: data['lastName'] ?? "",
            dob: data['dateOfBirth']?.toString() ?? "",
            gender: data['gender']?.toString() ?? "",
            profilePicPath: null,
          );
          return;
        }
      } catch (apiError) {
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${apiError.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Fallback to local storage only if API completely fails
      // Don't show fallback data if API returned an error about missing profile
      final userData = await StorageService.getUserDetails();
      if (mounted) {
        setState(() {
          // Only use local storage if we have some data, otherwise show empty
          if (userData['firstName']?.toString().isNotEmpty == true || 
              userData['email']?.toString().isNotEmpty == true) {
            _profileData = {
              'firstName': userData['firstName'] ?? '',
              'lastName': userData['lastName'] ?? '',
              'email': userData['email'] ?? '',
              'phoneNumber': userData['phone'] ?? '',
              'alternatePhone': userData['altPhone'] ?? '',
            };
          } else {
            // No data available - show empty state
            _profileData = {};
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFullName() {
    final firstName = _profileData['firstName'] ?? '';
    final lastName = _profileData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Field Officer' : fullName;
  }

  String _getUsername() {
    final username = _profileData['username'] ?? '';
    return username.isNotEmpty ? '@$username' : '';
  }

  String _getFieldOfficerId() {
    final fieldOfficerId = _profileData['fieldOfficerId'] ?? '';
    final userId = _profileData['userId'] ?? '';
    if (fieldOfficerId.toString().isNotEmpty) {
      return 'FO$fieldOfficerId';
    } else if (userId.toString().isNotEmpty) {
      return 'FO$userId';
    }
    return '';
  }

  String? _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Handle YYYY-MM-DD format from backend
      final parts = dateStr.split("-");
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}"; // DD/MM/YYYY
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String? _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
        return 'Other';
      default:
        return gender;
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.languageSelection,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Krushikranti',
          style: GoogleFonts.poppins(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // User Identification Section
                  Text(
                    _getFullName(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_getUsername().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getUsername(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_getFieldOfficerId().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_getFieldOfficerId()}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Email Field
                  _buildInputField(
                    label: 'Your Email',
                    icon: Icons.email_outlined,
                    value: _profileData['email']?.toString() ?? 'Not provided',
                  ),
                  const SizedBox(height: 16),

                  // Phone Number Field
                  _buildInputField(
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    value: _profileData['phoneNumber']?.toString() ?? 'Not provided',
                  ),
                  const SizedBox(height: 16),

                  // Alternate Number Field
                  _buildInputField(
                    label: 'Alternate Number',
                    icon: Icons.phone_android_outlined,
                    value: (_profileData['alternatePhone'] != null && _profileData['alternatePhone'].toString().isNotEmpty) 
                        ? _profileData['alternatePhone'].toString() 
                        : 'Not provided',
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth Field
                  _buildInputField(
                    label: 'Date of Birth',
                    icon: Icons.calendar_today_outlined,
                    value: _formatDate(_profileData['dateOfBirth']?.toString()) ?? 'Not provided',
                  ),
                  const SizedBox(height: 16),

                  // Gender Field
                  _buildInputField(
                    label: 'Gender',
                    icon: Icons.person_outline,
                    value: _formatGender(_profileData['gender']?.toString()) ?? 'Not provided',
                  ),
                  const SizedBox(height: 24),

                  // Address Section
                  _buildAddressSection(),

                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    print("_buildInputField called for '$label' with value: '$value'");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(25),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isAddressExpanded = !_isAddressExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Address',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Icon(
                _isAddressExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        if (_isAddressExpanded) ...[
          const SizedBox(height: 16),
          _buildAddressDetail('Pincode', _profileData['pincode'] ?? ''),
          const SizedBox(height: 12),
          _buildAddressDetail('District', _profileData['district'] ?? ''),
          const SizedBox(height: 12),
          _buildAddressDetail('Taluka', _profileData['taluka'] ?? ''),
          const SizedBox(height: 12),
          _buildAddressDetail('Village', _profileData['village'] ?? ''),
          const SizedBox(height: 12),
          _buildAddressDetail('State', _profileData['state'] ?? ''),
        ],
      ],
    );
  }

  Widget _buildAddressDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value.isEmpty ? 'Not provided' : value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
