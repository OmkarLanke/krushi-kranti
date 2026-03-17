import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/job_application_models.dart';
import '../services/job_application_service.dart';
import 'job_application_detail_screen.dart';

enum SortColumn {
  id,
  fullName,
  email,
  mobile,
  roleType,
  status,
  appliedAt,
}

enum SortDirection { ascending, descending }

class JobApplicationsListScreen extends StatefulWidget {
  const JobApplicationsListScreen({Key? key}) : super(key: key);

  @override
  State<JobApplicationsListScreen> createState() =>
      _JobApplicationsListScreenState();
}

class _JobApplicationsListScreenState extends State<JobApplicationsListScreen> {
  final JobApplicationService _service = JobApplicationService();

  List<JobApplication> _applications = [];
  List<JobApplication> _filteredApplications = [];
  List<JobApplication> _allApplications = []; // Source of truth
  JobApplicationStats? _stats;
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 50;

  // Search Controllers
  final _idSearchController = TextEditingController();
  final _nameSearchController = TextEditingController();
  final _emailSearchController = TextEditingController();
  final _mobileSearchController = TextEditingController();
  Timer? _idSearchDebounce;
  Timer? _nameSearchDebounce;
  Timer? _emailSearchDebounce;
  Timer? _mobileSearchDebounce;

  // Search Queries
  String? _idSearch;
  String? _nameSearch;
  String? _emailSearch;
  String? _mobileSearch;

  // Advanced Filters
  bool _showAdvancedFilters = false;
  List<String> _selectedRoles = [];
  List<String> _selectedStatuses = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Sort State
  SortColumn? _sortColumn;
  SortDirection _sortDirection = SortDirection.descending;

  // Scroll Controllers
  final _horizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();

  // Dropdown Overlays
  OverlayEntry? _dropdownOverlay;
  final Map<String, GlobalKey> _filterKeys = {};
  String? _openDropdownLabel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _closeDropdown();
    _idSearchController.dispose();
    _nameSearchController.dispose();
    _emailSearchController.dispose();
    _mobileSearchController.dispose();
    _idSearchDebounce?.cancel();
    _nameSearchDebounce?.cancel();
    _emailSearchDebounce?.cancel();
    _mobileSearchDebounce?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _closeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    _openDropdownLabel = null;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final applications = await _service.getAllApplications();
      // Calculate stats locally or fetch if API available.
      // The service has getStats(), let's use it.
      final stats = await _service.getStats();

      if (mounted) {
        setState(() {
          _allApplications = applications;
          _stats = stats;
          _isLoading = false;
        });
        _applyFiltersAndPagination();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<String> _getUniqueRoles() {
    final roles =
        _allApplications.map((a) => a.roleTypeDisplay).toSet().toList();
    roles.sort();
    return roles;
  }

  List<String> _getUniqueStatuses() {
    final statuses =
        _allApplications.map((a) => a.statusDisplay).toSet().toList();
    statuses.sort();
    return statuses;
  }

  void _applyFiltersAndPagination() {
    List<JobApplication> filtered = List.from(_allApplications);

    // 1. Column Searches
    if (_idSearch != null && _idSearch!.isNotEmpty) {
      filtered =
          filtered
              .where(
                (app) => app.id.toLowerCase().contains(_idSearch!.toLowerCase()),
              )
              .toList();
    }

    if (_nameSearch != null && _nameSearch!.isNotEmpty) {
      filtered =
          filtered
              .where(
                (app) => app.fullName.toLowerCase().contains(
                  _nameSearch!.toLowerCase(),
                ),
              )
              .toList();
    }

    if (_emailSearch != null && _emailSearch!.isNotEmpty) {
      filtered =
          filtered
              .where(
                (app) =>
                    app.email != null &&
                    app.email!.toLowerCase().contains(
                      _emailSearch!.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (_mobileSearch != null && _mobileSearch!.isNotEmpty) {
      filtered =
          filtered
              .where(
                (app) =>
                    app.mobileNumber != null &&
                    app.mobileNumber!.contains(_mobileSearch!),
              )
              .toList();
    }

    // 2. Advanced Filters
    if (_selectedRoles.isNotEmpty) {
      filtered =
          filtered
              .where((app) => _selectedRoles.contains(app.roleTypeDisplay))
              .toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      filtered =
          filtered
              .where((app) => _selectedStatuses.contains(app.statusDisplay))
              .toList();
    }

    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((app) {
        final applied = app.appliedAt;

        if (_startDate != null) {
          final startOfStartDate = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final startOfAppliedDate = DateTime(
            applied.year,
            applied.month,
            applied.day,
          );
          if (startOfAppliedDate.isBefore(startOfStartDate)) {
            return false;
          }
        }

        if (_endDate != null) {
          final endOfEndDate = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          if (applied.isAfter(endOfEndDate)) {
            return false;
          }
        }

        return true;
      }).toList();
    }

    // 3. Sorting
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int cmp = 0;
        switch (_sortColumn!) {
          case SortColumn.id:
            cmp = a.id.compareTo(b.id);
            break;
          case SortColumn.fullName:
            cmp = a.fullName.compareTo(b.fullName);
            break;
          case SortColumn.email:
            cmp = (a.email ?? '').compareTo(b.email ?? '');
            break;
          case SortColumn.mobile:
            cmp = (a.mobileNumber ?? '').compareTo(b.mobileNumber ?? '');
            break;
          case SortColumn.roleType:
            cmp = a.roleTypeDisplay.compareTo(b.roleTypeDisplay);
            break;
          case SortColumn.status:
            cmp = a.statusDisplay.compareTo(b.statusDisplay);
            break;
          case SortColumn.appliedAt:
            cmp = a.appliedAt.compareTo(b.appliedAt);
            break;
        }
        return _sortDirection == SortDirection.ascending ? cmp : -cmp;
      });
    } else {
      // Default sort: Latest applied first
      filtered.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    }

    // 4. Pagination
    _totalElements = filtered.length;
    _totalPages = (_totalElements / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;

    if (_currentPage >= _totalPages) {
      _currentPage = _totalPages - 1;
    }
    if (_currentPage < 0) _currentPage = 0;

    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _totalElements);

    if (_totalElements > 0) {
      _filteredApplications = filtered.sublist(startIndex, endIndex);
    } else {
      _filteredApplications = [];
    }
    _applications = _filteredApplications; // For compatibility if needed
  }

