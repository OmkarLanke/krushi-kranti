import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';
import '../models/field_officer_models.dart';
import '../services/field_officer_service.dart';

class AddFieldOfficerScreen extends StatefulWidget {
  const AddFieldOfficerScreen({super.key});

  @override
  State<AddFieldOfficerScreen> createState() => _AddFieldOfficerScreenState();
}

class _AddFieldOfficerScreenState extends State<AddFieldOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLookingUp = false;

  // Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;

  // Contact Information
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Address Information
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _talukaController = TextEditingController();
  final _stateController = TextEditingController();
  String? _selectedVillage;
  List<String> _villageList = [];

  // Credentials
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Additional
  bool _isActive = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _talukaController.dispose();
    _stateController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _lookupAddress() async {
    final pincode = _pincodeController.text.trim();
    
    if (pincode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter a valid 6-digit pincode",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLookingUp = true;
    });

    try {
      final response = await HttpService.get("farmer/profile/address/lookup?pincode=$pincode");
      final data = response['data'] ?? {};
      
      if (mounted && data.isNotEmpty) {
        setState(() {
          _districtController.text = data['district'] ?? "";
          _talukaController.text = data['taluka'] ?? "";
          _stateController.text = data['state'] ?? "";
          _villageList = List<String>.from(data['villages'] ?? []);
          _selectedVillage = null;
          _isLookingUp = false;
        });
      } else {
        throw Exception("No address found for this pincode");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _parseErrorMessage(e.toString()),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brandGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a village",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select gender",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateFieldOfficerRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        gender: _selectedGender!,
        phoneNumber: _phoneController.text.trim(),
        alternatePhone: _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
        email: _emailController.text.trim(),
        pincode: _pincodeController.text.trim(),
        village: _selectedVillage!,
        district: _districtController.text.trim(),
        taluka: _talukaController.text.trim(),
        state: _stateController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        isActive: _isActive,
      );

      await FieldOfficerService.createFieldOfficer(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Field officer created successfully",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _parseErrorMessage(e.toString()),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  String _parseErrorMessage(String error) {
    String message = error.replaceFirst("Exception: ", "").trim();
    String lowerMessage = message.toLowerCase();
    
    // Check for pincode-specific errors first (most user-friendly)
    if (lowerMessage.contains('no address found') ||
        lowerMessage.contains('pincode not found') ||
        lowerMessage.contains('address not found') ||
        (lowerMessage.contains('not found') && lowerMessage.contains('pincode'))) {
      return 'Pincode not found. Please check the 6-digit pincode and try again.';
    }
    
    // Check for invalid pincode format
    if (lowerMessage.contains('invalid pincode') ||
        lowerMessage.contains('pincode must be') ||
        lowerMessage.contains('pincode should be')) {
      return 'Invalid pincode format. Please enter a valid 6-digit pincode.';
    }
    
    // Network errors
    if (lowerMessage.contains('network error') || 
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('connection reset')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }
    
    // Server errors
    if (lowerMessage.contains('server error') ||
        lowerMessage.contains('500') ||
        lowerMessage.contains('internal server error')) {
      return 'Server error occurred. Please try again in a few moments.';
    }
    
    // Service not found (but not pincode-related)
    if (lowerMessage.contains('not found') ||
        lowerMessage.contains('404')) {
      return 'The requested service is temporarily unavailable. Please try again later.';
    }
    
    // Timeout errors
    if (lowerMessage.contains('timeout') ||
        lowerMessage.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    // If the message is short and clear, use it directly
    if (message.isNotEmpty && message.length < 100 && !lowerMessage.contains('exception')) {
      return message;
    }
    
    // Default fallback
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Field Officer',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (matching list screen style)
              Text(
                'Create New Field Officer',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in the details to create a new field officer account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person_outline),
              const SizedBox(height: 16),
              _buildPersonalInfoSection(),
              const SizedBox(height: 28),
              
              // Contact Information Section
              _buildSectionHeader('Contact Information', Icons.phone_outlined),
              const SizedBox(height: 16),
              _buildContactInfoSection(),
              const SizedBox(height: 28),
              
              // Address Information Section
              _buildSectionHeader('Address Information', Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildAddressInfoSection(),
              const SizedBox(height: 28),
              
              // Credentials Section
              _buildSectionHeader('Credentials', Icons.lock_outline),
              const SizedBox(height: 16),
              _buildCredentialsSection(),
              const SizedBox(height: 28),
              
              // Additional Section
              _buildSectionHeader('Additional', Icons.settings_outlined),
              const SizedBox(height: 16),
              _buildAdditionalSection(),
              const SizedBox(height: 32),
              
              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.brandGreen,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'Enter first name',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Enter last name',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        hint: 'Select date',
                        isReadOnly: true,
                        suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade400, size: 20),
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        value: _selectedGender,
                        label: 'Gender',
                        hint: 'Select gender',
                        isRequired: true,
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter first name',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter last name',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hint: 'Select date',
                  isReadOnly: true,
                  suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade400, size: 20),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  value: _selectedGender,
                  label: 'Gender',
                  hint: 'Select gender',
                  isRequired: true,
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Gender is required';
                    }
                    return null;
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter 10-digit phone number',
            isRequired: true,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (value.trim().length != 10) {
                return 'Phone number must be exactly 10 digits';
              }
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                return 'Phone number must contain only digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _altPhoneController,
            label: 'Alternate Phone',
            hint: 'Enter alternate phone (optional)',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.trim().length != 10) {
                  return 'Phone number must be exactly 10 digits';
                }
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                  return 'Phone number must contain only digits';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter email address',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          
          return Column(
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _pincodeController,
                        label: 'Pincode',
                        hint: 'Enter 6-digit pincode',
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pincode is required';
                          }
                          if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                            return 'Pincode must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
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
                          onPressed: _isLookingUp ? null : _lookupAddress,
                          icon: _isLookingUp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.search_rounded, size: 18),
                          label: Text(
                            _isLookingUp ? 'Looking up...' : 'Lookup',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter 6-digit pincode',
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pincode is required';
                        }
                        if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                          return 'Pincode must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
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
                        onPressed: _isLookingUp ? null : _lookupAddress,
                        icon: _isLookingUp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 18),
                        label: Text(
                          _isLookingUp ? 'Looking up...' : 'Lookup',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _districtController,
                label: 'District',
                hint: 'Auto-filled from pincode',
                isReadOnly: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _talukaController,
                label: 'Taluka',
                hint: 'Auto-filled from pincode',
                isReadOnly: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _stateController,
                label: 'State',
                hint: 'Auto-filled from pincode',
                isReadOnly: true,
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                value: _selectedVillage,
                label: 'Village',
                hint: _villageList.isEmpty ? 'No villages found. Please lookup pincode first.' : 'Select village',
                isRequired: true,
                items: _villageList.isEmpty
                    ? [
                        const DropdownMenuItem(
                          value: null,
                          enabled: false,
                          child: Text('No villages available'),
                        ),
                      ]
                    : _villageList.map((village) {
                        return DropdownMenuItem(
                          value: village,
                          child: Text(
                            village,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                onChanged: _villageList.isEmpty
                    ? null
                    : (value) {
                        if (mounted) {
                          setState(() {
                            _selectedVillage = value;
                          });
                        }
                      },
                validator: (value) {
                  if (_villageList.isEmpty) {
                    return 'Please lookup pincode first';
                  }
                  if (value == null) {
                    return 'Village is required';
                  }
                  return null;
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter username (admin assigns)',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter password (min 8 characters)',
            isRequired: true,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.trim().length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            isRequired: true,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Active Status',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Field officer will be active by default',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        value: _isActive,
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        activeColor: AppColors.brandGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    bool isReadOnly = false,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        suffixIcon: suffixIcon,
        errorMaxLines: 2,
        filled: true,
        fillColor: isReadOnly ? Colors.grey.shade50 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    Function(String?)? onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white,
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Create Field Officer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
