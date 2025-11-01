import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _submitAnimationController;
  late Animation<double> _submitAnimation;
  final supabase = Supabase.instance.client;
  final String submitReportUrl =
      'https://zfkhuajqzshwjtnlzaaw.supabase.co/functions/v1/smooth-responder';
  final dio = Dio();

  File? _image;
  String _title = '';
  String _description = '';
  String _category = 'Other';
  bool _isAtLocation = false;
  LatLng? _location;
  bool _isLoadingLocation = false;
  String _locationError = '';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pothole', 'icon': Icons.warning_amber_rounded},
    {'name': 'Graffiti', 'icon': Icons.palette_outlined},
    {'name': 'Fallen Tree', 'icon': Icons.park_outlined},
    {'name': 'Damaged Road Sign', 'icon': Icons.lightbulb_outline},
    {'name': 'Garbage', 'icon': Icons.delete_outline},
    {'name': 'Water Leak', 'icon': Icons.water_drop_outlined},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _submitAnimation = CurvedAnimation(
      parent: _submitAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Photo Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check permission
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (!status.isGranted) {
        setState(() {
          _locationError = 'Location permission denied';
          _isLoadingLocation = false;
          _isAtLocation = false;
        });
        return;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoadingLocation = false;
          _isAtLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        )
      );

      setState(() {
        _location = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
        _isAtLocation = false;
      });
    }
  }

  void _nextStep() async {
    if (_currentStep == 0 && _image != null) {
      setState(() => _isLoadingLocation = true);

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:8080/upload-image'),
        );
        request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint(response.body);

          final detections = json['detections'] as List<dynamic>? ?? [];
          if (detections.isNotEmpty) {
            final best = detections.cast<Map<String, dynamic>>().reduce((a, b) =>
            (a['confidence'] as num) > (b['confidence'] as num) ? a : b);

            final className = best['class_name'] as String;
            final confidence = best['confidence'] as num;

            if (confidence > 0.5) {
              final pretty = className.replaceAll('_', ' ').split(' ').map((w) =>
              '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
              if (_categories.any((c) => c['name'] == pretty)) {
                setState(() => _category = pretty);
              }
            }
          }
        } else {
          debugPrint('Upload failed: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        debugPrint('Upload error: $e');
      } finally {
        setState(() => _isLoadingLocation = false);
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submitReport();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submitReport() async {
    // ----- VALIDATION -----
    if (_image == null || _location == null || _title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // ----- SHOW LOADING -----
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image (no need to store return value)
      await supabase.storage
          .from('report-images')
          .upload(fileName, _image!, fileOptions: const FileOptions(upsert: false));

      // Get public URL
      final imageUrl = supabase.storage.from('report-images').getPublicUrl(fileName);

      // Prepare payload
      final payload = {
        'user_id': supabase.auth.currentUser!.id,
        'title': _title.trim(),
        'description': _description.isEmpty ? null : _description.trim(),
        'category': _category,
        'image_urls': [imageUrl],
        'latitude': _location!.latitude,
        'longitude': _location!.longitude,
      };

      final response = await http.post(
        Uri.parse(submitReportUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.body}');
      }

      final result = jsonDecode(response.body);
      debugPrint('Report ID: ${result['report_id']} | Merged: ${result['merged']}');

      if (mounted) Navigator.pop(context);

      setState(() {
        _currentStep = 0;
        _image = null;
        _title = '';
        _description = '';
        _category = 'Other';
        _isAtLocation = false;
        _location = null;
      });
      _pageController.jumpToPage(0);

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      debugPrint('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    _submitAnimationController.forward(from: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScaleTransition(
        scale: _submitAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Report Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for making your community better. You\'ve earned 50 karma points!',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+50 Karma',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Report Another Issue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Issue',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: List.generate(3, (i) {
                bool isActive = i <= _currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive ? primary : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepLabel(0, 'Photo', Icons.camera_alt_rounded),
                _buildStepLabel(1, 'Details', Icons.edit_note_rounded),
                _buildStepLabel(2, 'Review', Icons.check_circle_outline_rounded),
              ],
            ),
          ),

          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),

          // Bottom Buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _validateAndNext(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? 'Submit Report' : 'Continue',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 2
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(int step, String label, IconData icon) {
    bool isActive = step == _currentStep;
    bool isCompleted = step < _currentStep;

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive || isCompleted
              ? Theme.of(context).primaryColor
              : Colors.grey[400],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive || isCompleted
                ? Theme.of(context).primaryColor
                : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture the Issue',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a clear photo showing the problem',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap to Add Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera or Gallery',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showImageSourceDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Details',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand the problem better',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Title *',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _title = v),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'e.g., Large pothole near bus stop',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),

          // Category
          Text(
            'Category *',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((cat) {
              bool isSelected = _category == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _category = cat['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'],
                        size: 20,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Description (Optional)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _description = v),
            maxLines: 4,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'Add more details about the issue...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),

          // Location Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current Location',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'I am at the issue location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAtLocation,
                      onChanged: (v) {
                        setState(() => _isAtLocation = v);
                        if (v) {
                          _getCurrentLocation();
                        }
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                if (_isLoadingLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Getting your location...',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_locationError.isNotEmpty && !_isLoadingLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationError,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_location != null && !_isLoadingLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location captured: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please verify all information before submitting',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Photo Preview
          if (_image != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _summaryRow(
                  'Title',
                  _title.isEmpty ? '—' : _title,
                  Icons.title_rounded,
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _summaryRow(
                  'Category',
                  _category,
                  _categories.firstWhere((c) => c['name'] == _category)['icon'],
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _summaryRow(
                  'Description',
                  _description.isEmpty ? 'No description provided' : _description,
                  Icons.description_outlined,
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _summaryRow(
                  'Location',
                  _isAtLocation && _location != null
                      ? 'Current location\n${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}'
                      : 'Location not set',
                  Icons.location_on_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Info Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your report will be reviewed and assigned to the appropriate department.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).primaryColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _validateAndNext() {
    if (_currentStep == 0 && _image == null) return null;
    if (_currentStep == 1 && _title.trim().isEmpty) return null;
    return _nextStep;
  }
}