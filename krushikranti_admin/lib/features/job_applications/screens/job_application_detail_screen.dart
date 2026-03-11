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
      appBar: _buildAppBar(),
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
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusTimeline(),
                      const SizedBox(height: 32),
                      
                      // Desktop: Row for Action Card + Info
                      // Mobile: Column
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                     _buildSectionCard(
                                        title: 'Personal Information',
                                        icon: Icons.person_outline,
                                        child: _buildResponsiveGrid([
                                          _buildInfoItem('Full Name', _application!.fullName),
                                          if (_application!.email != null)
                                            _buildInfoItem('Email', _application!.email!),
                                          if (_application!.mobileNumber != null)
                                            _buildInfoItem('Mobile Number', _application!.mobileNumber!),
                                          if (_application!.whatsappNumber != null)
                                            _buildInfoItem('WhatsApp', _application!.whatsappNumber!),
                                          if (_application!.dateOfBirth != null)
                                            _buildInfoItem(
                                              'Date of Birth',
                                              DateFormat('dd MMM yyyy').format(_application!.dateOfBirth!),
                                            ),
                                          if (_application!.gender != null)
                                            _buildInfoItem('Gender', _application!.gender!),
                                        ]),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSectionCard(
                                        title: 'Address Information',
                                        icon: Icons.location_on_outlined,
                                        child: _buildResponsiveGrid([
                                          if (_application!.address != null)
                                            _buildInfoItem('Address', _application!.address!, flex: 2), // Spans 2 cols
                                          if (_application!.city != null)
                                            _buildInfoItem('City', _application!.city!),
                                          if (_application!.state != null)
                                            _buildInfoItem('State', _application!.state!),
                                          if (_application!.pincode != null)
                                            _buildInfoItem('Pincode', _application!.pincode!),
                                        ]),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSectionCard(
                                        title: 'Educational & Experience',
                                        icon: Icons.school_outlined,
                                        child: _buildResponsiveGrid([
                                          if (_application!.highestQualification != null)
                                            _buildInfoItem('Qualification', _application!.highestQualification!),
                                          if (_application!.yearOfPassing != null)
                                            _buildInfoItem('Passing Year', _application!.yearOfPassing.toString()),
                                          _buildInfoItem('Role Applied', _application!.roleTypeDisplay),
                                          if (_application!.yearsOfExperience != null)
                                            _buildInfoItem('Experience', _application!.yearsOfExperience!),
                                          if (_application!.previousExperience != null)
                                            _buildInfoItem('Prev. Exp.', _application!.previousExperience!),
                                           if (_application!.relevantSkills != null)
                                            _buildInfoItem('Skills', _application!.relevantSkills!, flex: 3),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      _buildActionCard(),
                                      const SizedBox(height: 24),
                                      if (_application!.resumeUrl != null)
                                        _buildResumeCard(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mobile Layout
                            return Column(
                              children: [
                                _buildActionCard(),
                                const SizedBox(height: 24),
                                _buildSectionCard(
                                  title: 'Personal Information',
                                  icon: Icons.person_outline,
                                  child: Column(
                                    children: [
                                      _buildInfoRow('Full Name', _application!.fullName),
                                      if (_application!.email != null) _buildInfoRow('Email', _application!.email!),
                                      // ... other mobile fields
                                    ],
                                  ),
                                ),
                                // ... other mobile sections
                                if (_application!.resumeUrl != null)
                                  _buildResumeCard(),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
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
      actions: [
         if (_application?.currentStatus == 'SCREENING' || _application?.currentStatus == 'SELECTED_FOR_HR')
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Row(
              children: [
                 OutlinedButton(
                  onPressed: _isProcessing ? null : _rejectApplication,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isProcessing 
                    ? null 
                    : () {
                        if (_application!.currentStatus == 'SCREENING') {
                           setState(() => _showHRForm = true);
                        } else {
                           setState(() => _showOfferLetterForm = true);
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _application!.currentStatus == 'SCREENING' ? 'Approve for HR' : 'Send Offer', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ]
    );
  }

  Widget _buildStatusTimeline() {
    final steps = ['Applied', 'Screening', 'HR Round', 'Offer', 'Hired'];
    int currentStep = 0;
    
    switch (_application!.currentStatus) {
      case 'APPLIED': currentStep = 0; break;
      case 'SCREENING': currentStep = 1; break;
      case 'SELECTED_FOR_HR': currentStep = 2; break; 
      case 'OFFER_SENT': currentStep = 3; break; // Assuming exist
      case 'SELECTED': currentStep = 4; break;
      case 'REJECTED': currentStep = -1; break; // Handle rejection specially
    }

    if (currentStep == -1) {
       return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Application Rejected', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 16)),
                Text('This application has been closed.', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == steps.length - 1;
              
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? AppColors.brandGreen : Colors.grey.shade200,
                            border: isCurrent ? Border.all(color: AppColors.brandGreen, width: 4) : null,
                          ),
                          child: Center(
                            child: isCompleted 
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text('${index + 1}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          steps[index],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                            color: isCompleted ? AppColors.brandGreen : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentStep ? AppColors.brandGreen : Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0).copyWith(bottom: 24),
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        }
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> children) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: children,
    );
  }

  Widget _buildInfoItem(String label, String value, {int flex = 1}) {
    // Basic calculation for 3 columns on desktop (approx 30% width)
    // Adjust logic if strictly need Flex, but Wrap works better for flowing content
    return LayoutBuilder(
      builder: (context, constraints) {
        // We want 3 items per row roughly
        // If parent has specific width, we can calculate.
        // For now, let's give them a min-width approx 250px
        return SizedBox(
          width: 250.0 * flex, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
               const SizedBox(height: 4),
               Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(icon, size: 20, color: Colors.grey.shade700),
               const SizedBox(width: 8),
               Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
             ],
           ),
           const Divider(height: 32),
           child,
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    // If we have specific forms (HR/Offer) open, show them here
    if (_showHRForm) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brandGreen, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Schedule HR Round', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)), IconButton(onPressed: () => setState(() => _showHRForm = false), icon: const Icon(Icons.close))]),
             const SizedBox(height: 16),
             _buildHRSchedulingForm(),
          ],
        ),
      );
    }
    
    if (_showOfferLetterForm) {
       return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brandGreen, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Send Offer Letter', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)), IconButton(onPressed: () => setState(() => _showOfferLetterForm = false), icon: const Icon(Icons.close))]),
             const SizedBox(height: 16),
             _buildOfferLetterForm(),
          ],
        ),
      );
    }

    // Default Action Summary or Empty if completed
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Current Status', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.brandGreen)),
           const SizedBox(height: 4),
           Text(_application!.statusDisplay, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
           const SizedBox(height: 8),
           Text('Review the details and take action from the top-right menu.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildResumeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Resume', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
           const SizedBox(height: 16),
           InkWell(
             onTap: _downloadResume,
             child: Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.grey.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey.shade200),
               ),
               child: Row(
                 children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Applicant Resume.pdf', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          Text('Click to download', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.download_rounded, color: Colors.grey.shade400),
                 ],
               ),
             ),
           ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upload Offer Letter',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_offerLetterFileName != null)
                 TextButton(onPressed: _isProcessing ? null : () => setState(() {
                   _offerLetterFileName = null; 
                   _offerLetterBytes = null;
                 }), child: Text('Remove', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12)))
            ],
          ),
          const SizedBox(height: 12),

          // File Upload Area
          InkWell(
            onTap: _isProcessing ? null : _pickOfferLetter,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _offerLetterFileName != null
                      ? AppColors.brandGreen
                      : Colors.grey.shade300,
                  width: _offerLetterFileName != null ? 2 : 1,
                  style: _offerLetterFileName != null ? BorderStyle.solid : BorderStyle.none, // Dotted border workaround requires custom painter, using solid/dashed implication or just simple border
                ),
              ),
              child: _offerLetterFileName != null 
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.brandGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.picture_as_pdf, color: AppColors.brandGreen, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_offerLetterFileName!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Ready to send', style: GoogleFonts.poppins(color: AppColors.brandGreen, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: AppColors.brandGreen),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Click to upload Offer Letter PDF', style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Supported format: PDF', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
            ),
          ),
          
          if (_offerLetterFileName == null) ...[
             // Helper text or Dotted border implementation could go here
          ] else ...[
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _sendOfferLetter,
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Send Offer Letter',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
             ),
          ],
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
