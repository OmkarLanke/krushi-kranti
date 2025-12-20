import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../services/subscription_service.dart';

/// Welcome/Onboarding screens for unsubscribed users.
/// Shows subscription benefits and guides to subscribe.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingSubscription = true;
  List<WelcomePage>? _pages;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    // Check if user is already subscribed - if yes, redirect to dashboard
    try {
      final subStatus = await SubscriptionService.getSubscriptionStatus();
      final isSubscribed = subStatus['isSubscribed'] == true || 
                          subStatus['subscriptionStatus'] == 'ACTIVE';
      
      if (isSubscribed && mounted) {
        // User is already subscribed, redirect to dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        return;
      }
    } catch (_) {
      // If API fails, check local storage
      final isLocallySubscribed = await StorageService.isSubscribed();
      if (isLocallySubscribed && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isCheckingSubscription = false;
      });
    }
  }

  List<WelcomePage> _getPages(AppLocalizations l10n) {
    return [
      WelcomePage(
        title: l10n.welcomePage1Title,
        subtitle: l10n.welcomePage1Subtitle,
        image: "assets/images/welcome_1.png",
        features: [
          FeatureItem(icon: Icons.cloud_outlined, label: l10n.welcomePage1Feature1),
          FeatureItem(icon: Icons.grass_outlined, label: l10n.welcomePage1Feature2),
          FeatureItem(icon: Icons.person_outline, label: l10n.welcomePage1Feature3),
        ],
        backgroundColor: const Color(0xFF32CD32), // Green gradient approx
      ),
      WelcomePage(
        title: l10n.welcomePage2Title,
        subtitle: l10n.welcomePage2Subtitle,
        image: "assets/images/welcome_2.png",
        features: [
          FeatureItem(icon: Icons.percent, label: l10n.welcomePage2Feature1),
          FeatureItem(icon: Icons.check_circle_outline, label: l10n.welcomePage2Feature2),
          FeatureItem(icon: Icons.eco_outlined, label: l10n.welcomePage2Feature3),
        ],
        backgroundColor: const Color(0xFF32CD32),
      ),
      WelcomePage(
        title: l10n.welcomePage3Title,
        subtitle: l10n.welcomePage3Subtitle,
        image: "assets/images/welcome_3.png",
        features: [
          FeatureItem(icon: Icons.favorite_border, label: l10n.welcomePage3Feature1),
          FeatureItem(icon: Icons.bug_report_outlined, label: l10n.welcomePage3Feature2),
          FeatureItem(icon: Icons.person_search_outlined, label: l10n.welcomePage3Feature3),
        ],
        footerText: l10n.welcomePage3Footer,
        backgroundColor: const Color(0xFF32CD32),
      ),
      WelcomePage(
        title: l10n.welcomePage4Title,
        subtitle: l10n.welcomePage4Subtitle,
        image: "assets/images/welcome_4.png",
        features: [
          FeatureItem(icon: Icons.verified_user_outlined, label: l10n.welcomePage4Feature1),
          FeatureItem(icon: Icons.thumb_up_alt_outlined, label: l10n.welcomePage4Feature2),
          FeatureItem(icon: Icons.currency_rupee, label: l10n.welcomePage4Feature3),
        ],
        footerText: l10n.welcomePage4Footer,
        backgroundColor: const Color(0xFF32CD32),
      ),
      WelcomePage(
        title: l10n.welcomePage5Title,
        subtitle: l10n.welcomePage5Subtitle,
        image: "assets/images/welcome_5.png",
        features: [],
        backgroundColor: const Color(0xFF32CD32),
        isLastPage: true,
        benefits: [
          l10n.welcomePage5Benefit1,
          l10n.welcomePage5Benefit2,
          l10n.welcomePage5Benefit3,
          l10n.welcomePage5Benefit4,
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_pages != null && _currentPage < _pages!.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToSubscribe() {
    // Navigate directly to subscription payment page
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.subscription,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);
    _pages = pages; // Store pages for use in other methods
    
    // Show loading while checking subscription
    if (_isCheckingSubscription) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.krushiKranti,
          style: const TextStyle(
            color: Color(0xFF1B5E20), // Dark Green
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _goToSubscribe,
            child: Text(
              l10n.skip,
              style: const TextStyle(
                color: Color(0xFF2E7D32), // Dark Green
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return _buildPage(pages[index], l10n);
              },
            ),
          ),
          
          // Page indicator dots
          _buildPageIndicator(pages.length),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPage(WelcomePage page, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF66BB6A), // Light Green
            Color(0xFF2E7D32), // Dark Green
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          
          if (page.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white, // White color for subtitle
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Image
          Expanded(
            flex: 4,
            child: _buildWelcomeImage(page.image),
          ),

          const SizedBox(height: 20),

          if (page.isLastPage) _buildLastPageContent(page) else _buildFeatureIcons(page),

          const Spacer(),

          // Footer Text
          if (page.footerText != null) ...[
            Text(
              page.footerText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: page.isLastPage ? _goToSubscribe : _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // Gold/Yellow
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                page.isLastPage ? l10n.subscribeNowWelcome : l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index
                  ? const Color(0xFF2E7D32) // Dark Green for active dot
                  : const Color(0xFF66BB6A).withOpacity(0.4), // Light Green for inactive dots
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeImage(String imagePath) {
    // Ensure the path doesn't have a leading slash for Flutter Web compatibility
    final String assetPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      package: null, // Explicitly set package to null to avoid issues
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $assetPath');
        debugPrint('Error: $error');
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(
                      l10n.imageNotFound,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      assetPath,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcons(WelcomePage page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: page.features.map((feature) {
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature.icon,
                  size: 30,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 3,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLastPageContent(WelcomePage page) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20), // Dark green box
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.welcomePage5KycText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...page.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class WelcomePage {
  final String title;
  final String subtitle;
  final String image;
  final List<FeatureItem> features;
  final Color backgroundColor;
  final bool isLastPage;
  final List<String> benefits;
  final String? footerText;

  WelcomePage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.features,
    required this.backgroundColor,
    this.isLastPage = false,
    this.benefits = const [],
    this.footerText,
  });
}

class FeatureItem {
  final IconData icon;
  final String label;

  FeatureItem({required this.icon, required this.label});
}