  void _clearAdvancedFilters() {
    _idSearchController.clear();
    _nameSearchController.clear();
    _emailSearchController.clear();
    _mobileSearchController.clear();

    setState(() {
      _idSearch = null;
      _nameSearch = null;
      _emailSearch = null;
      _mobileSearch = null;
      _selectedRoles = [];
      _selectedStatuses = [];
      _startDate = null;
      _endDate = null;
      _currentPage = 0;
    });
    _applyFiltersAndPagination();
  }

  void _onSortChanged(SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _sortColumn = column;
        _sortDirection = SortDirection.ascending;
      }
    });
    _applyFiltersAndPagination();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildStatsSection(),
                const SizedBox(height: 28),
                if (_showAdvancedFilters) ...[
                  _buildAdvancedFiltersPanel(),
                  const SizedBox(height: 20),
                ],
                _buildJobApplicationsTable(),
                if (_totalPages > 1) ...[
                  const SizedBox(height: 20),
                  _buildPagination(),
                ],
              ],
            ),
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
              'Job Applications',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and review job applications',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
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

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Applications',
                  value: stats?.total.toString() ?? '0',
                  icon: Icons.people_outline,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Screening',
                  value: stats?.screening.toString() ?? '0',
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Selected for HR',
                  value: stats?.selectedForHR.toString() ?? '0',
                  icon: Icons.event,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Selected',
                  value: stats?.selected.toString() ?? '0',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
            ],
          );
        } else {
          // Mobile/Tablet Grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Applications',
                      value: stats?.total.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Screening',
                      value: stats?.screening.toString() ?? '0',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Selected for HR',
                      value: stats?.selectedForHR.toString() ?? '0',
                      icon: Icons.event,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Selected',
                      value: stats?.selected.toString() ?? '0',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  // --- Advanced Filters ---
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
                icon: Icon(
                  Icons.clear_all_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
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
          Row(
            children: [
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'Role Type',
                  icon: Icons.work_outline,
                  options: _getUniqueRoles(),
                  selectedValues: _selectedRoles,
                  onChanged: (values) {
                    setState(() {
                      _selectedRoles = values;
                      _currentPage = 0;
                    });
                    _applyFiltersAndPagination();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'Status',
                  icon: Icons.filter_alt_outlined,
                  options: _getUniqueStatuses(),
                  selectedValues: _selectedStatuses,
                  onChanged: (values) {
                    setState(() {
                      _selectedStatuses = values;
                      _currentPage = 0;
                    });
                    _applyFiltersAndPagination();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildDateFilter(isStart: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateFilter(isStart: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter({required bool isStart}) {
    final date = isStart ? _startDate : _endDate;
    final label = isStart ? 'Start Date' : 'End Date';
    return InkWell(
      onTap: () async {
        final today = DateTime.now();
        final normalizedToday = DateTime(today.year, today.month, today.day);

        final newDate = await showDatePicker(
          context: context,
          initialDate: date ?? normalizedToday,
          firstDate: isStart ? DateTime(2024) : (_startDate ?? DateTime(2024)),
          lastDate: normalizedToday,
        );
        if (newDate != null) {
          setState(() {
            if (isStart) {
              _startDate = newDate;
            } else {
              _endDate = newDate;
            }
            _currentPage = 0;
          });
          _applyFiltersAndPagination();
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
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null
                    ? label
                    : '${date.day}/${date.month}/${date.year}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: date == null
                      ? Colors.grey.shade400
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (date != null)
              IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {
                  setState(() {
                    if (isStart) {
                      _startDate = null;
                    } else {
                      _endDate = null;
                    }
                    _currentPage = 0;
                  });
                  _applyFiltersAndPagination();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectFilter({
    required String label,
    required IconData icon,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
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
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showDropdown({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    required GlobalKey key,
  }) {
    _closeDropdown();

    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _openDropdownLabel = label;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 8,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: options.map((option) {
                    final isSelected = selectedValues.contains(option);
                    return InkWell(
                      onTap: () {
                        final newValues = List<String>.from(selectedValues);
                        if (isSelected) {
                          newValues.remove(option);
                        } else {
                          newValues.add(option);
                        }
                        onChanged(newValues);
                        // Don't close for multi-select
                        // We need to rebuild overlay to show checkmark
                        _showDropdown(
                          label: label,
                          options: options,
                          selectedValues: newValues,
                          onChanged: onChanged,
                          key: key,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.brandGreen
                                      : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: isSelected
                                    ? AppColors.brandGreen
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_dropdownOverlay!);
  }

  // --- Table Implementation ---
  Widget _buildJobApplicationsTable() {
    if (_isLoading) {
      return Container(
        height: 200,
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
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: Text('Error: $_error')),
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: double.infinity,
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
              return Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: _buildCustomTable(
                    constraints.maxWidth > 0 ? constraints.maxWidth : 1200,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTable(double availableWidth) {
    const double rowHeight = 72.0;
    const double headerHeight = 56.0;
    const double filterHeight = 52.0;

    // Based Column Widths
    const double baseIdWidth = 120.0;
    const double baseFullNameWidth = 200.0;
    const double baseEmailWidth = 200.0;
    const double baseMobileWidth = 140.0;
    const double baseRoleWidth = 150.0;
    const double baseStatusWidth = 150.0;
    const double baseDateWidth = 150.0;
    const double baseActionWidth = 90.0;

    const int numberOfDividers = 7;
    const double dividerWidth = 1.0;
    const double totalDividerWidth = numberOfDividers * dividerWidth;

    final totalBaseWidth =
        baseIdWidth +
        baseFullNameWidth +
        baseEmailWidth +
        baseMobileWidth +
        baseRoleWidth +
        baseStatusWidth +
        baseDateWidth +
        baseActionWidth +
        totalDividerWidth;

    double scaleFactor = 1.0;
    if (availableWidth > totalBaseWidth) {
      scaleFactor = availableWidth / totalBaseWidth;
    }

    // Apply scale
    final double idWidth = baseIdWidth * scaleFactor;
    final double fullNameWidth = baseFullNameWidth * scaleFactor;
    final double emailWidth = baseEmailWidth * scaleFactor;
    final double mobileWidth = baseMobileWidth * scaleFactor;
    final double roleWidth = baseRoleWidth * scaleFactor;
    final double statusWidth = baseStatusWidth * scaleFactor;
    final double dateWidth = baseDateWidth * scaleFactor;
    final double actionWidth = baseActionWidth * scaleFactor;

    final totalWidth =
        (totalBaseWidth - totalDividerWidth) * scaleFactor + totalDividerWidth;

    // Height calculation
    const double maxVisibleHeight = 800.0;
    final actualDataHeight = _filteredApplications.length * rowHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: totalWidth, maxWidth: totalWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
                 _buildHeaderCell(
                  'Application ID',
                  idWidth,
                  SortColumn.id,
                  true,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Full Name',
                  fullNameWidth,
                  SortColumn.fullName,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Email',
                  emailWidth,
                  SortColumn.email,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Mobile',
                  mobileWidth,
                  SortColumn.mobile,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Role Type',
                  roleWidth,
                  SortColumn.roleType,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Status',
                  statusWidth,
                  SortColumn.status,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell(
                  'Applied Date',
                  dateWidth,
                  SortColumn.appliedAt,
                  false,
                ),
                _buildHeaderDivider(),
                _buildHeaderCell('Actions', actionWidth, null, false),
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
                _buildFilterInput(
                  idWidth,
                  'Search ID...',
                  _idSearchController,
                  (val) {
                    _idSearchDebounce?.cancel();
                    _idSearchDebounce = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        setState(() {
                          _idSearch = val;
                          _currentPage = 0;
                        });
                        _applyFiltersAndPagination();
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildFilterInput(
                  fullNameWidth,
                  'Search Name...',
                  _nameSearchController,
                  (val) {
                    _nameSearchDebounce?.cancel();
                    _nameSearchDebounce = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        setState(() {
                          _nameSearch = val;
                          _currentPage = 0;
                        });
                        _applyFiltersAndPagination();
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildFilterInput(
                  emailWidth,
                  'Search Email...',
                  _emailSearchController,
                  (val) {
                    _emailSearchDebounce?.cancel();
                    _emailSearchDebounce = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        setState(() {
                          _emailSearch = val;
                          _currentPage = 0;
                        });
                        _applyFiltersAndPagination();
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildFilterInput(
                  mobileWidth,
                  'Search Mobile...',
                  _mobileSearchController,
                  (val) {
                    _mobileSearchDebounce?.cancel();
                    _mobileSearchDebounce = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        setState(() {
                          _mobileSearch = val;
                          _currentPage = 0;
                        });
                        _applyFiltersAndPagination();
                      },
                    );
                  },
                ),
                _buildDivider(),
                Container(width: roleWidth), // Covered by advanced filters
                _buildDivider(),
                Container(width: statusWidth), // Covered by advanced filters
                _buildDivider(),
                Container(width: dateWidth), // Covered by advanced filters
                _buildDivider(),
                Container(width: actionWidth),
              ],
            ),
          ),
          // Data
          SizedBox(
            height: maxVisibleHeight,
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                child: _filteredApplications.isEmpty
                    ? _buildEmptyState(totalWidth, actualDataHeight)
                    : Column(
                        children: _filteredApplications.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final app = entry.value;
                          return _buildRow(
                            app,
                            rowHeight,
                            idWidth,
                            fullNameWidth,
                            emailWidth,
                            mobileWidth,
                            roleWidth,
                            statusWidth,
                            dateWidth,
                            actionWidth,
                            index == _filteredApplications.length - 1,
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Container(
      width: width,
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No applications found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    JobApplication app,
    double height,
    double idWidth,
    double fullNameWidth,
    double emailWidth,
    double mobileWidth,
    double roleWidth,
    double statusWidth,
    double dateWidth,
    double actionWidth,
    bool isLast,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
      ),
      child: Row(
        children: [
          _buildCell(app.id, idWidth, textColor: Colors.grey.shade600),
          _buildDivider(),
          _buildCell(
            app.fullName,
            fullNameWidth,
            isBold: true,
          ),
          _buildDivider(),
          _buildCell(
            app.email ?? '-',
            emailWidth,
            textColor: Colors.grey.shade700,
          ),
          _buildDivider(),
          _buildCell(
            app.mobileNumber ?? '-',
            mobileWidth,
            textColor: Colors.grey.shade700,
          ),
          _buildDivider(),
          _buildCell(
            app.roleTypeDisplay,
            roleWidth,
            textColor: Colors.blue.shade700,
            isBold: true,
          ),
          _buildDivider(),
          Container(
            width: statusWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(app.currentStatus),
            ),
          ),
          _buildDivider(),
          _buildCell(
            DateFormat('dd MMM yyyy').format(app.appliedAt),
            dateWidth,
            textColor: Colors.grey.shade600,
          ),
          _buildDivider(),
          Container(
            width: actionWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center, // Center the button
            child: IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                color: AppColors.brandGreen,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobApplicationDetailScreen(
                      applicationId: app.id,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    String text,
    double width, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: textColor ?? AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'SELECTED':
        bg = AppColors.successBg;
        text = AppColors.success;
        break;
      case 'REJECTED':
        bg = AppColors.errorBg;
        text = AppColors.error;
        break;
      case 'SELECTED_FOR_HR':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      case 'SCREENING':
      default:
        bg = AppColors.warningBg;
        text = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Text(
        _service.getStatusDisplay(status),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    double width,
    SortColumn? sortCol,
    bool isFirst,
  ) {
    return InkWell(
      onTap: sortCol != null ? () => _onSortChanged(sortCol) : null,
      child: Container(
        width: width,
        padding: EdgeInsets.only(left: isFirst ? 16 : 12, right: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sortCol != null) ...[
              const SizedBox(width: 4),
              Icon(
                _sortColumn == sortCol
                    ? (_sortDirection == SortDirection.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterInput(
    double width,
    String hint,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.brandGreen),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
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

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Page ${_currentPage + 1} of $_totalPages',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _currentPage > 0
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _applyFiltersAndPagination();
                }
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _applyFiltersAndPagination();
                }
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
