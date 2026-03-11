import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_localizations.dart';

class HiringScreenWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final Widget? sidePanel; // New optional parameter

  const HiringScreenWrapper({
    super.key,
    required this.child,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    this.sidePanel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: onBack ?? () => Navigator.pop(context),
                  ),
                  title: Column(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${AppStrings.tr('step')} $currentStep ${AppStrings.tr('of')} $totalSteps',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
          body: isDesktop
              ? Row(
                  children: [
                    // Left Side: Dynamic Side Panel OR Image (Full Height)
                    Expanded(
                      flex: 5,
                      child: sidePanel ?? Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/hiring_intro.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(color: Colors.black.withOpacity(0.1)),
                        ],
                      ),
                    ),
                    // Right Side: Form Content
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // Custom Header Area
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40.0,
                              vertical: 32.0,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                                  onPressed: onBack ?? () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStepIndicator(isDesktop: true),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 48), // Balance back button
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 600),
                                child: child,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: child,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStepIndicator({required bool isDesktop}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        bool isActive = index + 1 <= currentStep;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFFFD700) : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
