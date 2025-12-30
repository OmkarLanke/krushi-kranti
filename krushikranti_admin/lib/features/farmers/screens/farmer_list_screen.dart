import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/farmer_models.dart';
import '../services/farmer_service.dart';
import 'farmer_detail_screen.dart';
import 'assign_field_officer_dialog.dart';

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  List<FarmerSummary> _farmers = [];
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _error;
  
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 20;
  
  String? _searchQuery;
  String? _kycFilter;
  String? _subscriptionFilter;
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AdminFarmerService.getFarmers(
        page: _currentPage,
        size: _pageSize,
        search: _searchQuery,
        kycStatus: _kycFilter,
        subscriptionStatus: _subscriptionFilter,
      );

      setState(() {
        _farmers = response.farmers;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
        _stats = response.stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 0;
    });
    _loadFarmers();
  }

  void _onKycFilterChanged(String? value) {
    setState(() {
      _kycFilter = value;
      _currentPage = 0;
    });
    _loadFarmers();
  }

  void _onSubscriptionFilterChanged(String? value) {
    setState(() {
      _subscriptionFilter = value;
      _currentPage = 0;
    });
    _loadFarmers();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadFarmers();
  }

  void _viewFarmerDetail(FarmerSummary farmer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FarmerDetailDialog(farmerId: farmer.farmerId),
    );
  }

  void _assignFieldOfficer(FarmerSummary farmer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignFieldOfficerDialog(
        farmerUserId: farmer.userId,
        farmerId: farmer.farmerId,
      ),
    ).then((success) {
      if (success == true) {
        // Refresh the list if assignment was successful
        _loadFarmers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          
          // Stats Cards
          _buildStatsSection(),
          const SizedBox(height: 24),
          
          // Search and Filters
          _buildFiltersSection(),
          const SizedBox(height: 16),
          
          // Farmers Table
          Expanded(
            child: _buildFarmersTable(),
          ),
          
          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Farmer Management',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Export functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export feature coming soon')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Registered',
            value: stats?.totalFarmers.toString() ?? '0',
            subtitle: '+12% this Month',
            icon: Icons.people,
            color: AppColors.brandGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Pending Approvals',
            value: stats?.pendingKyc.toString() ?? '0',
            subtitle: '+8% this Month',
            icon: Icons.pending_actions,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Verified Farmers',
            value: stats?.verifiedKyc.toString() ?? '0',
            subtitle: '+8% this Month',
            icon: Icons.verified_user,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Active Subscriptions',
            value: stats?.activeSubscriptions.toString() ?? '0',
            subtitle: '+6% this Month',
            icon: Icons.card_membership,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search farmers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.brandGreen),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // KYC Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _kycFilter,
              decoration: InputDecoration(
                labelText: 'KYC Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                DropdownMenuItem(value: 'VERIFIED', child: Text('Verified')),
              ],
              onChanged: _onKycFilterChanged,
            ),
          ),
          const SizedBox(width: 16),
          
          // Subscription Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _subscriptionFilter,
              decoration: InputDecoration(
                labelText: 'Subscription',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'EXPIRED', child: Text('Expired')),
              ],
              onChanged: _onSubscriptionFilterChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmersTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFarmers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No farmers found',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.brandGreen.withOpacity(0.1),
            ),
            headingTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            columns: const [
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Full Name')),
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Phone No')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('KYC Status')),
              DataColumn(label: Text('Subscription')),
              DataColumn(label: Text('Farms')),
              DataColumn(label: Text('Field Officer')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _farmers.map((farmer) => _buildFarmerRow(farmer)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildFarmerRow(FarmerSummary farmer) {
    return DataRow(
      cells: [
        DataCell(Text(farmer.userId.toString())),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                child: Text(
                  farmer.fullName.isNotEmpty ? farmer.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(farmer.fullName.isEmpty ? 'Not Set' : farmer.fullName),
            ],
          ),
        ),
        DataCell(Text(farmer.username)),
        DataCell(Text(farmer.phoneNumber)),
        DataCell(Text('${farmer.village ?? '-'}, ${farmer.district ?? '-'}')),
        DataCell(_buildStatusChip(farmer.kycStatus, _getKycStatusColor(farmer.kycStatus))),
        DataCell(_buildStatusChip(farmer.subscriptionStatus, _getSubStatusColor(farmer.subscriptionStatus))),
        DataCell(Text('${farmer.verifiedFarmCount}/${farmer.farmCount}')),
        DataCell(
          TextButton.icon(
            onPressed: () => _assignFieldOfficer(farmer),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Assign'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: AppColors.brandGreen),
                onPressed: () => _viewFarmerDetail(farmer),
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toLowerCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getKycStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return AppColors.success;
      case 'PARTIAL':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getSubStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'EXPIRED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          ),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: GoogleFonts.poppins(),
          ),
          Text(
            ' ($_totalElements total)',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

