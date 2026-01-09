import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final String routeName;

  SidebarItem({
    required this.title,
    required this.icon,
    required this.routeName,
  });
}

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onItemSelected;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onItemSelected,
  });

  static final List<SidebarItem> items = [
    SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded, routeName: 'dashboard'),
    SidebarItem(title: 'Farmer', icon: Icons.people_rounded, routeName: 'farmers'),
    SidebarItem(title: 'Field Officer', icon: Icons.badge_rounded, routeName: 'field-officers'),
    SidebarItem(title: 'Product & Pricing', icon: Icons.inventory_2_rounded, routeName: 'products'),
    SidebarItem(title: 'Inventory', icon: Icons.warehouse_rounded, routeName: 'inventory'),
    SidebarItem(title: 'Order & Logistics', icon: Icons.local_shipping_rounded, routeName: 'orders'),
    SidebarItem(title: 'Payment & Finance', icon: Icons.payment_rounded, routeName: 'payments'),
    SidebarItem(title: 'User', icon: Icons.person_rounded, routeName: 'users'),
    SidebarItem(title: 'Support', icon: Icons.support_agent_rounded, routeName: 'support'),
    SidebarItem(title: 'Configurations', icon: Icons.settings_rounded, routeName: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
      color: AppColors.sidebarBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandGreenLight,
                        AppColors.brandGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreenLight.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  'Krushi Kranti',
                  style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                    color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentRoute == item.routeName;
                
                return _buildMenuItem(item, isSelected);
              },
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(item.routeName),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brandGreenLight.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.brandGreenLight.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandGreenLight.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
      ),
                  child: Icon(
          item.icon,
                    color: isSelected
                        ? AppColors.brandGreenLight
                        : Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
        ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
          item.title,
          style: GoogleFonts.poppins(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.85),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
            fontSize: 14,
                      letterSpacing: 0.2,
                    ),
          ),
        ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected('logout'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
      ),
              ),
              const SizedBox(width: 14),
              Text(
        'Logout',
        style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
          fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

