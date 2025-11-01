import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GoogleMapController? mapController;
  bool _locationPermissionGranted = false;
  Position? _currentPosition;
  String _currentCity = 'Loading...';
  bool _isLoadingLocation = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Sample issues with real coordinates
  final List<IssueMarker> _issues = [
    IssueMarker(
      id: '1',
      position: const LatLng(28.6139, 77.2090),
      title: 'Pothole on Main St.',
      status: 'Resolved',
      timeAgo: '2h ago',
      severity: IssueSeverity.high,
    ),
    IssueMarker(
      id: '2',
      position: const LatLng(28.6150, 77.2100),
      title: 'Water leak on 2nd Ave.',
      status: 'In Progress',
      timeAgo: '5h ago',
      severity: IssueSeverity.medium,
    ),
    IssueMarker(
      id: '3',
      position: const LatLng(28.6120, 77.2080),
      title: 'Broken streetlight',
      status: 'In Progress',
      timeAgo: '1d ago',
      severity: IssueSeverity.low,
    ),
  ];

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
    _initializeLocation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _requestLocationPermission();
    if (_locationPermissionGranted) {
      await _getCurrentLocation();
      await _createMarkers();
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    setState(() => _locationPermissionGranted = status.isGranted);

    if (!status.isGranted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Location Permission Required',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Please enable location permission to see nearby issues and your current location.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentCity = 'Location disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Move camera to current location
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14.5,
            ),
          ),
        );
      }

      // Get city name from coordinates
      await _getCityFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _currentCity = 'Location unavailable';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getCityFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentCity = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting city: $e');
      setState(() {
        _currentCity = 'Unknown location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _createMarkers() async {
    final Set<Marker> markers = {};
    for (final issue in _issues) {
      final icon = await _markerIconForSeverity(issue.severity);
      markers.add(
        Marker(
          markerId: MarkerId(issue.id),
          position: issue.position,
          icon: icon,
          infoWindow: InfoWindow(
            title: issue.title,
            snippet: '${issue.status} • ${issue.timeAgo}',
          ),
          onTap: () => _showIssueDialog(issue),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _markerIconForSeverity(IssueSeverity severity) async {
    final hue = severity == IssueSeverity.high
        ? BitmapDescriptor.hueRed
        : severity == IssueSeverity.medium
        ? BitmapDescriptor.hueOrange
        : BitmapDescriptor.hueAzure;
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Alex!',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white70, size: 14.sp),
                const SizedBox(width: 4),
                _isLoadingLocation
                    ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
                    : Text(
                  _currentCity,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.amber, size: 16.sp),
                      const SizedBox(width: 4),
                      Text(
                        '1,250',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {},
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=3'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(28.6139, 77.2090),
              zoom: 14.5,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                );
              }
            },
            markers: _markers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // CUSTOM LOCATION BUTTON
          if (_locationPermissionGranted)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 80,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    if (_currentPosition != null && mapController != null) {
                      await mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 15,
                          ),
                        ),
                      );
                    } else {
                      await _getCurrentLocation();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          // DRAGGABLE BOTTOM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.25,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 50,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nearby Issues
                          _buildSection('Nearby Issues', primary),
                          _buildIssueList(_issues.take(3).toList()),

                          const SizedBox(height: 24),

                          // My Active Reports
                          _buildSection('My Active Reports', primary),
                          _buildMyReports(),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _fabAnimationController.reverse().then((_) {
              Navigator.pushNamed(context, '/report').then((_) {
                _fabAnimationController.forward();
              });
            });
          },
          backgroundColor: primary,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
          label: Text(
            'Report Issue',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // -------------------------------------------------------------------------
  // UI HELPERS
  // -------------------------------------------------------------------------
  void _showIssueDialog(IssueMarker issue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(issue.title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(issue.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(issue.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${issue.timeAgo}',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_severityIcon(issue.severity),
                    color: _severityColor(issue.severity), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${issue.severity.name.toUpperCase()} Severity',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: _severityColor(issue.severity),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('View Details', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 17.sp, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text('See all',
                        style: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueList(List<IssueMarker> issues) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: issues.length,
      itemBuilder: (_, i) => _IssueCard(issue: issues[i]),
    );
  }

  Widget _buildMyReports() {
    final myReports =
    _issues.where((i) => i.status == 'In Progress').toList();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: myReports.length,
        itemBuilder: (_, i) {
          final r = myReports[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showIssueDialog(r),
              child: Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _severityColor(r.severity).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_severityIcon(r.severity),
                              size: 16, color: _severityColor(r.severity)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.status,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _statusColor(r.status),
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text(r.timeAgo,
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _severityColor(IssueSeverity s) => s == IssueSeverity.high
      ? Colors.red
      : s == IssueSeverity.medium
      ? Colors.orange
      : Colors.blue;

  IconData _severityIcon(IssueSeverity s) => s == IssueSeverity.high
      ? Icons.warning
      : s == IssueSeverity.medium
      ? Icons.info
      : Icons.lightbulb;

  Color _statusColor(String status) =>
      status == 'Resolved' ? Colors.green : Colors.orange;
}

// -------------------------------------------------------------------------
// MODELS
// -------------------------------------------------------------------------
class IssueMarker {
  final String id;
  final LatLng position;
  final String title;
  final String status;
  final String timeAgo;
  final IssueSeverity severity;

  const IssueMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.status,
    required this.timeAgo,
    required this.severity,
  });
}

enum IssueSeverity { high, medium, low }

// -------------------------------------------------------------------------
// REUSABLE CARD
// -------------------------------------------------------------------------
class _IssueCard extends StatelessWidget {
  final IssueMarker issue;

  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show issue details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _severityColor(issue.severity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_severityIcon(issue.severity),
                      color: _severityColor(issue.severity), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(issue.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              issue.status,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _statusColor(issue.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${issue.timeAgo}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _severityColor(IssueSeverity s) => s == IssueSeverity.high
      ? Colors.red
      : s == IssueSeverity.medium
      ? Colors.orange
      : Colors.blue;

  IconData _severityIcon(IssueSeverity s) => s == IssueSeverity.high
      ? Icons.warning
      : s == IssueSeverity.medium
      ? Icons.info
      : Icons.lightbulb;

  Color _statusColor(String status) =>
      status == 'Resolved' ? Colors.green : Colors.orange;
}