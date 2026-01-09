import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/farmer_models.dart';
import '../services/farmer_service.dart';
import 'farmer_detail_screen.dart';
import 'assign_field_officer_dialog.dart';

enum SortColumn {
  userId,
  fullName,
  username,
  phoneNumber,
  location,
  kycStatus,
  subscriptionStatus,
  farmCount,
  registeredAt,
}

enum SortDirection {
  ascending,
  descending,
}

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  List<FarmerSummary> _farmers = [];
  List<FarmerSummary> _filteredFarmers = [];
  List<FarmerSummary> _allFarmers = []; // All farmers for filtering and dropdowns
  DashboardStats? _stats;
  bool _isLoading = true;
  bool _isLoadingAllFarmers = false;
  String? _error;
  
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 5; // Changed to 5 farmers per page
  
  // Column-specific search queries
  String? _userIdSearch;
  String? _fullNameSearch;
  String? _usernameSearch;
  String? _phoneSearch;
  String? _locationSearch;
  String? _pincodeSearch;
  
  String? _kycFilter;
  String? _subscriptionFilter;
  String? _fieldOfficerFilter; // All, Assign, View, Manage
  
  // Advanced filters - Multi-select
  List<String> _selectedPincodes = [];
  List<String> _selectedVillages = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedStates = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showAdvancedFilters = false;
  
  // Legacy single filters (for backward compatibility with existing code)
  String? _pincodeFilter;
  
  // Sort state
  SortColumn? _sortColumn;
  SortDirection _sortDirection = SortDirection.descending;
  
  // Dropdown overlay state
  OverlayEntry? _dropdownOverlay;
  final Map<String, GlobalKey> _filterKeys = {};
  String? _openDropdownLabel;
  
  // Search controllers for each column
  final _userIdSearchController = TextEditingController();
  final _fullNameSearchController = TextEditingController();
  final _usernameSearchController = TextEditingController();
  final _phoneSearchController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _pincodeSearchController = TextEditingController();
  final _pincodeController = TextEditingController();
  Timer? _userIdSearchDebounce;
  Timer? _fullNameSearchDebounce;
  Timer? _usernameSearchDebounce;
  Timer? _phoneSearchDebounce;
  Timer? _locationSearchDebounce;
  Timer? _pincodeSearchDebounce;
  Timer? _pincodeDebounce;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    _loadStats();
  }

  @override
  void dispose() {
    _closeDropdown();
    _userIdSearchController.dispose();
    _fullNameSearchController.dispose();
    _usernameSearchController.dispose();
    _phoneSearchController.dispose();
    _locationSearchController.dispose();
    _pincodeSearchController.dispose();
    _pincodeController.dispose();
    _userIdSearchDebounce?.cancel();
    _fullNameSearchDebounce?.cancel();
    _usernameSearchDebounce?.cancel();
    _phoneSearchDebounce?.cancel();
    _locationSearchDebounce?.cancel();
    _pincodeSearchDebounce?.cancel();
    _pincodeDebounce?.cancel();
    super.dispose();
  }

  void _closeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    _openDropdownLabel = null;
  }

  Future<void> _loadAllFarmers() async {
    if (_allFarmers.isNotEmpty) return; // Already loaded
    
    setState(() {
      _isLoadingAllFarmers = true;
    });

    try {
      // Load all farmers for dropdown population
      final response = await AdminFarmerService.getFarmers(
        page: 0,
        size: 10000, // Large size to get all farmers
        search: null,
        kycStatus: null,
        subscriptionStatus: null,
      );

      setState(() {
        _allFarmers = response.farmers;
        _isLoadingAllFarmers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAllFarmers = false;
      });
    }
  }

  List<String> _getUniqueStates() {
    final states = _allFarmers
        .where((f) => f.state != null && f.state!.isNotEmpty)
        .map((f) => f.state!)
        .toSet()
        .toList();
    states.sort();
    return states;
  }

  List<String> _getUniqueDistricts() {
    final districts = _allFarmers
        .where((f) => f.district != null && f.district!.isNotEmpty)
        .map((f) => f.district!)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  List<String> _getUniquePincodes() {
    final pincodes = _allFarmers
        .where((f) => f.pincode != null && f.pincode!.isNotEmpty)
        .map((f) => f.pincode!)
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  List<String> _getUniqueVillages() {
    final villages = _allFarmers
        .where((f) => f.village != null && f.village!.isNotEmpty)
        .map((f) => f.village!)
        .toSet()
        .toList();
    villages.sort();
    return villages;
  }

  List<String> _getFilteredVillages() {
    List<FarmerSummary> filteredFarmers = _allFarmers;
    
    // Filter by selected states
    if (_selectedStates.isNotEmpty) {
      filteredFarmers = filteredFarmers
          .where((f) => _selectedStates.contains(f.state))
          .toList();
    }
    
    // Filter by selected districts
    if (_selectedDistricts.isNotEmpty) {
      filteredFarmers = filteredFarmers
          .where((f) => _selectedDistricts.contains(f.district))
          .toList();
    }
    
    final villages = filteredFarmers
        .where((f) => f.village != null && f.village!.isNotEmpty)
        .map((f) => f.village!)
        .toSet()
        .toList();
    villages.sort();
    return villages;
  }

  List<String> _getFilteredPincodes() {
    List<FarmerSummary> filteredFarmers = _allFarmers;
    
    // Filter by selected states
    if (_selectedStates.isNotEmpty) {
      filteredFarmers = filteredFarmers
          .where((f) => _selectedStates.contains(f.state))
          .toList();
    }
    
    // Filter by selected districts
    if (_selectedDistricts.isNotEmpty) {
      filteredFarmers = filteredFarmers
          .where((f) => _selectedDistricts.contains(f.district))
          .toList();
    }
    
    // Filter by selected villages
    if (_selectedVillages.isNotEmpty) {
      filteredFarmers = filteredFarmers
          .where((f) => _selectedVillages.contains(f.village))
          .toList();
    }
    
    final pincodes = filteredFarmers
        .where((f) => f.pincode != null && f.pincode!.isNotEmpty)
        .map((f) => f.pincode!)
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  Future<void> _loadFarmers({bool forceReload = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all farmers for filtering
      // Always reload if pincode filter is set (to get backend-filtered results)
      // Or if forceReload is true, or if _allFarmers is empty
      if (_allFarmers.isEmpty || _pincodeFilter != null || forceReload) {
        final allResponse = await AdminFarmerService.getFarmers(
          page: 0,
          size: 10000,
          search: null,
          kycStatus: null,
          subscriptionStatus: null,
          pincode: _pincodeFilter, // Use backend pincode filtering
        );
        setState(() {
          _allFarmers = allResponse.farmers;
        });
      }

      // Apply filters and pagination
      _applyFiltersAndReload();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      // First try to get stats from the dedicated stats endpoint
      final stats = await AdminFarmerService.getDashboardStats();
      
      // If stats have real values (not all zeros), use them
      if (stats.verifiedKyc > 0 || stats.pendingKyc > 0 || stats.activeSubscriptions > 0) {
    setState(() {
          _stats = stats;
        });
        return;
      }
    } catch (e) {
      // Stats endpoint failed, will calculate from farmers
    }

    // Fallback: Fetch all farmers to calculate accurate stats
    try {
      final allFarmersResponse = await AdminFarmerService.getFarmers(
        page: 0,
        size: 10000, // Large size to get all farmers
        search: null,
        kycStatus: null,
        subscriptionStatus: null,
      );

      if (allFarmersResponse.farmers.isNotEmpty) {
        final calculatedStats = _calculateStatsFromFarmers(allFarmersResponse.farmers);
        setState(() {
          _stats = calculatedStats;
        });
      }
    } catch (e) {
      // If that fails too, calculate from current page as last resort
      if (_farmers.isNotEmpty) {
        _stats = _calculateStatsFromFarmers(_farmers);
      }
    }
  }

  DashboardStats _calculateStatsFromFarmers(List<FarmerSummary> farmers) {
    int pendingKyc = 0;
    int verifiedKyc = 0;
    int activeSubscriptions = 0;
    int pendingSubscriptions = 0;
    int totalFarms = 0;
    int verifiedFarms = 0;

    for (var farmer in farmers) {
      // Count KYC status
      final kycStatus = farmer.kycStatus.toUpperCase();
      if (kycStatus == 'PENDING' || kycStatus == 'PARTIAL') {
        pendingKyc++;
      } else if (kycStatus == 'VERIFIED') {
        verifiedKyc++;
      }

      // Count subscription status
      final subStatus = farmer.subscriptionStatus.toUpperCase();
      if (subStatus == 'ACTIVE') {
        activeSubscriptions++;
      } else if (subStatus == 'PENDING') {
        pendingSubscriptions++;
      }

      // Count farms
      totalFarms += farmer.farmCount;
      verifiedFarms += farmer.verifiedFarmCount;
    }

    return DashboardStats(
      totalFarmers: farmers.length,
      pendingKyc: pendingKyc,
      verifiedKyc: verifiedKyc,
      activeSubscriptions: activeSubscriptions,
      pendingSubscriptions: pendingSubscriptions,
      totalFarms: totalFarms,
      verifiedFarms: verifiedFarms,
    );
  }



  void _onKycFilterChanged(String? value) {
    setState(() {
      _kycFilter = value;
      _currentPage = 0;
    });
    _applyFiltersAndReload();
  }

  void _onSubscriptionFilterChanged(String? value) {
    setState(() {
      _subscriptionFilter = value;
      _currentPage = 0;
    });
    _applyFiltersAndReload();
  }

  void _onFieldOfficerFilterChanged(String? value) {
    setState(() {
      _fieldOfficerFilter = value;
      _currentPage = 0;
    });
    _applyFiltersAndReload();
  }

  void _onSortChanged(SortColumn? column) {
    setState(() {
      if (_sortColumn == column) {
        // Toggle direction if same column
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _sortColumn = column;
        _sortDirection = SortDirection.ascending;
      }
    });
    _applyFiltersAndReload();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _applyFiltersAndReload();
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
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
              const SizedBox(height: 28),
          
          // Stats Cards
          _buildStatsSection(),
              const SizedBox(height: 28),
              
              // Advanced Filters Panel
              if (_showAdvancedFilters) ...[
                _buildAdvancedFiltersPanel(),
                const SizedBox(height: 20),
              ],
              
              // Farmers Table with integrated filters
              _buildFarmersTable(),
          
          // Pagination
              if (_totalPages > 1) ...[
                const SizedBox(height: 20),
          _buildPagination(),
              ],
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farmer Management',
          style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and monitor all registered farmers',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Filters Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                  if (_showAdvancedFilters) {
                    _loadAllFarmers(); // Load all farmers when opening filters
                  }
                },
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: _showAdvancedFilters 
                      ? AppColors.brandGreen 
                      : Colors.grey.shade700,
                ),
                label: Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _showAdvancedFilters 
                        ? AppColors.brandGreen 
                        : Colors.grey.shade700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _showAdvancedFilters 
                          ? AppColors.brandGreen 
                          : Colors.grey.shade300,
                      width: _showAdvancedFilters ? 1.5 : 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Export Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
          onPressed: () {
            // Export functionality
            ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Export feature coming soon'),
                      backgroundColor: AppColors.brandGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  'Export',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
          ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1200;
        final isMedium = constraints.maxWidth > 800;
        
        if (isWide) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
                  title: 'Total Farmers',
            value: stats?.totalFarmers.toString() ?? '0',
            subtitle: '+12% this Month',
            icon: Icons.people,
            color: AppColors.brandGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
                  title: 'KYC Pending',
            value: stats?.pendingKyc.toString() ?? '0',
            subtitle: '+8% this Month',
            icon: Icons.pending_actions,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
                  title: 'KYC Verified',
            value: stats?.verifiedKyc.toString() ?? '0',
            subtitle: '+8% this Month',
            icon: Icons.verified_user,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
                  title: 'Active Subscription',
            value: stats?.activeSubscriptions.toString() ?? '0',
            subtitle: '+6% this Month',
            icon: Icons.card_membership,
            color: AppColors.info,
          ),
        ),
      ],
          );
        } else if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Farmers',
                      value: stats?.totalFarmers.toString() ?? '0',
                      subtitle: '+12% this Month',
                      icon: Icons.people,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'KYC Pending',
                      value: stats?.pendingKyc.toString() ?? '0',
                      subtitle: '+8% this Month',
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'KYC Verified',
                      value: stats?.verifiedKyc.toString() ?? '0',
                      subtitle: '+8% this Month',
                      icon: Icons.verified_user,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Active Subscription',
                      value: stats?.activeSubscriptions.toString() ?? '0',
                      subtitle: '+6% this Month',
                      icon: Icons.card_membership,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              StatCard(
                title: 'Total Farmers',
                value: stats?.totalFarmers.toString() ?? '0',
                subtitle: '+12% this Month',
                icon: Icons.people,
                color: AppColors.brandGreen,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'KYC Pending',
                value: stats?.pendingKyc.toString() ?? '0',
                subtitle: '+8% this Month',
                icon: Icons.pending_actions,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'KYC Verified',
                value: stats?.verifiedKyc.toString() ?? '0',
                subtitle: '+8% this Month',
                icon: Icons.verified_user,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'Active Subscription',
                value: stats?.activeSubscriptions.toString() ?? '0',
                subtitle: '+6% this Month',
                icon: Icons.card_membership,
                color: AppColors.info,
              ),
            ],
          );
        }
      },
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedPincodes.isNotEmpty) count++;
    if (_selectedVillages.isNotEmpty) count++;
    if (_selectedDistricts.isNotEmpty) count++;
    if (_selectedStates.isNotEmpty) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    // Legacy filters
    if (_pincodeFilter != null && _pincodeFilter!.isNotEmpty) count++;
    return count;
  }

  void _showDropdown({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    required GlobalKey key,
  }) {
    _closeDropdown();
    
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _openDropdownLabel = label;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        label: label,
        options: options,
        selectedValues: selectedValues,
        onChanged: onChanged,
        onClose: _closeDropdown,
        position: position,
        size: size,
      ),
    );

    Overlay.of(context).insert(_dropdownOverlay!);
  }

  Widget _buildMultiSelectFilter({
    required String label,
    required IconData icon,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    double? width,
  }) {
    if (!_filterKeys.containsKey(label)) {
      _filterKeys[label] = GlobalKey();
    }
    final key = _filterKeys[label]!;

    return GestureDetector(
      onTap: () {
        if (_openDropdownLabel == label) {
          _closeDropdown();
        } else {
          _showDropdown(
            label: label,
            options: options,
            selectedValues: selectedValues,
            onChanged: onChanged,
            key: key,
          );
        }
      },
      child: Container(
        key: key,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedValues.isEmpty
                        ? 'All $label'
                        : selectedValues.length == 1
                            ? selectedValues.first
                            : '${selectedValues.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: selectedValues.isEmpty
                          ? Colors.grey.shade400
                          : AppColors.textPrimary,
                      fontWeight: selectedValues.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selectedValues.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  selectedValues.length.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Filters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _clearAdvancedFilters,
                icon: Icon(Icons.clear_all_rounded, size: 18, color: Colors.grey.shade600),
                label: Text(
                  'Clear All',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // All filters in one row: State, District, Pincode, Village, Start Date, End Date
          Row(
            children: [
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'State',
                  icon: Icons.map_outlined,
                  options: _getUniqueStates(),
                  selectedValues: _selectedStates,
                  onChanged: (values) {
                    setState(() {
                      _selectedStates = values;
                      // Clear districts, villages, and pincodes if state changes
                      if (values.isNotEmpty) {
                        final districtsInStates = _allFarmers
                            .where((f) => values.contains(f.state) && f.district != null)
                            .map((f) => f.district!)
                            .toSet()
                            .toList();
                        _selectedDistricts = _selectedDistricts
                            .where((d) => districtsInStates.contains(d))
                            .toList();
                        
                        final villagesInStates = _allFarmers
                            .where((f) => values.contains(f.state) && f.village != null)
                            .map((f) => f.village!)
                            .toSet()
                            .toList();
                        _selectedVillages = _selectedVillages
                            .where((v) => villagesInStates.contains(v))
                            .toList();
                        
                        final pincodesInStates = _allFarmers
                            .where((f) => values.contains(f.state) && f.pincode != null)
                            .map((f) => f.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes = _selectedPincodes
                            .where((p) => pincodesInStates.contains(p))
                            .toList();
                      } else {
                        // If no states selected, clear all dependent filters
                        _selectedDistricts = [];
                        _selectedVillages = [];
                        _selectedPincodes = [];
                      }
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'District',
                  icon: Icons.location_city_outlined,
                  options: _selectedStates.isNotEmpty
                      ? _getUniqueDistricts()
                          .where((d) => _allFarmers
                              .where((f) => _selectedStates.contains(f.state))
                              .any((f) => f.district == d))
                          .toList()
                      : _getUniqueDistricts(),
                  selectedValues: _selectedDistricts,
                  onChanged: (values) {
                    setState(() {
                      _selectedDistricts = values;
                      // Clear villages and pincodes that don't belong to selected districts
                      if (values.isNotEmpty) {
                        final villagesInDistricts = _allFarmers
                            .where((f) => values.contains(f.district) && f.village != null)
                            .map((f) => f.village!)
                            .toSet()
                            .toList();
                        _selectedVillages = _selectedVillages
                            .where((v) => villagesInDistricts.contains(v))
                            .toList();
                        
                        final pincodesInDistricts = _allFarmers
                            .where((f) => values.contains(f.district) && f.pincode != null)
                            .map((f) => f.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes = _selectedPincodes
                            .where((p) => pincodesInDistricts.contains(p))
                            .toList();
                      } else {
                        // If no districts selected, filter villages and pincodes by states only
                        if (_selectedStates.isNotEmpty) {
                          final villagesInStates = _allFarmers
                              .where((f) => _selectedStates.contains(f.state) && f.village != null)
                              .map((f) => f.village!)
                              .toSet()
                              .toList();
                          _selectedVillages = _selectedVillages
                              .where((v) => villagesInStates.contains(v))
                              .toList();
                          
                          final pincodesInStates = _allFarmers
                              .where((f) => _selectedStates.contains(f.state) && f.pincode != null)
                              .map((f) => f.pincode!)
                              .toSet()
                              .toList();
                          _selectedPincodes = _selectedPincodes
                              .where((p) => pincodesInStates.contains(p))
                              .toList();
                        } else {
                          // If no states and no districts, clear villages and pincodes
                          _selectedVillages = [];
                          _selectedPincodes = [];
                        }
                      }
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'Pincode',
                  icon: Icons.location_on_outlined,
                  options: _getFilteredPincodes(),
                  selectedValues: _selectedPincodes,
                  onChanged: (values) {
                    setState(() {
                      _selectedPincodes = values;
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'Village',
                  icon: Icons.home_outlined,
                  options: _getFilteredVillages(),
                  selectedValues: _selectedVillages,
                  onChanged: (values) {
                    setState(() {
                      _selectedVillages = values;
                      // Clear pincodes that don't belong to selected villages
                      if (values.isNotEmpty) {
                        List<FarmerSummary> filteredFarmers = _allFarmers;
                        if (_selectedStates.isNotEmpty) {
                          filteredFarmers = filteredFarmers
                              .where((f) => _selectedStates.contains(f.state))
                              .toList();
                        }
                        if (_selectedDistricts.isNotEmpty) {
                          filteredFarmers = filteredFarmers
                              .where((f) => _selectedDistricts.contains(f.district))
                              .toList();
                        }
                        final pincodesInVillages = filteredFarmers
                            .where((f) => values.contains(f.village) && f.pincode != null)
                            .map((f) => f.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes = _selectedPincodes
                            .where((p) => pincodesInVillages.contains(p))
                            .toList();
                      }
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                        _currentPage = 0;
                      });
                      _applyFiltersAndReload();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? 'Start Date'
                                : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _startDate == null
                                  ? Colors.grey.shade400
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_startDate != null)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, size: 16, color: Colors.grey.shade400),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _currentPage = 0;
                              });
                              _applyFiltersAndReload();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                        _currentPage = 0;
                      });
                      _applyFiltersAndReload();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate == null
                                ? 'End Date'
                                : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _endDate == null
                                  ? Colors.grey.shade400
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_endDate != null)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, size: 16, color: Colors.grey.shade400),
                            onPressed: () {
                              setState(() {
                                _endDate = null;
                                _currentPage = 0;
                              });
                              _applyFiltersAndReload();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFiltersAndReload() {
    // Apply filters to all farmers and then paginate
    List<FarmerSummary> filtered = List.from(_allFarmers);

    // Apply column-specific search filters
    if (_userIdSearch != null && _userIdSearch!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.userId.toString().contains(_userIdSearch!);
      }).toList();
    }

    if (_fullNameSearch != null && _fullNameSearch!.isNotEmpty) {
      final lowerQuery = _fullNameSearch!.toLowerCase();
      filtered = filtered.where((farmer) {
        return farmer.fullName.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_usernameSearch != null && _usernameSearch!.isNotEmpty) {
      final lowerQuery = _usernameSearch!.toLowerCase();
      filtered = filtered.where((farmer) {
        return farmer.username.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_phoneSearch != null && _phoneSearch!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.phoneNumber.contains(_phoneSearch!);
      }).toList();
    }

    if (_locationSearch != null && _locationSearch!.isNotEmpty) {
      final lowerQuery = _locationSearch!.toLowerCase();
      filtered = filtered.where((farmer) {
        return (farmer.village ?? '').toLowerCase().contains(lowerQuery) ||
            (farmer.district ?? '').toLowerCase().contains(lowerQuery) ||
            (farmer.state ?? '').toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply Pincode search filter (column-specific)
    if (_pincodeSearch != null && _pincodeSearch!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return (farmer.pincode ?? '').contains(_pincodeSearch!);
      }).toList();
    }

    // Apply multi-select State filter
    if (_selectedStates.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.state != null && _selectedStates.contains(farmer.state);
      }).toList();
    }

    // Apply multi-select District filter
    if (_selectedDistricts.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.district != null && _selectedDistricts.contains(farmer.district);
      }).toList();
    }

    // Apply multi-select Village filter
    if (_selectedVillages.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.village != null && _selectedVillages.contains(farmer.village);
      }).toList();
    }

    // Apply multi-select Pincode filter
    if (_selectedPincodes.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.pincode != null && _selectedPincodes.contains(farmer.pincode);
      }).toList();
    }

    // Apply KYC filter
    if (_kycFilter != null && _kycFilter!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.kycStatus.toUpperCase() == _kycFilter!.toUpperCase();
      }).toList();
    }

    // Apply Subscription filter
    if (_subscriptionFilter != null && _subscriptionFilter!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        return farmer.subscriptionStatus.toUpperCase() == _subscriptionFilter!.toUpperCase();
      }).toList();
    }

    // Pincode filter is applied via backend API in _loadFarmers()
    // No need to filter here as _allFarmers already contains pincode-filtered results

    // Apply Field Officer filter
    if (_fieldOfficerFilter != null && _fieldOfficerFilter!.isNotEmpty) {
      filtered = filtered.where((farmer) {
        final assignedCount = farmer.assignedFarmsCount ?? 0;
        final totalCount = farmer.totalFarmsCount ?? farmer.farmCount;
        final hasAllAssigned = farmer.hasAllFarmsAssigned ?? false;
        final hasPartial = farmer.hasPartialAssignment ?? false;

        switch (_fieldOfficerFilter) {
          case 'ASSIGN':
            // No farms assigned - Show "Assign" button
            return assignedCount == 0;
          case 'VIEW':
            // All farms assigned - Show "View" button
            return hasAllAssigned && assignedCount > 0;
          case 'MANAGE':
            // Some farms assigned (partial) - Show "Manage" button
            return hasPartial && !hasAllAssigned && assignedCount > 0;
          default:
            return true;
        }
      }).toList();
    }

    // Apply Date range filter
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((farmer) {
        final registeredDate = farmer.registeredAt;
        if (registeredDate == null) return false;
        if (_startDate != null && registeredDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && registeredDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn!) {
          case SortColumn.userId:
            comparison = a.userId.compareTo(b.userId);
            break;
          case SortColumn.fullName:
            comparison = a.fullName.compareTo(b.fullName);
            break;
          case SortColumn.username:
            comparison = a.username.compareTo(b.username);
            break;
          case SortColumn.phoneNumber:
            comparison = a.phoneNumber.compareTo(b.phoneNumber);
            break;
          case SortColumn.location:
            final aLocation = '${a.village ?? ''}, ${a.district ?? ''}';
            final bLocation = '${b.village ?? ''}, ${b.district ?? ''}';
            comparison = aLocation.compareTo(bLocation);
            break;
          case SortColumn.kycStatus:
            comparison = a.kycStatus.compareTo(b.kycStatus);
            break;
          case SortColumn.subscriptionStatus:
            comparison = a.subscriptionStatus.compareTo(b.subscriptionStatus);
            break;
          case SortColumn.farmCount:
            comparison = a.farmCount.compareTo(b.farmCount);
            break;
          case SortColumn.registeredAt:
            final aDate = a.registeredAt ?? DateTime(1970);
            final bDate = b.registeredAt ?? DateTime(1970);
            comparison = aDate.compareTo(bDate);
            break;
        }
        return _sortDirection == SortDirection.ascending ? comparison : -comparison;
      });
    }

    // Calculate pagination
    final totalFiltered = filtered.length;
    final totalPages = (totalFiltered / _pageSize).ceil();
    
    // Get current page data
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalFiltered);
    final pageData = filtered.sublist(
      startIndex.clamp(0, totalFiltered),
      endIndex,
    );

    setState(() {
      _filteredFarmers = pageData;
      _totalPages = totalPages;
      _totalElements = totalFiltered;
      _farmers = pageData; // For compatibility
    });
  }

  void _clearAdvancedFilters() {
    // Clear all search controllers
    _userIdSearchController.clear();
    _fullNameSearchController.clear();
    _usernameSearchController.clear();
    _phoneSearchController.clear();
    _locationSearchController.clear();
    _pincodeSearchController.clear();
    _pincodeController.clear();
    
    setState(() {
      // Clear all search queries
      _userIdSearch = null;
      _fullNameSearch = null;
      _usernameSearch = null;
      _phoneSearch = null;
      _locationSearch = null;
      _pincodeSearch = null;
      
      // Clear table filters
      _kycFilter = null;
      _subscriptionFilter = null;
      _fieldOfficerFilter = null;
      
      // Clear advanced filters (multi-select)
      _selectedPincodes = [];
      _selectedVillages = [];
      _selectedDistricts = [];
      _selectedStates = [];
      
      // Clear legacy advanced filters
      _pincodeFilter = null;
      _startDate = null;
      _endDate = null;
      _currentPage = 0;
      // Clear all farmers to force reload from backend without filters
      _allFarmers = [];
    });
    _loadFarmers(forceReload: true); // Force reload from backend without filters
  }

  Widget _buildFarmersTable() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
            Text(
                  'Error Loading Data',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
              onPressed: _loadFarmers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Always show table structure, even when empty
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildCustomTable(
                constraints.maxWidth > 0 ? constraints.maxWidth : 1200,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomTable(double minWidth) {
    const double rowHeight = 72.0;
    const double headerHeight = 56.0;
    const double filterHeight = 52.0;
    
    // Column widths - optimized for better layout
    // Order: User ID, Username, Full Name, Phone No, Location, Pincode, Farms, KYC, Subscription, Field Officer
    const double userIdWidth = 110.0;
    const double usernameWidth = 150.0;
    const double fullNameWidth = 200.0;
    const double phoneWidth = 140.0;
    const double locationWidth = 280.0;
    const double pincodeWidth = 120.0;
    const double farmsWidth = 100.0;
    const double kycWidth = 130.0;
    const double subscriptionWidth = 150.0;
    const double fieldOfficerWidth = 160.0;
    
    final totalWidth = userIdWidth +
        usernameWidth +
        fullNameWidth +
        phoneWidth +
        locationWidth +
        pincodeWidth +
        farmsWidth +
        kycWidth +
        subscriptionWidth +
        fieldOfficerWidth;
    
    // Effective min width (either table content or available width)
    final tableMinWidth =
        totalWidth > minWidth ? totalWidth : minWidth;

    // Calculate minimum height for 5 rows (page size)
    final minDataHeight = _pageSize * rowHeight;
    final totalMinHeight = headerHeight + filterHeight + minDataHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: tableMinWidth,
        minHeight: totalMinHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('User ID', userIdWidth, SortColumn.userId, true),
                _buildHeaderDivider(),
                _buildHeaderCell('Username', usernameWidth, SortColumn.username, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Full Name', fullNameWidth, SortColumn.fullName, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Phone No', phoneWidth, SortColumn.phoneNumber, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Location', locationWidth, SortColumn.location, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Pincode', pincodeWidth, null, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Farms', farmsWidth, SortColumn.farmCount, false),
                _buildHeaderDivider(),
                _buildHeaderCell('KYC', kycWidth, SortColumn.kycStatus, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Subscription', subscriptionWidth, SortColumn.subscriptionStatus, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Field Officer', fieldOfficerWidth, null, true),
              ],
            ),
          ),
          // Filter Row
          Container(
            height: filterHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildFilterCell(userIdWidth, 'userId'),
                _buildDivider(),
                _buildFilterCell(usernameWidth, 'username'),
                _buildDivider(),
                _buildFilterCell(fullNameWidth, 'fullName'),
                _buildDivider(),
                _buildFilterCell(phoneWidth, 'phone'),
                _buildDivider(),
                _buildFilterCell(locationWidth, 'location'),
                _buildDivider(),
                _buildFilterCell(pincodeWidth, 'pincode'),
                _buildDivider(),
                _buildFilterCell(farmsWidth, null),
                _buildDivider(),
                _buildFilterCell(kycWidth, 'kyc'),
                _buildDivider(),
                _buildFilterCell(subscriptionWidth, 'subscription'),
                _buildDivider(),
                _buildFilterCell(fieldOfficerWidth, 'fieldOfficer'),
              ],
            ),
          ),
          // Data Rows Container with minimum height
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minDataHeight),
            child: _filteredFarmers.isEmpty
                ? _buildEmptyState(tableMinWidth, minDataHeight)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._filteredFarmers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final farmer = entry.value;
                        return _buildCustomFarmerRow(
                          farmer,
                          rowHeight,
                          userIdWidth,
                          usernameWidth,
                          fullNameWidth,
                          phoneWidth,
                          locationWidth,
                          pincodeWidth,
                          farmsWidth,
                          kycWidth,
                          subscriptionWidth,
                          fieldOfficerWidth,
                          index == _filteredFarmers.length - 1, // Last row
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildHeaderCell(String label, double width, SortColumn? sortColumn, bool isFirstOrLast) {
    final isSorted = _sortColumn == sortColumn;
    return InkWell(
      onTap: sortColumn != null ? () => _onSortChanged(sortColumn) : null,
      hoverColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: isFirstOrLast ? 16 : 12,
          vertical: 16,
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
                  fontSize: 13,
              color: Colors.white,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sortColumn != null) ...[
              const SizedBox(width: 6),
              if (isSorted)
                Icon(
                  _sortDirection == SortDirection.ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: Colors.white,
                )
              else
                Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCell(double width, String? filterType) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.centerLeft,
      child: filterType == 'kyc'
          ? SizedBox(
              width: width - 24,
            child: DropdownButtonFormField<String>(
              value: _kycFilter,
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                DropdownMenuItem(value: 'VERIFIED', child: Text('Verified')),
              ],
              onChanged: _onKycFilterChanged,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
              ),
            )
          : filterType == 'subscription'
              ? SizedBox(
                  width: width - 24,
            child: DropdownButtonFormField<String>(
              value: _subscriptionFilter,
              decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'EXPIRED', child: Text('Expired')),
              ],
              onChanged: _onSubscriptionFilterChanged,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
                  ),
                )
              : filterType == 'userId'
                  ? _buildSearchInput(width, _userIdSearchController, 'Search ID...', (value) {
                      _userIdSearchDebounce?.cancel();
                      _userIdSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                        setState(() {
                          _userIdSearch = value.isEmpty ? null : value;
                          _currentPage = 0;
                        });
                        _applyFiltersAndReload();
                      });
                    })
                  : filterType == 'fullName'
                      ? _buildSearchInput(width, _fullNameSearchController, 'Search name...', (value) {
                          _fullNameSearchDebounce?.cancel();
                          _fullNameSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                            setState(() {
                              _fullNameSearch = value.isEmpty ? null : value;
                              _currentPage = 0;
                            });
                            _applyFiltersAndReload();
                          });
                        })
                      : filterType == 'username'
                          ? _buildSearchInput(width, _usernameSearchController, 'Search username...', (value) {
                              _usernameSearchDebounce?.cancel();
                              _usernameSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                                setState(() {
                                  _usernameSearch = value.isEmpty ? null : value;
                                  _currentPage = 0;
                                });
                                _applyFiltersAndReload();
                              });
                            })
                          : filterType == 'phone'
                              ? _buildSearchInput(width, _phoneSearchController, 'Search phone...', (value) {
                                  _phoneSearchDebounce?.cancel();
                                  _phoneSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                                    setState(() {
                                      _phoneSearch = value.isEmpty ? null : value;
                                      _currentPage = 0;
                                    });
                                    _applyFiltersAndReload();
                                  });
                                })
                              : filterType == 'location'
                                  ? _buildSearchInput(width, _locationSearchController, 'Search location...', (value) {
                                      _locationSearchDebounce?.cancel();
                                      _locationSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                                        setState(() {
                                          _locationSearch = value.isEmpty ? null : value;
                                          _currentPage = 0;
                                        });
                                        _applyFiltersAndReload();
                                      });
                                    })
                                  : filterType == 'pincode'
                                      ? _buildSearchInput(width, _pincodeSearchController, 'Search pincode...', (value) {
                                          _pincodeSearchDebounce?.cancel();
                                          _pincodeSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                                            setState(() {
                                              _pincodeSearch = value.isEmpty ? null : value;
                                              _currentPage = 0;
                                            });
                                            _applyFiltersAndReload();
                                          });
                                        })
                                      : filterType == 'fieldOfficer'
                                      ? SizedBox(
                                          width: width - 24,
                                          child: DropdownButtonFormField<String>(
                                            value: _fieldOfficerFilter,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
                                            items: const [
                                              DropdownMenuItem(value: null, child: Text('All')),
                                              DropdownMenuItem(value: 'ASSIGN', child: Text('Assign')),
                                              DropdownMenuItem(value: 'VIEW', child: Text('View')),
                                              DropdownMenuItem(value: 'MANAGE', child: Text('Manage')),
                                            ],
                                            onChanged: _onFieldOfficerFilterChanged,
                                            icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchInput(double width, TextEditingController controller, String hint, Function(String) onChanged) {
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return SizedBox(
          width: width - 24,
          child: TextField(
            controller: controller,
            onChanged: (value) {
              setStateLocal(() {});
              onChanged(value);
            },
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 14, color: Colors.grey.shade400),
                      onPressed: () {
                        controller.clear();
                        setStateLocal(() {});
                        onChanged('');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double tableWidth, double minHeight) {
    return Container(
      width: tableWidth,
      height: minHeight,
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
            Text(
              'No farmers found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _clearAdvancedFilters();
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: Text(
                  'Clear All Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }

  Widget _buildCustomFarmerRow(
    FarmerSummary farmer,
    double height,
    double userIdWidth,
    double usernameWidth,
    double fullNameWidth,
    double phoneWidth,
    double locationWidth,
    double pincodeWidth,
    double farmsWidth,
    double kycWidth,
    double subscriptionWidth,
    double fieldOfficerWidth,
    bool isLastRow,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: height,
      decoration: BoxDecoration(
        color: Colors.white,
          border: Border(
            bottom: isLastRow 
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewFarmerDetail(farmer),
            hoverColor: AppColors.brandGreen.withOpacity(0.05),
            child: Row(
        children: [
          // User ID
          _buildDataCell(userIdWidth, Text(
            farmer.userId.toString(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ), true),
          _buildDivider(),
          // Username
          _buildDataCell(usernameWidth, Text(
            farmer.username,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ), false),
          _buildDivider(),
          // Full Name with avatar
          _buildDataCell(fullNameWidth, Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    farmer.fullName.isNotEmpty
                        ? farmer.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: AppColors.brandGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  farmer.fullName.isEmpty ? 'Not Set' : farmer.fullName,
                  style: GoogleFonts.poppins(
              fontSize: 13,
                    fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ), false),
          _buildDivider(),
          // Phone No
          _buildDataCell(phoneWidth, Text(
            farmer.phoneNumber,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ), false),
          _buildDivider(),
          // Location
          _buildDataCell(locationWidth, SizedBox(
            width: locationWidth - 24,
            child: Text(
              '${farmer.village ?? '-'}, ${farmer.district ?? '-'}',
              style: GoogleFonts.poppins(
              fontSize: 13,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ), false),
          _buildDivider(),
          // Pincode
          _buildDataCell(pincodeWidth, Text(
            farmer.pincode ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ), false),
          _buildDivider(),
          // Farms
          _buildDataCell(farmsWidth, Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '${farmer.verifiedFarmCount}/${farmer.farmCount}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ), false),
          _buildDivider(),
          // KYC Status
          _buildDataCell(kycWidth, _buildStatusChip(farmer.kycStatus, _getKycStatusColor(farmer.kycStatus)), false),
          _buildDivider(),
          // Subscription Status
          _buildDataCell(subscriptionWidth, _buildStatusChip(farmer.subscriptionStatus, _getSubStatusColor(farmer.subscriptionStatus)), false),
          _buildDivider(),
          // Field Officer
          _buildDataCell(fieldOfficerWidth, _buildFieldOfficerCell(farmer), true),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(double width, Widget child, bool isFirstOrLast) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: isFirstOrLast ? 16 : 12,
        vertical: 16,
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  DataRow _buildFarmerRow(FarmerSummary farmer) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            farmer.userId.toString(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                child: Text(
                    farmer.fullName.isNotEmpty
                        ? farmer.fullName[0].toUpperCase()
                        : '?',
                  style: GoogleFonts.poppins(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                      fontSize: 14,
                  ),
                ),
              ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  farmer.fullName.isEmpty ? 'Not Set' : farmer.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            farmer.username,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            farmer.phoneNumber,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              '${farmer.village ?? '-'}, ${farmer.district ?? '-'}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_buildStatusChip(farmer.kycStatus, _getKycStatusColor(farmer.kycStatus))),
        DataCell(_buildStatusChip(farmer.subscriptionStatus, _getSubStatusColor(farmer.subscriptionStatus))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '${farmer.verifiedFarmCount}/${farmer.farmCount}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        DataCell(
          _buildFieldOfficerCell(farmer),
        ),
        DataCell(
          Container(
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.visibility_rounded,
                color: AppColors.brandGreen,
                size: 20,
              ),
                onPressed: () => _viewFarmerDetail(farmer),
                tooltip: 'View Details',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.toLowerCase().replaceAll('_', ' '),
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
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

  Widget _buildFieldOfficerCell(FarmerSummary farmer) {
    // Determine button type based on assignment status
    final assignedCount = farmer.assignedFarmsCount ?? 0;
    final totalCount = farmer.totalFarmsCount ?? farmer.farmCount;
    final hasAllAssigned = farmer.hasAllFarmsAssigned ?? false;
    final hasPartial = farmer.hasPartialAssignment ?? false;

    // If no farms exist, show "Assign" button
    if (totalCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brandGreen.withOpacity(0.3)),
        ),
        child: InkWell(
          onTap: () => _assignFieldOfficer(farmer),
          child: Text(
            'Assign',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGreen,
            ),
          ),
        ),
      );
    }

    String buttonLabel;
    Color buttonColor;

    if (assignedCount == 0) {
      // No farms assigned - Show "Assign" button (green)
      buttonLabel = 'Assign';
      buttonColor = AppColors.brandGreen;
    } else if (hasAllAssigned) {
      // All farms assigned - Show "View" button (blue)
      buttonLabel = 'View';
      buttonColor = AppColors.info;
    } else {
      // Some farms assigned - Show "Manage" button (orange)
      buttonLabel = 'Manage';
      buttonColor = AppColors.warning;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Assignment summary badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasAllAssigned
                ? AppColors.success.withOpacity(0.12)
                : hasPartial
                    ? AppColors.warning.withOpacity(0.12)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasAllAssigned
                  ? AppColors.success.withOpacity(0.3)
                  : hasPartial
                      ? AppColors.warning.withOpacity(0.3)
                      : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            '$assignedCount/$totalCount',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasAllAssigned
                  ? AppColors.success
                  : hasPartial
                      ? AppColors.warning
                      : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Action button (without icon)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonColor.withOpacity(0.3)),
          ),
          child: InkWell(
            onTap: () => _assignFieldOfficer(farmer),
            child: Text(
              buttonLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: buttonColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          
          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          Text(
                  'Showing ${(_currentPage * _pageSize) + 1}-${(_currentPage + 1) * _pageSize > _totalElements ? _totalElements : (_currentPage + 1) * _pageSize} of $_totalElements',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _currentPage > 0
                            ? AppColors.brandGreen.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: _currentPage > 0
                              ? AppColors.brandGreen
                              : Colors.grey.shade400,
                        ),
                        onPressed: _currentPage > 0
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        tooltip: 'Previous page',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
            'Page ${_currentPage + 1} of $_totalPages',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _currentPage < _totalPages - 1
                            ? AppColors.brandGreen.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _currentPage < _totalPages - 1
                              ? AppColors.brandGreen
                              : Colors.grey.shade400,
                        ),
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        tooltip: 'Next page',
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
          Text(
                  'Showing ${(_currentPage * _pageSize) + 1}-${(_currentPage + 1) * _pageSize > _totalElements ? _totalElements : (_currentPage + 1) * _pageSize} of $_totalElements',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _currentPage > 0
                            ? AppColors.brandGreen.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: _currentPage > 0
                              ? AppColors.brandGreen
                              : Colors.grey.shade400,
                        ),
                        onPressed: _currentPage > 0
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        tooltip: 'Previous page',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _currentPage < _totalPages - 1
                            ? AppColors.brandGreen.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _currentPage < _totalPages - 1
                              ? AppColors.brandGreen
                              : Colors.grey.shade400,
                        ),
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        tooltip: 'Next page',
                      ),
          ),
        ],
      ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _DropdownOverlay extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final VoidCallback onClose;
  final Offset position;
  final Size size;

  const _DropdownOverlay({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    required this.onClose,
    required this.position,
    required this.size,
  });

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay> {
  late TextEditingController _searchController;
  String searchQuery = '';
  List<String> tempSelected = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    tempSelected = List.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filteredOptions = widget.options
        .where(
          (o) => o.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Stack(
      children: [
        // Backdrop to close dropdown on tap outside
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // Dropdown content
        Positioned(
          left: widget.position.dx,
          top: widget.position.dy + widget.size.height + 4,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 400),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.label}',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.brandGreen,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelected.clear();
                            _searchController.clear();
                            searchQuery = '';
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelected = List.from(widget.options);
                            _searchController.clear();
                            searchQuery = '';
                          });
                        },
                        child: Text(
                          'Select All',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.brandGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  // Options list
                  if (filteredOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No options available',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredOptions.length,
                        itemBuilder: (context, index) {
                          final option = filteredOptions[index];
                          final isSelected = tempSelected.contains(option);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected.add(option);
                                } else {
                                  tempSelected.remove(option);
                                }
                              });
                            },
                            title: Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            activeColor: AppColors.brandGreen,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onChanged(tempSelected);
                        widget.onClose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

