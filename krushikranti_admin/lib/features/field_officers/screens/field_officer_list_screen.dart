import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/field_officer_models.dart';
import '../services/field_officer_service.dart';
import '../services/assignment_service.dart';
import 'add_field_officer_screen.dart';
import 'field_officer_assignments_dialog.dart';

class FieldOfficerListScreen extends StatefulWidget {
  const FieldOfficerListScreen({super.key});

  @override
  State<FieldOfficerListScreen> createState() => _FieldOfficerListScreenState();
}

class _FieldOfficerListScreenState extends State<FieldOfficerListScreen> {
  List<FieldOfficerSummary> _fieldOfficers = [];
  bool _isLoading = true;
  String? _error;
  
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 20;
  
  String? _searchQuery;
  bool? _isActiveFilter;
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFieldOfficers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldOfficers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await FieldOfficerService.getFieldOfficers(
        page: _currentPage,
        size: _pageSize,
        search: _searchQuery,
        isActive: _isActiveFilter,
      );

      // Debug: Print first field officer's pincode
      if (response.fieldOfficers.isNotEmpty) {
        print('DEBUG: First field officer pincode: ${response.fieldOfficers.first.pincode}');
      }
      
      // Debug: Print first field officer's data to verify pincode is received
      if (response.fieldOfficers.isNotEmpty) {
        final firstOfficer = response.fieldOfficers.first;
        print('DEBUG: First field officer - ID: ${firstOfficer.fieldOfficerId}, Pincode: ${firstOfficer.pincode}');
        print('DEBUG: All field officer data: ${firstOfficer.toString()}');
      }
      
      setState(() {
        _fieldOfficers = response.fieldOfficers;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
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
    _loadFieldOfficers();
  }

  void _onActiveFilterChanged(bool? value) {
    setState(() {
      _isActiveFilter = value;
      _currentPage = 0;
    });
    _loadFieldOfficers();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadFieldOfficers();
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFieldOfficerScreen()),
    );
    
    if (result == true) {
      _loadFieldOfficers();
    }
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
          
          // Search and Filters
          _buildFiltersSection(),
          const SizedBox(height: 16),
          
          // Field Officers Table
          Expanded(
            child: _buildFieldOfficersTable(),
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
          'Field Officer Management',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _navigateToAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Field Officer'),
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
                hintText: 'Search field officers...',
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
          
          // Active Status Filter
          Expanded(
            child: DropdownButtonFormField<bool?>(
              value: _isActiveFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: _onActiveFilterChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldOfficersTable() {
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
              onPressed: _loadFieldOfficers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_fieldOfficers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No field officers found',
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
              DataColumn(label: Text('Field Officer ID')),
              DataColumn(label: Text('Full Name')),
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Phone No')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Pincode')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Farm Assignment')),
            ],
            rows: _fieldOfficers.map((fo) => _buildFieldOfficerRow(fo)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildFieldOfficerRow(FieldOfficerSummary fieldOfficer) {
    return DataRow(
      cells: [
        DataCell(Text(fieldOfficer.fieldOfficerId.toString())),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                child: Text(
                  fieldOfficer.fullName.isNotEmpty ? fieldOfficer.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(fieldOfficer.fullName.isEmpty ? 'Not Set' : fieldOfficer.fullName),
            ],
          ),
        ),
        DataCell(Text(fieldOfficer.username)),
        DataCell(Text(fieldOfficer.phoneNumber)),
        DataCell(Text(fieldOfficer.email)),
        DataCell(Text(fieldOfficer.pincode ?? '-')),
        DataCell(Text('${fieldOfficer.village ?? '-'}, ${fieldOfficer.district ?? '-'}')),
        DataCell(_buildStatusChip(fieldOfficer.isActive)),
        DataCell(_buildFarmAssignmentCell(fieldOfficer)),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFarmAssignmentCell(FieldOfficerSummary fieldOfficer) {
    final count = fieldOfficer.assignedFarmsCount ?? 0;
    
    return InkWell(
      onTap: count > 0
          ? () => _showAssignmentsDialog(fieldOfficer)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: count > 0
              ? AppColors.brandGreen.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: count > 0
                ? AppColors.brandGreen
                : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.agriculture,
              size: 16,
              color: count > 0 ? AppColors.brandGreen : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: count > 0 ? AppColors.brandGreen : Colors.grey,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.brandGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAssignmentsDialog(FieldOfficerSummary fieldOfficer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FieldOfficerAssignmentsDialog(
        fieldOfficerId: fieldOfficer.fieldOfficerId,
        fieldOfficerName: fieldOfficer.fullName,
      ),
    );
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

