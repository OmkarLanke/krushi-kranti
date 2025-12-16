import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
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
      final response = await HttpService.get("farmer/profile/my-details");
      
      // Debug: Print full response to see structure
      print("=== My Details API Response ===");
      print("Full response: $response");
      print("Response type: ${response.runtimeType}");
      
      // Handle different response structures
      Map<String, dynamic> data = {};
      if (response is Map<String, dynamic>) {
        // Check if data is nested in 'data' field
        if (response.containsKey('data')) {
          data = response['data'] ?? {};
          print("Data found in 'data' field");
        } else {
          // Response itself might be the data
          data = response;
          print("Using response as data directly");
        }
      }
      
      print("=== Extracted Data ===");
      print("Data keys: ${data.keys.toList()}");
      print("firstName: ${data['firstName']}");
      print("lastName: ${data['lastName']}");
      print("dateOfBirth: ${data['dateOfBirth']}");
      print("gender: ${data['gender']}");
      print("pincode: ${data['pincode']}");
      print("village: ${data['village']}");
      print("district: ${data['district']}");
      print("taluka: ${data['taluka']}");
      print("state: ${data['state']}");
      print("email: ${data['email']}");
      print("phoneNumber: ${data['phoneNumber']}");
      print("alternatePhone: ${data['alternatePhone']}");
      
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        print("Error loading profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load profile: ${e.toString().replaceFirst("Exception: ", "")}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Not provided";
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

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return "Not provided";
    return gender.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Details",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top "Complete Profile" banner if any critical field is missing
                  if (_isProfileIncomplete()) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.creamBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: AppColors.brandGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Profile Incomplete",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Please complete your profile details.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to onboarding personal flow to edit details
                              Navigator.pushNamed(context, "/onboarding_personal");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Complete Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Personal Details Section
                  _buildSectionTitle("Personal Details"),
                  const SizedBox(height: 16),
                  _buildDetailField("First Name", _profileData['firstName'] ?? "Not provided"),
                  const SizedBox(height: 16),
                  _buildDetailField("Last Name", _profileData['lastName'] ?? "Not provided"),
                  const SizedBox(height: 16),
                  _buildDetailField("Date of Birth", _formatDate(_profileData['dateOfBirth']?.toString())),
                  const SizedBox(height: 16),
                  _buildDetailField("Gender", _formatGender(_profileData['gender']?.toString())),
                  
                  const SizedBox(height: 32),
                  
                  // Contact Details Section
                  _buildSectionTitle("Contact Details"),
                  const SizedBox(height: 16),
                  _buildDetailField("Email", _profileData['email'] ?? "Not provided", icon: Icons.email),
                  const SizedBox(height: 16),
                  _buildDetailField("Phone Number", _profileData['phoneNumber'] ?? "Not provided", icon: Icons.phone),
                  const SizedBox(height: 16),
                  _buildDetailField("Alternate Phone", _profileData['alternatePhone'] ?? "Not provided", icon: Icons.phone_android),
                  
                  const SizedBox(height: 32),
                  
                  // Address Details Section
                  _buildSectionTitle("Address Details"),
                  const SizedBox(height: 16),
                  _buildDetailField("Pincode", _profileData['pincode'] ?? "Not provided", icon: Icons.pin),
                  const SizedBox(height: 16),
                  _buildDetailField("Village", _profileData['village'] ?? "Not provided", icon: Icons.location_on),
                  const SizedBox(height: 16),
                  _buildDetailField("Taluka", _profileData['taluka'] ?? "Not provided", icon: Icons.location_city),
                  const SizedBox(height: 16),
                  _buildDetailField("District", _profileData['district'] ?? "Not provided", icon: Icons.map),
                  const SizedBox(height: 16),
                  _buildDetailField("State", _profileData['state'] ?? "Not provided", icon: Icons.public),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.brandGreen,
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.brandGreen),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Determine if profile is incomplete based on key fields.
  /// If all these are filled, we hide the top banner.
  bool _isProfileIncomplete() {
    final firstName = (_profileData['firstName'] ?? '').toString().trim();
    final lastName = (_profileData['lastName'] ?? '').toString().trim();
    final phone = (_profileData['phoneNumber'] ?? '').toString().trim();
    final pincode = (_profileData['pincode'] ?? '').toString().trim();
    final village = (_profileData['village'] ?? '').toString().trim();

    return firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        pincode.isEmpty ||
        village.isEmpty;
  }
}

