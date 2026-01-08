import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/field_officer_models.dart';
import '../services/field_officer_service.dart';
import '../services/assignment_service.dart';
import 'add_field_officer_screen.dart';
import 'field_officer_assignments_dialog.dart';

enum SortColumn {
  fieldOfficerId,
  fullName,
  username,
  phoneNumber,
  email,
  pincode,
  location,
  status,
  assignedFarmsCount,
  createdAt,
}

enum SortDirection {
  ascending,
  descending,
}

class FieldOfficerListScreen extends StatefulWidget {
  const FieldOfficerListScreen({super.key});

  @override
  State<FieldOfficerListScreen> createState() => _FieldOfficerListScreenState();
}

class _FieldOfficerListScreenState extends State<FieldOfficerListScreen> {
  List<FieldOfficerSummary> _fieldOfficers = [];
  List<FieldOfficerSummary> _filteredFieldOfficers = [];
  List<FieldOfficerSummary> _allFieldOfficers = []; // All field officers for filtering and dropdowns
  bool _isLoading = true;
  bool _isLoadingAllFieldOfficers = false;
  String? _error;
  
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 5; // Changed to 5 field officers per page
  
  String? _searchQuery;
  bool? _isActiveFilter;
  String? _pincodeFilter;
  
  // Column-specific search queries (for table header filters)
  String? _fieldOfficerIdSearch;
  String? _fullNameSearch;
  String? _usernameSearch;
  String? _phoneSearch;
  String? _emailSearch;
  String? _pincodeSearch;
  String? _locationSearch;
  
  // Advanced filters
  String? _stateFilter;
  String? _districtFilter;
  // New multi-select advanced filters
  List<String> _selectedStates = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedPincodes = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showAdvancedFilters = false;
  
  // Sort state
  SortColumn? _sortColumn;
  SortDirection _sortDirection = SortDirection.descending;
  
  final _searchController = TextEditingController();
  final _pincodeController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _pincodeDebounce;

  // Controllers & debouncers for column search inputs
  final _fieldOfficerIdSearchController = TextEditingController();
  final _fullNameSearchController = TextEditingController();
  final _usernameSearchController = TextEditingController();
  final _phoneSearchController = TextEditingController();
  final _emailSearchController = TextEditingController();
  final _pincodeSearchController = TextEditingController();
  final _locationSearchController = TextEditingController();
  Timer? _fieldOfficerIdSearchDebounce;
  Timer? _fullNameSearchDebounce;
  Timer? _usernameSearchDebounce;
  Timer? _phoneSearchDebounce;
  Timer? _emailSearchDebounce;
  Timer? _pincodeSearchDebounce;
  Timer? _locationSearchDebounce;

