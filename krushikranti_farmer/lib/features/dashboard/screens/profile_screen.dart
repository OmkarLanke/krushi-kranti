import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String userEmail = "";
  String userPicPath = "";
  bool _isLoading = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    final isSubscribed = await StorageService.isSubscribed();
    if (mounted) {
      setState(() {
        _isSubscribed = isSubscribed;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to fetch from API first
      try {
        final response = await HttpService.get("farmer/profile/my-details");
        final data = response['data'] ?? {};
        
        if (mounted && data.isNotEmpty) {
          setState(() {
            String first = data['firstName'] ?? "";
            String last = data['lastName'] ?? "";
            
            if (first.isEmpty && last.isEmpty) {
              userName = "Guest Farmer";
            } else {
              userName = "$first $last";
            }

            userEmail = data['email'] ?? "";
            userPicPath = ""; // Profile pic path not in API response yet
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
        // If API fails, fall back to local storage
        print("API Error: $apiError");
      }

      // Fallback to local storage
      final userData = await StorageService.getUserDetails();
      
      if (mounted) {
        setState(() {
          String first = userData['firstName'] ?? "";
          String last = userData['lastName'] ?? "";
          
          if (first.isEmpty && last.isEmpty) {
            userName = "Guest Farmer";
          } else {
            userName = "$first $last"; 
          }

          userEmail = userData['email'] ?? "";
          userPicPath = userData['pic'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "Guest Farmer";
          userEmail = "No Email";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white, 
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          l10n.krushiKranti, 
          style: GoogleFonts.poppins(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // --- 1. PROFILE HEADER ---
            _buildProfileHeader(),
            
            const SizedBox(height: 40), // Increased spacing
            
            // --- 2. MENU LIST (Ordered as requested) ---
            // 1. My Details
            _buildMenuItem(Icons.badge_outlined, l10n.myDetails, onTap: () {
              Navigator.pushNamed(context, AppRoutes.myDetails);
            }),
            _buildDivider(),

            // 2. Farm Details
            _buildMenuItem(Icons.agriculture_outlined, l10n.farmDetails, onTap: () {
              Navigator.pushNamed(context, AppRoutes.farmList);
            }),
            _buildDivider(),

            // 3. Crop Details
            _buildMenuItem(Icons.grass, "Crop Details", onTap: () {
              Navigator.pushNamed(context, AppRoutes.cropList);
            }),
            _buildDivider(),

            // 4. Subscription
            _buildSubscriptionMenuItem(),
            _buildDivider(),

            // 5. KYC
            _buildMenuItem(Icons.verified_user_outlined, l10n.kyc, onTap: () {}),
            _buildDivider(),
            
            // ✅ CHANGED: Used standard Bank Icon instead of Bag
            _buildMenuItem(Icons.account_balance_outlined, l10n.bankAccount, onTap: () {}),
            _buildDivider(),
            
            _buildMenuItem(Icons.account_balance_wallet_outlined, l10n.finance, onTap: () {}),
            _buildDivider(),
            
            _buildMenuItem(Icons.help_outline, l10n.help, onTap: () {}),
            _buildDivider(),
            
            _buildMenuItem(Icons.info_outline, l10n.about, onTap: () {}),
            
            const SizedBox(height: 50), // Increased spacing before logout

            // --- 3. LOGOUT BUTTON ---
            _buildLogoutButton(context, l10n),
            const SizedBox(height: 50), 
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    bool hasImage = userPicPath.isNotEmpty && File(userPicPath).existsSync();

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        // Avatar Box
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade200, 
            borderRadius: BorderRadius.circular(20),
            image: hasImage 
              ? DecorationImage(
                  image: FileImage(File(userPicPath)),
                  fit: BoxFit.cover,
                )
              : null,
          ),
          child: !hasImage 
              ? Icon(Icons.person, size: 40, color: Colors.grey.shade400) 
              : null,
        ),
        const SizedBox(width: 20), // Increased gap
        
        // Name & Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName, 
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, 
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 16, color: AppColors.brandGreen), 
                ],
              ),
              const SizedBox(height: 4),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail, 
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey, 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4), // ✅ Added padding for breathing room
      leading: Icon(icon, color: Colors.black87, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16, // Slightly larger font
          fontWeight: FontWeight.w500, 
          color: Colors.black87,
        ),
      ),
      // Design keeps it simple without trailing arrows, matching your screenshot
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1);
  }

  Widget _buildSubscriptionMenuItem() {
    return ListTile(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.subscription);
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isSubscribed ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isSubscribed ? Icons.verified : Icons.card_membership,
          color: _isSubscribed ? Colors.green : Colors.orange,
          size: 24,
        ),
      ),
      title: Text(
        "Subscription",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        _isSubscribed ? "Active" : "Subscribe Now - ₹999/year",
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: _isSubscribed ? Colors.green : Colors.orange,
        ),
      ),
      trailing: _isSubscribed 
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Subscribe",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        await StorageService.clearSession();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.splash, 
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppColors.brandGreen, size: 20),
            const SizedBox(width: 10),
            Text(
              l10n.logout,
              style: GoogleFonts.poppins(
                color: AppColors.brandGreen,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}