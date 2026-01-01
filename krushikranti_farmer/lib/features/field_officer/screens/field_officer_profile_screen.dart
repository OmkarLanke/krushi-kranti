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
      try {
        final response = await HttpService.get("field-officer/profile");
        
        Map<String, dynamic> data = {};
        if (response is Map<String, dynamic>) {
          if (response.containsKey('data')) {
            final dataValue = response['data'];
            if (dataValue is Map<String, dynamic>) {
              data = dataValue;
            }
          } else {
            data = response;
          }
        }

        if (mounted && data.isNotEmpty) {
          setState(() {
            _profileData = data;
            _isLoading = false;
          });

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
        if (mounted) {
           // Handle silent error
        }
      }

      final userData = await StorageService.getUserDetails();
      if (mounted) {
        setState(() {
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
    return username.isNotEmpty ? 'Username: $username' : '';
  }

  // UPDATED: Changed text to "Field Officer ID"
  String _getFieldOfficerId() {
    final fieldOfficerId = _profileData['fieldOfficerId'] ?? '';
    final userId = _profileData['userId'] ?? '';
    if (fieldOfficerId.toString().isNotEmpty) {
      return 'Field Officer ID: $fieldOfficerId';
    } else if (userId.toString().isNotEmpty) {
      return 'Field Officer ID: $userId';
    }
    return '';
  }

  String? _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split("-");
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 0;
        final day = parts[2];
        
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthStr = (month > 0 && month <= 12) ? months[month - 1] : parts[1];
        
        return "$day $monthStr $year";
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String? _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    return gender[0].toUpperCase() + gender.substring(1).toLowerCase();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
      backgroundColor: const Color(0xFFF9FAFB), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  
                  _buildSectionHeader('Contact Information'),
                  _buildModernField(
                    label: 'Email Address',
                    value: _profileData['email']?.toString() ?? '',
                    icon: Icons.email_rounded,
                    placeholder: 'Not provided',
                  ),
                  _buildModernField(
                    label: 'Phone Number',
                    value: _profileData['phoneNumber']?.toString() ?? '',
                    icon: Icons.phone_rounded,
                    placeholder: '--',
                  ),
                  _buildModernField(
                    label: 'Alternate Number',
                    value: _profileData['alternatePhone']?.toString() ?? '',
                    icon: Icons.phone_iphone_rounded,
                    placeholder: 'Not provided',
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Personal Details'),
                  _buildModernField(
                    label: 'Date of Birth',
                    value: _formatDate(_profileData['dateOfBirth']?.toString()) ?? '',
                    icon: Icons.calendar_month_rounded,
                    placeholder: '--',
                  ),
                  _buildModernField(
                    label: 'Gender',
                    value: _formatGender(_profileData['gender']?.toString()) ?? '',
                    icon: Icons.person_outline_rounded,
                    placeholder: '--',
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Location'),
                  _buildAddressCard(),

                  const SizedBox(height: 40),

                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: (_profileData['profilePic'] != null && _profileData['profilePic'].toString().isNotEmpty)
                      ? NetworkImage(_profileData['profilePic'].toString())
                      : null,
                  child: (_profileData['profilePic'] == null || _profileData['profilePic'].toString().isEmpty)
                      ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                      : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.verified, color: Colors.orange, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _getFullName(),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        if (_getUsername().isNotEmpty)
          Text(
            _getUsername(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getFieldOfficerId(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required String value,
    required IconData icon,
    String placeholder = '',
  }) {
    final hasValue = value.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : placeholder,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: hasValue ? const Color(0xFF1F2937) : Colors.grey.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                'Address Details',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.only(bottom: 16)),
          
          _buildAddressRow('Pincode', _profileData['pincode']),
          _buildAddressRow('District', _profileData['district']),
          _buildAddressRow('Taluka', _profileData['taluka']),
          _buildAddressRow('Village', _profileData['village']),
          _buildAddressRow('State', _profileData['state']),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            (value == null || value.isEmpty) ? '--' : value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}