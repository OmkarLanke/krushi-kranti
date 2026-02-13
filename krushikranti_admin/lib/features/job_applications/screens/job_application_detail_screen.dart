import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/job_application_models.dart';
import '../services/job_application_service.dart';

class JobApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const JobApplicationDetailScreen({Key? key, required this.applicationId})
    : super(key: key);

  @override
  State<JobApplicationDetailScreen> createState() =>
      _JobApplicationDetailScreenState();
}

class _JobApplicationDetailScreenState
    extends State<JobApplicationDetailScreen> {
  final JobApplicationService _service = JobApplicationService();

  JobApplication? _application;
  bool _isLoading = true;
  bool _isProcessing = false;

  // HR Scheduling state
  bool _showHRForm = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _venueController = TextEditingController();
  final List<String> _requiredDocuments = [
    'Aadhaar Card',
    'PAN Card',
    'Educational Certificates',
    'Experience Letters (if applicable)',
    'Passport Size Photos (2)',
  ];

  // Offer Letter state
  bool _showOfferLetterForm = false;
  String? _offerLetterFileName;
  Uint8List? _offerLetterBytes;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  @override
  void dispose() {
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _loadApplication() async {
    setState(() => _isLoading = true);

    try {
      final application = await _service.getApplicationById(
        widget.applicationId,
      );

      setState(() {
        _application = application;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading application: $e')),
        );
      }
    }
  }

  Future<void> _pickOfferLetter() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _offerLetterFileName = result.files.single.name;
          _offerLetterBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _sendHRInvitation() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _venueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Prepare request data
      final requestData = {
        'interviewDate': _selectedDate!.toIso8601String().split('T')[0],
        'interviewTime':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        'venue': _venueController.text,
        'requiredDocuments': _requiredDocuments,
      };

      // Call backend API
      await HttpService.post(
        'api/applications/${widget.applicationId}/schedule-hr',
        requestData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'HR invitation sent! Status updated to Selected for HR',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _showHRForm = false;
          _selectedDate = null;
          _selectedTime = null;
          _venueController.clear();
        });

        await _loadApplication();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendOfferLetter() async {
    if (_offerLetterBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload offer letter PDF'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Prepare multipart request for file upload
      final uri = Uri.parse(
        '${HttpService.baseUrl}/api/applications/${widget.applicationId}/send-offer',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the offer letter PDF
      request.files.add(
        http.MultipartFile.fromBytes(
          'offerLetter',
          _offerLetterBytes!,
          filename: _offerLetterFileName ?? 'offer_letter.pdf',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Offer letter sent! Applicant is now hired (Selected)',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          setState(() {
            _showOfferLetterForm = false;
            _offerLetterFileName = null;
            _offerLetterBytes = null;
          });

          await _loadApplication();
        }
      } else {
        throw Exception('Failed to send offer letter: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending offer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectApplication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Application',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to reject this application? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Reject', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      try {
        // Call backend API to reject application
        await HttpService.put(
          'api/applications/${widget.applicationId}/reject',
          {},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected'),
              backgroundColor: AppColors.success,
            ),
          );

          await _loadApplication();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting application: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _getAuthToken() async {
    // Import storage service to get token
    try {
      final token = await StorageService.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> _downloadResume() async {
    if (_application?.resumeUrl == null) return;

    try {
      final url = Uri.parse(_application!.resumeUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening resume: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Application Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _application == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Application not found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Action Card
                  _buildStatusActionCard(),

                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildInfoRow('Full Name', _application!.fullName),
                      if (_application!.email != null)
                        _buildInfoRow('Email', _application!.email!),
                      if (_application!.mobileNumber != null)
                        _buildInfoRow(
                          'Mobile Number',
                          _application!.mobileNumber!,
                        ),
                      if (_application!.whatsappNumber != null)
                        _buildInfoRow(
                          'WhatsApp Number',
                          _application!.whatsappNumber!,
                        ),
                      if (_application!.dateOfBirth != null)
                        _buildInfoRow(
                          'Date of Birth',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(_application!.dateOfBirth!),
                        ),
                      if (_application!.gender != null)
                        _buildInfoRow('Gender', _application!.gender!),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Address Information
                  if (_application!.address != null ||
                      _application!.city != null ||
                      _application!.state != null ||
                      _application!.pincode != null)
                    _buildSectionCard(
                      title: 'Address Information',
                      icon: Icons.location_on_outlined,
                      children: [
                        if (_application!.address != null)
                          _buildInfoRow('Address', _application!.address!),
                        if (_application!.city != null)
                          _buildInfoRow('City', _application!.city!),
                        if (_application!.state != null)
                          _buildInfoRow('State', _application!.state!),
                        if (_application!.pincode != null)
                          _buildInfoRow('Pincode', _application!.pincode!),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Educational Details
                  _buildSectionCard(
                    title: 'Educational Details',
                    icon: Icons.school_outlined,
                    children: [
                      if (_application!.highestQualification != null)
                        _buildInfoRow(
                          'Highest Qualification',
                          _application!.highestQualification!,
                        ),
                      if (_application!.fieldOfStudy != null)
                        _buildInfoRow(
                          'Field of Study',
                          _application!.fieldOfStudy!,
                        ),
                      if (_application!.yearOfPassing != null)
                        _buildInfoRow(
                          'Year of Passing',
                          _application!.yearOfPassing.toString(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Experience Details
                  _buildSectionCard(
                    title: 'Experience Details',
                    icon: Icons.work_outline,
                    children: [
                      _buildInfoRow('Role Type', _application!.roleTypeDisplay),
                      _buildInfoRow(
                        'Previous Experience',
                        _application!.previousExperience ?? 'N/A',
                      ),
                      if (_application!.yearsOfExperience != null)
                        _buildInfoRow(
                          'Years of Experience',
                          _application!.yearsOfExperience!,
                        ),
                      if (_application!.relevantSkills != null)
                        _buildInfoRow(
                          'Relevant Skills',
                          _application!.relevantSkills!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Resume
                  if (_application!.resumeUrl != null)
                    _buildSectionCard(
                      title: 'Resume',
                      icon: Icons.description_outlined,
                      children: [
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _downloadResume,
                            icon: const Icon(Icons.download),
                            label: Text(
                              'Download Resume',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Application Timeline
                  _buildSectionCard(
                    title: 'Application Timeline',
                    icon: Icons.timeline,
                    children: [
                      _buildInfoRow(
                        'Applied On',
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(_application!.appliedAt),
                      ),
                      if (_application!.lastUpdated != null)
                        _buildInfoRow(
                          'Last Updated',
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(_application!.lastUpdated!),
                        ),
                      _buildInfoRow('Application ID', _application!.id),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusActionCard() {
    final status = _application!.currentStatus;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.brandGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Application Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(status, large: true),
            ],
          ),
          const SizedBox(height: 20),

          // Status-specific actions
          if (status == 'SCREENING') ...[
            if (!_showHRForm) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => setState(() => _showHRForm = true),
                      icon: const Icon(Icons.event),
                      label: Text(
                        'Approve for HR Round',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _rejectApplication,
                      icon: const Icon(Icons.close),
                      label: Text(
                        'Reject Application',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildHRSchedulingForm(),
            ],
          ] else if (status == 'SELECTED_FOR_HR') ...[
            if (!_showOfferLetterForm) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => setState(() => _showOfferLetterForm = true),
                      icon: const Icon(Icons.description),
                      label: Text(
                        'Approve for Final Offer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _rejectApplication,
                      icon: const Icon(Icons.close),
                      label: Text(
                        'Reject Application',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildOfferLetterForm(),
            ],
          ] else if (status == 'SELECTED') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Candidate has been hired! Offer letter has been sent.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'REJECTED') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This application has been rejected.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHRSchedulingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HR Round Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Date Picker
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.brandGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Select Interview Date'
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _selectedDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Time Picker
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: AppColors.brandGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'Select Interview Time'
                          : _selectedTime!.format(context),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _selectedTime == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Venue
          TextField(
            controller: _venueController,
            decoration: InputDecoration(
              labelText: 'Interview Venue',
              hintText: 'Enter office address or meeting link',
              prefixIcon: Icon(Icons.location_on, color: AppColors.brandGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),

          const SizedBox(height: 16),

          // Required Documents
          Text(
            'Required Documents',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ..._requiredDocuments
              .map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.brandGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          setState(() {
                            _showHRForm = false;
                            _selectedDate = null;
                            _selectedTime = null;
                            _venueController.clear();
                          });
                        },
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _sendHRInvitation,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    'Send Email Invitation',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildOfferLetterForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Offer Letter',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // File Upload
          InkWell(
            onTap: _isProcessing ? null : _pickOfferLetter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _offerLetterFileName != null
                      ? AppColors.brandGreen
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _offerLetterFileName != null
                        ? Icons.check_circle
                        : Icons.cloud_upload,
                    size: 48,
                    color: _offerLetterFileName != null
                        ? AppColors.brandGreen
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _offerLetterFileName ?? 'Click to upload PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: _offerLetterFileName != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _offerLetterFileName != null
                          ? AppColors.brandGreen
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_offerLetterFileName == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Only PDF files accepted',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          setState(() {
                            _showOfferLetterForm = false;
                            _offerLetterFileName = null;
                            _offerLetterBytes = null;
                          });
                        },
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _sendOfferLetter,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    'Send Offer Letter',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.brandGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool large = false}) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'SCREENING':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warning;
        break;
      case 'SELECTED_FOR_HR':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'SELECTED':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'REJECTED':
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 12,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(large ? 16 : 12),
      ),
      child: Text(
        _service.getStatusDisplay(status),
        style: GoogleFonts.poppins(
          fontSize: large ? 14 : 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
