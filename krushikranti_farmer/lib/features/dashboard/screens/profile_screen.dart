import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/models/setup_state.dart';
import '../../../core/services/setup_state_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../../dashboard/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "";
  String userEmail = "";
  String userPicPath = "";
  bool _isLoading = true;
  SetupState _setupState = const SetupState();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSetupState();
  }

  Future<void> _loadSetupState() async {
    final state = await SetupStateService.load();
    if (!mounted) return;
    setState(() {
      _setupState = state;
    });
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
              userName = "";
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
            userName = "";
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
          userName = "";
          userEmail = "";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.krushiKranti,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          _buildCompactLanguageSelector(),
          const SizedBox(width: 16),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. PROFILE HEADER CARD ---
            _buildProfileHeaderCard(l10n),

            const SizedBox(height: 24),

            // --- 2. MENU SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _buildSectionTitle(l10n.profileSectionAccount, l10n),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(Icons.badge_outlined, l10n.myDetails,
                          onTap: () {
                        Navigator.pushNamed(context, AppRoutes.myDetails);
                      }),
                      _buildMenuItemDivider(),
                      _buildMenuItem(
                          Icons.agriculture_outlined, l10n.farmDetails,
                          onTap: () {
                        Navigator.pushNamed(context, AppRoutes.farmList);
                      }),
                      _buildMenuItemDivider(),
                      _buildMenuItem(Icons.grass, l10n.cropDetails, onTap: () {
                        Navigator.pushNamed(context, AppRoutes.cropList);
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Services Section
                  _buildSectionTitle(l10n.profileSectionServices, l10n),
                  const SizedBox(height: 12),
                  _buildSubscriptionSection(l10n),
                  const SizedBox(height: 16),
                  _buildKycSection(l10n),

                  const SizedBox(height: 20),

                  // Financial Section
                  _buildSectionTitle(l10n.profileSectionFinancial, l10n),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                          Icons.account_balance_outlined, l10n.bankAccount,
                          onTap: () {}),
                      _buildMenuItemDivider(),
                      _buildMenuItem(
                          Icons.account_balance_wallet_outlined, l10n.finance,
                          onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Support Section
                  _buildSectionTitle(l10n.profileSectionSupport, l10n),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(Icons.help_outline, l10n.help,
                          onTap: () {}),
                      _buildMenuItemDivider(),
                      _buildMenuItem(Icons.info_outline, l10n.about,
                          onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- 3. LOGOUT BUTTON ---
                  _buildLogoutButton(context, l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(AppLocalizations l10n) {
    bool hasImage = userPicPath.isNotEmpty && File(userPicPath).existsSync();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.brandGreen),
              ),
            )
          : Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandGreen,
                        AppColors.brandGreen.withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(File(userPicPath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? Icon(
                            Icons.person,
                            size: 45,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName.trim().isEmpty
                                  ? l10n.guestFarmer
                                  : userName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (userEmail.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                userEmail,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Edit button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.brandGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 20,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildSubscriptionSection(AppLocalizations l10n) {
    if (!_setupState.hasSubscription) {
      return _buildInfoContextCard(
        title: "Subscription Incomplete",
        description:
            "Subscribe to unlock premium features like market access, expert advice, and better pricing.",
        icon: Icons.workspace_premium_outlined,
        iconColor: Colors.orange,
        bgColor: Colors.orange.shade50,
        borderColor: Colors.orange.shade200,
      );
    } else {
      return _buildMenuCard(
        children: [
          _buildMenuItem(Icons.verified, "${l10n.subscription} - Active",
              onTap: () => Navigator.pushNamed(context, AppRoutes.subscription))
        ],
      );
    }
  }

  Widget _buildKycSection(AppLocalizations l10n) {
    final isComplete = _setupState.hasKyc;

    if (!isComplete) {
      return _buildInfoContextCard(
        title: "KYC Incomplete",
        description:
            "Complete your KYC to unlock funding requests and high-yield financial options.",
        icon: _setupState.hasSubscription
            ? Icons.verified_user_outlined
            : Icons.lock_outline,
        iconColor: _setupState.hasSubscription ? Colors.orange : Colors.grey,
        bgColor: _setupState.hasSubscription
            ? Colors.orange.shade50
            : Colors.grey.shade50,
        borderColor: _setupState.hasSubscription
            ? Colors.orange.shade200
            : Colors.grey.shade200,
      );
    } else {
      return _buildMenuCard(
        children: [
          _buildMenuItem(
              Icons.verified_user, "${l10n.kyc} - ${l10n.kycComplete}",
              onTap: () => Navigator.pushNamed(context, AppRoutes.kycStatus))
        ],
      );
    }
  }

  Widget _buildInfoContextCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Text(description,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLanguageSelector() {
    final currentLocale = Provider.of<LocaleProvider>(context).locale;

    // Get current language code for display
    String currentLangCode = currentLocale.languageCode.toUpperCase();
    if (currentLocale.languageCode == 'hi') {
      currentLangCode = 'HI';
    } else if (currentLocale.languageCode == 'mr') {
      currentLangCode = 'MR';
    } else {
      currentLangCode = 'EN';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showLanguageSelectionDialog();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                currentLangCode,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    final currentLocale =
        Provider.of<LocaleProvider>(context, listen: false).locale;
    String selectedLang = currentLocale.languageCode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectLanguage,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLanguageOption(
                      context: dialogContext,
                      code: "en",
                      name: AppLocalizations.of(context)!.languageEnglish,
                      selectedLang: selectedLang,
                      onTap: () {
                        setState(() {
                          selectedLang = "en";
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: dialogContext,
                      code: "hi",
                      name: AppLocalizations.of(context)!.languageHindi,
                      selectedLang: selectedLang,
                      onTap: () {
                        setState(() {
                          selectedLang = "hi";
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: dialogContext,
                      code: "mr",
                      name: AppLocalizations.of(context)!.languageMarathi,
                      selectedLang: selectedLang,
                      onTap: () {
                        setState(() {
                          selectedLang = "mr";
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<LocaleProvider>(context,
                                      listen: false)
                                  .setLocale(Locale(selectedLang));
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.saveChanges,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required String name,
    required String selectedLang,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedLang == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandGreen.withOpacity(0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.brandGreen : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.brandGreen : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Clear notifications before logout to prevent cross-user data leakage
          NotificationService().clearOnLogout();
          await StorageService.clearSession();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.splash,
            (route) => false,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade400,
                Colors.red.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.logout,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
