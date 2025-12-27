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
    SidebarItem(title: 'Dashboard', icon: Icons.dashboard, routeName: 'dashboard'),
    SidebarItem(title: 'Farmer', icon: Icons.people, routeName: 'farmers'),
    SidebarItem(title: 'Field Officer', icon: Icons.badge, routeName: 'field-officers'),
    SidebarItem(title: 'Product & Pricing', icon: Icons.inventory_2, routeName: 'products'),
    SidebarItem(title: 'Inventory', icon: Icons.warehouse, routeName: 'inventory'),
    SidebarItem(title: 'Order & Logistics', icon: Icons.local_shipping, routeName: 'orders'),
    SidebarItem(title: 'Payment & Finance', icon: Icons.payment, routeName: 'payments'),
    SidebarItem(title: 'User', icon: Icons.person, routeName: 'users'),
    SidebarItem(title: 'Support', icon: Icons.support_agent, routeName: 'support'),
    SidebarItem(title: 'Configurations', icon: Icons.settings, routeName: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Krushi Kranti',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white12, height: 1),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandGreenLight.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? AppColors.brandGreenLight : Colors.white70,
          size: 22,
        ),
        title: Text(
          item.title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => onItemSelected(item.routeName),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: Colors.white10,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout,
        color: Colors.white70,
        size: 22,
      ),
      title: Text(
        'Logout',
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      onTap: () => onItemSelected('logout'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.white.withOpacity(0.05),
      hoverColor: Colors.white10,
    );
  }
}

