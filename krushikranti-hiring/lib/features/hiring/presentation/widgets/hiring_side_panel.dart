import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HiringSidePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const HiringSidePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF66BB6A), // Green 400 (Light & Fresh)
            Color(0xFF1B5E20), // Green 900 (Deep Brand Green)
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional shapes/circles)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),

                
                const SizedBox(height: 40),
                
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 48),

                // Features List
                ...features.map((feature) => _buildFeatureItem(feature)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.black, size: 14),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