  @override
  void initState() {
    super.initState();
    _loadFieldOfficers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pincodeController.dispose();
    _searchDebounce?.cancel();
    _pincodeDebounce?.cancel();
    _fieldOfficerIdSearchController.dispose();
    _fullNameSearchController.dispose();
    _usernameSearchController.dispose();
    _phoneSearchController.dispose();
    _emailSearchController.dispose();
    _pincodeSearchController.dispose();
    _locationSearchController.dispose();
    _fieldOfficerIdSearchDebounce?.cancel();
    _fullNameSearchDebounce?.cancel();
    _usernameSearchDebounce?.cancel();
    _phoneSearchDebounce?.cancel();
    _emailSearchDebounce?.cancel();
    _pincodeSearchDebounce?.cancel();
    _locationSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllFieldOfficers() async {
    if (_allFieldOfficers.isNotEmpty) return; // Already loaded
    
    setState(() {
      _isLoadingAllFieldOfficers = true;
    });

    try {
      // Load all field officers for dropdown population
      final response = await FieldOfficerService.getFieldOfficers(
        page: 0,
        size: 10000, // Large size to get all field officers
        search: null,
        isActive: null,
      );

      setState(() {
        _allFieldOfficers = response.fieldOfficers;
        _isLoadingAllFieldOfficers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAllFieldOfficers = false;
      });
    }
  }

  List<String> _getUniqueStates() {
    final states = _allFieldOfficers
        .where((fo) => fo.state != null && fo.state!.isNotEmpty)
        .map((fo) => fo.state!)
        .toSet()
        .toList();
    states.sort();
    return states;
  }

  List<String> _getUniqueDistricts() {
    final districts = _allFieldOfficers
        .where((fo) => fo.district != null && fo.district!.isNotEmpty)
        .map((fo) => fo.district!)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  List<String> _getUniquePincodes() {
    final pincodes = _allFieldOfficers
        .where((fo) => fo.pincode != null && fo.pincode!.isNotEmpty)
        .map((fo) => fo.pincode!)
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  Future<void> _loadFieldOfficers({bool forceReload = false}) async {
      setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all field officers for filtering
      // Always reload if pincode filter is set (to get backend-filtered results)
      // Or if forceReload is true, or if _allFieldOfficers is empty
      if (_allFieldOfficers.isEmpty || _pincodeFilter != null || forceReload) {
        final allResponse = await FieldOfficerService.getFieldOfficers(
          page: 0,
          size: 10000,
          search: null,
          isActive: null,
        );
        setState(() {
          _allFieldOfficers = allResponse.fieldOfficers;
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 0;
    });
      _applyFiltersAndReload();
    });
  }

  void _onActiveFilterChanged(bool? value) {
    setState(() {
      _isActiveFilter = value;
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

  void _applyFiltersAndReload() {
    // Apply filters to all field officers and then paginate
    List<FieldOfficerSummary> filtered = List.from(_allFieldOfficers);

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final lowerQuery = _searchQuery!.toLowerCase();
      filtered = filtered.where((fo) {
        return fo.fullName.toLowerCase().contains(lowerQuery) ||
            fo.username.toLowerCase().contains(lowerQuery) ||
            fo.phoneNumber.contains(_searchQuery!) ||
            fo.email.toLowerCase().contains(lowerQuery) ||
            (fo.village ?? '').toLowerCase().contains(lowerQuery) ||
            (fo.district ?? '').toLowerCase().contains(lowerQuery) ||
            (fo.pincode ?? '').contains(_searchQuery!);
      }).toList();
    }

    // Apply column-specific search filters (table header)
    if (_fieldOfficerIdSearch != null && _fieldOfficerIdSearch!.isNotEmpty) {
      filtered = filtered.where((fo) {
        return fo.fieldOfficerId.toString().contains(_fieldOfficerIdSearch!);
      }).toList();
    }

    if (_fullNameSearch != null && _fullNameSearch!.isNotEmpty) {
      final lowerQuery = _fullNameSearch!.toLowerCase();
      filtered = filtered.where((fo) {
        return fo.fullName.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_usernameSearch != null && _usernameSearch!.isNotEmpty) {
      final lowerQuery = _usernameSearch!.toLowerCase();
      filtered = filtered.where((fo) {
        return fo.username.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_phoneSearch != null && _phoneSearch!.isNotEmpty) {
      filtered = filtered.where((fo) {
        return fo.phoneNumber.contains(_phoneSearch!);
      }).toList();
    }

    if (_emailSearch != null && _emailSearch!.isNotEmpty) {
      final lowerQuery = _emailSearch!.toLowerCase();
      filtered = filtered.where((fo) {
        return fo.email.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_pincodeSearch != null && _pincodeSearch!.isNotEmpty) {
      filtered = filtered.where((fo) {
        return (fo.pincode ?? '').contains(_pincodeSearch!);
      }).toList();
    }

    if (_locationSearch != null && _locationSearch!.isNotEmpty) {
      final lowerQuery = _locationSearch!.toLowerCase();
      filtered = filtered.where((fo) {
        return (fo.village ?? '').toLowerCase().contains(lowerQuery) ||
            (fo.district ?? '').toLowerCase().contains(lowerQuery) ||
            (fo.state ?? '').toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply Active filter (status dropdown)
    if (_isActiveFilter != null) {
      filtered = filtered.where((fo) {
        return fo.isActive == _isActiveFilter;
      }).toList();
    }

    // Apply multi-select State filter
    if (_selectedStates.isNotEmpty) {
      filtered = filtered.where((fo) {
        return fo.state != null && _selectedStates.contains(fo.state);
      }).toList();
    }

    // Apply multi-select District filter
    if (_selectedDistricts.isNotEmpty) {
      filtered = filtered.where((fo) {
        return fo.district != null && _selectedDistricts.contains(fo.district);
      }).toList();
    }

    // Apply multi-select Pincode filter
    if (_selectedPincodes.isNotEmpty) {
      filtered = filtered.where((fo) {
        return fo.pincode != null && _selectedPincodes.contains(fo.pincode);
      }).toList();
    }

    // Apply Date range filter
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((fo) {
        final createdDate = fo.createdAt;
        if (createdDate == null) return false;
        if (_startDate != null && createdDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && createdDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
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
          case SortColumn.fieldOfficerId:
            comparison = a.fieldOfficerId.compareTo(b.fieldOfficerId);
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
          case SortColumn.email:
            comparison = a.email.compareTo(b.email);
            break;
          case SortColumn.pincode:
            final aPincode = a.pincode ?? '';
            final bPincode = b.pincode ?? '';
            comparison = aPincode.compareTo(bPincode);
            break;
          case SortColumn.location:
            final aLocation = '${a.village ?? ''}, ${a.district ?? ''}';
            final bLocation = '${b.village ?? ''}, ${b.district ?? ''}';
            comparison = aLocation.compareTo(bLocation);
            break;
          case SortColumn.status:
            comparison = a.isActive.toString().compareTo(b.isActive.toString());
            break;
          case SortColumn.assignedFarmsCount:
            final aCount = a.assignedFarmsCount ?? 0;
            final bCount = b.assignedFarmsCount ?? 0;
            comparison = aCount.compareTo(bCount);
            break;
          case SortColumn.createdAt:
            final aDate = a.createdAt ?? DateTime(1970);
            final bDate = b.createdAt ?? DateTime(1970);
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
      _filteredFieldOfficers = pageData;
      _totalPages = totalPages;
      _totalElements = totalFiltered;
      _fieldOfficers = pageData; // For compatibility
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _applyFiltersAndReload();
  }

  int _getActiveFilterCount() {
    int count = 0;
    // New multi-select filters (advanced panel)
    if (_selectedStates.isNotEmpty) count++;
    if (_selectedDistricts.isNotEmpty) count++;
    if (_selectedPincodes.isNotEmpty) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    return count;
  }

  void _clearAdvancedFilters() {
    setState(() {
      // New multi-select filters
      _selectedStates = [];
      _selectedDistricts = [];
      _selectedPincodes = [];
      _startDate = null;
      _endDate = null;
      _currentPage = 0;
    });
    _applyFiltersAndReload();
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

  int get _totalFieldOfficers => _allFieldOfficers.length;
  int get _activeFieldOfficers => _allFieldOfficers.where((fo) => fo.isActive).length;
  int get _inactiveFieldOfficers => _allFieldOfficers.where((fo) => !fo.isActive).length;
  int get _totalAssignedFarms => _allFieldOfficers.fold(0, (sum, fo) => sum + (fo.assignedFarmsCount ?? 0));

  // ---------- Shared multi-select dropdown helpers (similar to Farmer screen) ----------

  Widget _buildMultiSelectFilter({
    required String label,
    required IconData icon,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showMultiSelectDialog(
          label: label,
          options: options,
          selectedValues: selectedValues,
          onChanged: onChanged,
        ),
        child: Container(
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
      ),
    );
  }

  void _showMultiSelectDialog({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    List<String> tempSelected = List.from(selectedValues);
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final List<String> filteredOptions = options
              .where(
                (o) => o.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.only(
              left: 200,
              right: 200,
              top: 150,
              bottom: 24,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $label',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setStateDialog(() {
                        searchQuery = value;
                      });
                    },
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search $label',
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
                                searchController.clear();
                                setStateDialog(() {
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
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.brandGreen,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filteredOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No options available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredOptions.length,
                        itemBuilder: (context, index) {
                          final option = filteredOptions[index];
                          final isSelected = tempSelected.contains(option);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setStateDialog(() {
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
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            activeColor: AppColors.brandGreen,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setStateDialog(() {
                    tempSelected.clear();
                  });
                  searchController.clear();
                  searchQuery = '';
                },
                child: Text(
                  'Clear All',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setStateDialog(() {
                    tempSelected = List.from(options);
                  });
                  searchController.clear();
                  searchQuery = '';
                },
                child: Text(
                  'Select All',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  onChanged(tempSelected);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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

              // Advanced Filters Panel (toggled from header Filters button)
              if (_showAdvancedFilters) ...[
                _buildAdvancedFiltersPanel(),
                const SizedBox(height: 20),
              ],

              // Field Officers Table with integrated filters
              _buildFieldOfficersTable(),

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
          'Field Officer Management',
          style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and monitor all field officers',
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
            // Filters Button (matches farmer screen position)
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
                    _loadAllFieldOfficers(); // Load all field officers when opening filters
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
            // Add Field Officer Button
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
                onPressed: _navigateToAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Add Field Officer',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1200;
        final isMedium = constraints.maxWidth > 800;
        
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Officers',
                  value: _totalFieldOfficers.toString(),
                  subtitle: 'All field officers',
                  icon: Icons.badge_rounded,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Officers',
                  value: _activeFieldOfficers.toString(),
                  subtitle: 'Currently active',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Inactive Officers',
                  value: _inactiveFieldOfficers.toString(),
                  subtitle: 'Currently inactive',
                  icon: Icons.cancel_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Total Assignments',
                  value: _totalAssignedFarms.toString(),
                  subtitle: 'Farm assignments',
                  icon: Icons.agriculture_rounded,
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
                      title: 'Total Officers',
                      value: _totalFieldOfficers.toString(),
                      subtitle: 'All field officers',
                      icon: Icons.badge_rounded,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Active Officers',
                      value: _activeFieldOfficers.toString(),
                      subtitle: 'Currently active',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Inactive Officers',
                      value: _inactiveFieldOfficers.toString(),
                      subtitle: 'Currently inactive',
                      icon: Icons.cancel_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Total Assignments',
                      value: _totalAssignedFarms.toString(),
                      subtitle: 'Farm assignments',
                      icon: Icons.agriculture_rounded,
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
                title: 'Total Officers',
                value: _totalFieldOfficers.toString(),
                subtitle: 'All field officers',
                icon: Icons.badge_rounded,
                color: AppColors.brandGreen,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'Active Officers',
                value: _activeFieldOfficers.toString(),
                subtitle: 'Currently active',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'Inactive Officers',
                value: _inactiveFieldOfficers.toString(),
                subtitle: 'Currently inactive',
                icon: Icons.cancel_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'Total Assignments',
                value: _totalAssignedFarms.toString(),
                subtitle: 'Farm assignments',
                icon: Icons.agriculture_rounded,
                color: AppColors.info,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
      padding: const EdgeInsets.all(16),
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
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return TextField(
              controller: _searchController,
                  onChanged: (value) {
                    setStateLocal(() {});
                    _onSearchChanged(value);
                  },
                  style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                    hintText: 'Search by name, username, phone, email, or location...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                        onPressed: () {
                          _searchController.clear();
                              setStateLocal(() {});
                              _onSearchChanged('');
                        },
                      )
                    : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Advanced Filters Button
        Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showAdvancedFilters = !_showAdvancedFilters;
                });
                if (_showAdvancedFilters) {
                  _loadAllFieldOfficers(); // Load all field officers when opening filters
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: _showAdvancedFilters 
                          ? AppColors.brandGreen 
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _showAdvancedFilters 
                            ? AppColors.brandGreen 
                            : Colors.grey.shade700,
                      ),
                    ),
                    if (_showAdvancedFilters) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getActiveFilterCount().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
              ),
            ),
          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
          // All advanced filters in a single clean row (Status, State, District, Pincode, Date Range)
          Row(
            children: [
              // Status Filter (dropdown)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<bool?>(
                    value: _isActiveFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.toggle_on_outlined,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Inactive')),
                    ],
                    onChanged: _onActiveFilterChanged,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // State multi-select
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'State',
                  icon: Icons.map_outlined,
                  options: _getUniqueStates(),
                  selectedValues: _selectedStates,
                  onChanged: (values) {
                    setState(() {
                      _selectedStates = values;
                      // Clear dependent multi-selects when state changes
                      if (values.isNotEmpty) {
                        final districtsInStates = _allFieldOfficers
                            .where((fo) => values.contains(fo.state) && fo.district != null)
                            .map((fo) => fo.district!)
                            .toSet()
                            .toList();
                        _selectedDistricts =
                            _selectedDistricts.where((d) => districtsInStates.contains(d)).toList();

                        final pincodesInStates = _allFieldOfficers
                            .where((fo) => values.contains(fo.state) && fo.pincode != null)
                            .map((fo) => fo.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes =
                            _selectedPincodes.where((p) => pincodesInStates.contains(p)).toList();
                      } else {
                        _selectedDistricts = [];
                        _selectedPincodes = [];
                      }
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // District multi-select
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'District',
                  icon: Icons.location_city_outlined,
                  options: _selectedStates.isNotEmpty
                      ? _getUniqueDistricts()
                          .where((d) => _allFieldOfficers
                              .where((fo) => _selectedStates.contains(fo.state))
                              .any((fo) => fo.district == d))
                          .toList()
                      : _getUniqueDistricts(),
                  selectedValues: _selectedDistricts,
                  onChanged: (values) {
                    setState(() {
                      _selectedDistricts = values;
                      // Adjust pincodes to stay in selected districts / states
                      if (values.isNotEmpty) {
                        final pincodesInDistricts = _allFieldOfficers
                            .where((fo) => values.contains(fo.district) && fo.pincode != null)
                            .map((fo) => fo.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes =
                            _selectedPincodes.where((p) => pincodesInDistricts.contains(p)).toList();
                      } else if (_selectedStates.isNotEmpty) {
                        final pincodesInStates = _allFieldOfficers
                            .where((fo) => _selectedStates.contains(fo.state) && fo.pincode != null)
                            .map((fo) => fo.pincode!)
                            .toSet()
                            .toList();
                        _selectedPincodes =
                            _selectedPincodes.where((p) => pincodesInStates.contains(p)).toList();
                      }
                      _currentPage = 0;
                    });
                    _applyFiltersAndReload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Pincode multi-select
              Expanded(
                child: _buildMultiSelectFilter(
                  label: 'Pincode',
                  icon: Icons.location_on_outlined,
                  options: () {
                    Iterable<FieldOfficerSummary> source = _allFieldOfficers;
                    if (_selectedStates.isNotEmpty) {
                      source =
                          source.where((fo) => _selectedStates.contains(fo.state));
                    }
                    if (_selectedDistricts.isNotEmpty) {
                      source =
                          source.where((fo) => _selectedDistricts.contains(fo.district));
                    }
                    return source
                        .where((fo) => fo.pincode != null && fo.pincode!.isNotEmpty)
                        .map((fo) => fo.pincode!)
                        .toSet()
                        .toList()
                      ..sort();
                  }(),
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
              // Date Range Filter (same as before)
              Expanded(
                child: Row(
                  children: [
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
                    const SizedBox(width: 8),
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
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFieldOfficersTable() {
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
              onPressed: _loadFieldOfficers,
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
              child: _buildCustomTable(constraints.maxWidth > 0 ? constraints.maxWidth : 1200),
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
    
    // Column widths (tuned to match farmer table look & avoid overflow)
    const double fieldOfficerIdWidth = 120.0;
    const double fullNameWidth = 210.0;
    const double usernameWidth = 150.0;
    const double phoneWidth = 150.0;
    const double emailWidth = 230.0;
    const double pincodeWidth = 110.0;
    const double locationWidth = 260.0;
    const double statusWidth = 130.0;
    const double farmAssignmentWidth = 170.0;
    
    final totalWidth = fieldOfficerIdWidth +
        fullNameWidth +
        usernameWidth +
        phoneWidth +
        emailWidth +
        pincodeWidth +
        locationWidth +
        statusWidth +
        farmAssignmentWidth;
    
    // Effective min width (either table content or available width)
    final tableMinWidth = totalWidth > minWidth ? totalWidth : minWidth;
    
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
          // Header Row (solid green like farmer table)
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
                _buildHeaderCell('Field Officer ID', fieldOfficerIdWidth, SortColumn.fieldOfficerId, true),
                _buildHeaderDivider(),
                _buildHeaderCell('Full Name', fullNameWidth, SortColumn.fullName, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Username', usernameWidth, SortColumn.username, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Phone No', phoneWidth, SortColumn.phoneNumber, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Email', emailWidth, SortColumn.email, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Pincode', pincodeWidth, SortColumn.pincode, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Location', locationWidth, SortColumn.location, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Status', statusWidth, SortColumn.status, false),
                _buildHeaderDivider(),
                _buildHeaderCell('Farm Assignment', farmAssignmentWidth, SortColumn.assignedFarmsCount, true),
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
                _buildFilterCell(fieldOfficerIdWidth, 'fieldOfficerId'),
                _buildDivider(),
                _buildFilterCell(fullNameWidth, 'fullName'),
                _buildDivider(),
                _buildFilterCell(usernameWidth, 'username'),
                _buildDivider(),
                _buildFilterCell(phoneWidth, 'phone'),
                _buildDivider(),
                _buildFilterCell(emailWidth, 'email'),
                _buildDivider(),
                _buildFilterCell(pincodeWidth, 'pincode'),
                _buildDivider(),
                _buildFilterCell(locationWidth, 'location'),
                _buildDivider(),
                _buildFilterCell(statusWidth, 'status'),
                _buildDivider(),
                _buildFilterCell(farmAssignmentWidth, null),
              ],
            ),
          ),
          // Data Rows Container with minimum height
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minDataHeight),
            child: _filteredFieldOfficers.isEmpty
                ? _buildEmptyState(tableMinWidth, minDataHeight)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._filteredFieldOfficers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final fieldOfficer = entry.value;
                        return _buildCustomFieldOfficerRow(
                          fieldOfficer,
                          rowHeight,
                          fieldOfficerIdWidth,
                          fullNameWidth,
                          usernameWidth,
                          phoneWidth,
                          emailWidth,
                          pincodeWidth,
                          locationWidth,
                          statusWidth,
                          farmAssignmentWidth,
                          index == _filteredFieldOfficers.length - 1, // Last row
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
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
                  Icons.badge_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No field officers found',
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
                  // Clear column search filters
                  _fieldOfficerIdSearchController.clear();
                  _fullNameSearchController.clear();
                  _usernameSearchController.clear();
                  _phoneSearchController.clear();
                  _emailSearchController.clear();
                  _pincodeSearchController.clear();
                  _locationSearchController.clear();
                  setState(() {
                    _fieldOfficerIdSearch = null;
                    _fullNameSearch = null;
                    _usernameSearch = null;
                    _phoneSearch = null;
                    _emailSearch = null;
                    _pincodeSearch = null;
                    _locationSearch = null;
                    _isActiveFilter = null;
                    _currentPage = 0;
                  });
                  _applyFiltersAndReload();
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
                ),
              ),
            ],
          ),
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

  Widget _buildHeaderCell(String label, double width, SortColumn? sortColumn, bool isFirstOrLast) {
    final isSorted = _sortColumn == sortColumn;
    return InkWell(
      onTap: sortColumn != null ? () => _onSortChanged(sortColumn) : null,
      hoverColor: Colors.white.withOpacity(0.08),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: filterType == 'status'
          ? SizedBox(
              width: width - 24,
              child: DropdownButtonFormField<bool?>(
                value: _isActiveFilter,
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
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: _onActiveFilterChanged,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
              ),
            )
          : filterType == 'fieldOfficerId'
              ? _buildSearchInput(width, _fieldOfficerIdSearchController, 'Search ID...', (value) {
                  _fieldOfficerIdSearchDebounce?.cancel();
                  _fieldOfficerIdSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _fieldOfficerIdSearch = value.isEmpty ? null : value;
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
                          : filterType == 'email'
                              ? _buildSearchInput(width, _emailSearchController, 'Search email...', (value) {
                                  _emailSearchDebounce?.cancel();
                                  _emailSearchDebounce = Timer(const Duration(milliseconds: 300), () {
                                    setState(() {
                                      _emailSearch = value.isEmpty ? null : value;
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
                                      : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchInput(
    double width,
    TextEditingController controller,
    String hint,
    Function(String) onChanged,
  ) {
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

  Widget _buildCustomFieldOfficerRow(
    FieldOfficerSummary fieldOfficer,
    double height,
    double fieldOfficerIdWidth,
    double fullNameWidth,
    double usernameWidth,
    double phoneWidth,
    double emailWidth,
    double pincodeWidth,
    double locationWidth,
    double statusWidth,
    double farmAssignmentWidth,
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
            onTap: () => _showAssignmentsDialog(fieldOfficer),
            hoverColor: AppColors.brandGreen.withOpacity(0.05),
            child: Row(
            children: [
                _buildDataCell(fieldOfficerIdWidth, Text(
                  fieldOfficer.fieldOfficerId.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ), true),
                _buildDivider(),
                _buildDataCell(fullNameWidth, Row(
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
                          fieldOfficer.fullName.isNotEmpty
                              ? fieldOfficer.fullName[0].toUpperCase()
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
                        fieldOfficer.fullName.isEmpty ? 'Not Set' : fieldOfficer.fullName,
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
                _buildDataCell(usernameWidth, Text(
                  fieldOfficer.username,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ), false),
                _buildDivider(),
                _buildDataCell(phoneWidth, Text(
                  fieldOfficer.phoneNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ), false),
                _buildDivider(),
                _buildDataCell(emailWidth, SizedBox(
                  width: emailWidth - 24,
                  child: Text(
                    fieldOfficer.email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ), false),
                _buildDivider(),
                _buildDataCell(pincodeWidth, Text(
                  fieldOfficer.pincode ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ), false),
                _buildDivider(),
                _buildDataCell(locationWidth, SizedBox(
                  width: locationWidth - 24,
                  child: Text(
                    '${fieldOfficer.village ?? '-'}, ${fieldOfficer.district ?? '-'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ), false),
                _buildDivider(),
                _buildDataCell(statusWidth, _buildStatusChip(fieldOfficer.isActive), false),
                _buildDivider(),
                _buildDataCell(farmAssignmentWidth, _buildFarmAssignmentCell(fieldOfficer), true),
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

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: count > 0
              ? AppColors.brandGreen.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: count > 0
                ? AppColors.brandGreen.withOpacity(0.3)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.agriculture_rounded,
              size: 18,
              color: count > 0 ? AppColors.brandGreen : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: count > 0 ? AppColors.brandGreen : Colors.grey.shade700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
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
