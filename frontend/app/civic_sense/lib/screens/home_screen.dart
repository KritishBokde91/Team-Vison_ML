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
  late AnimationController _statsAnimationController;
  String _selectedFilter = 'All';

  final List<IssueMarker> _issues = [
    IssueMarker(
      id: '1',
      position: const LatLng(28.6139, 77.2090),
      title: 'Pothole on Main St.',
      description: 'Large pothole causing traffic issues',
      status: 'Resolved',
      timeAgo: '2h ago',
      severity: IssueSeverity.high,
      category: 'Pothole',
      upvotes: 24,
    ),
    IssueMarker(
      id: '2',
      position: const LatLng(28.6150, 77.2100),
      title: 'Water leak on 2nd Ave.',
      description: 'Continuous water leakage from pipe',
      status: 'In Progress',
      timeAgo: '5h ago',
      severity: IssueSeverity.medium,
      category: 'Water Leak',
      upvotes: 15,
    ),
    IssueMarker(
      id: '3',
      position: const LatLng(28.6120, 77.2080),
      title: 'Broken streetlight',
      description: 'Street light not working for 3 days',
      status: 'In Progress',
      timeAgo: '1d ago',
      severity: IssueSeverity.low,
      category: 'Streetlight',
      upvotes: 8,
    ),
    IssueMarker(
      id: '4',
      position: const LatLng(28.6165, 77.2085),
      title: 'Garbage accumulation',
      description: 'Pile of garbage not collected',
      status: 'Pending',
      timeAgo: '3h ago',
      severity: IssueSeverity.high,
      category: 'Garbage',
      upvotes: 32,
    ),
    IssueMarker(
      id: '5',
      position: const LatLng(28.6125, 77.2105),
      title: 'Broken sidewalk',
      description: 'Cracked pavement dangerous for pedestrians',
      status: 'Pending',
      timeAgo: '6h ago',
      severity: IssueSeverity.medium,
      category: 'Infrastructure',
      upvotes: 12,
    ),
  ];

  Set<Marker> _markers = {};
  Set<Circle> _heatmapCircles = {};
  bool _showHeatmap = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController.forward();
    _statsAnimationController.forward();
    _initializeLocation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _requestLocationPermission();
    if (_locationPermissionGranted) {
      await _getCurrentLocation();
      await _createMarkersAndHeatmap();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text('Location Access', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'We need location access to show nearby issues and provide a better experience.',
          style: GoogleFonts.poppins(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Enable', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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

      await _getCityFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
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
      setState(() {
        _currentCity = 'Unknown location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _createMarkersAndHeatmap() async {
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};

    for (final issue in _issues) {
      final icon = await _markerIconForSeverity(issue.severity);
      markers.add(
        Marker(
          markerId: MarkerId(issue.id),
          position: issue.position,
          icon: icon,
          onTap: () => _showIssueBottomSheet(issue),
        ),
      );

      // Create heatmap circles
      circles.add(
        Circle(
          circleId: CircleId('heat_${issue.id}'),
          center: issue.position,
          radius: issue.severity == IssueSeverity.high ? 200 : issue.severity == IssueSeverity.medium ? 150 : 100,
          fillColor: _severityColor(issue.severity).withOpacity(0.15),
          strokeColor: _severityColor(issue.severity).withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _heatmapCircles = circles;
    });
  }

  Future<BitmapDescriptor> _markerIconForSeverity(IssueSeverity severity) async {
    final hue = severity == IssueSeverity.high
        ? BitmapDescriptor.hueRed
        : severity == IssueSeverity.medium
        ? BitmapDescriptor.hueOrange
        : BitmapDescriptor.hueGreen;
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  List<IssueMarker> get _filteredIssues {
    if (_selectedFilter == 'All') return _issues;
    return _issues.where((issue) => issue.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            circles: _showHeatmap ? _heatmapCircles : {},
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            mapType: MapType.normal,
          ),

          // TOP GRADIENT OVERLAY
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // HEADER SECTION
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  // Top Bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Alex! 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
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
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Karma Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '1,250',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Profile
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=3'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stats Cards
                  // _buildStatsCards(),
                ],
              ),
            ),
          ),

          // MAP CONTROLS
          Positioned(
            right: 20,
            top: MediaQuery.of(context).padding.top + 200,
            child: Column(
              children: [
                // Heatmap Toggle
                _buildMapControl(
                  icon: _showHeatmap ? Icons.layers_rounded : Icons.layers_outlined,
                  onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                  color: _showHeatmap ? primary : Colors.grey[700]!,
                ),
                const SizedBox(height: 12),
                // My Location
                if (_locationPermissionGranted)
                  _buildMapControl(
                    icon: Icons.my_location_rounded,
                    onTap: () async {
                      if (_currentPosition != null && mapController != null) {
                        await mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 16,
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),

          // BOTTOM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Drag Handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterTabs(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Issues List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final issue = _filteredIssues[index];
                            return _buildEnhancedIssueCard(issue);
                          },
                          childCount: _filteredIssues.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // FLOATING ACTION BUTTON
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _fabAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: primary,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        _fabAnimationController.reverse().then((_) {
                          Navigator.pushNamed(context, '/report').then((_) {
                            _fabAnimationController.forward();
                          });
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Report Issue',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.report_problem_rounded,
            label: 'Active',
            value: '${_issues.where((i) => i.status != 'Resolved').length}',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Resolved',
            value: '${_issues.where((i) => i.status == 'Resolved').length}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            label: 'My Reports',
            value: '12',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return FadeTransition(
      opacity: _statsAnimationController,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'In Progress', 'Resolved'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedIssueCard(IssueMarker issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showIssueBottomSheet(issue),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Severity Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _severityColor(issue.severity).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _severityIcon(issue.severity),
                        color: _severityColor(issue.severity),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            issue.category,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(issue.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.status,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(issue.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  issue.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Bottom Info
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      issue.timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    // Upvotes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${issue.upvotes}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIssueBottomSheet(IssueMarker issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _severityColor(issue.severity).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _severityIcon(issue.severity),
                            color: _severityColor(issue.severity),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issue.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                issue.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status and Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(issue.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _statusIcon(issue.status),
                                size: 16,
                                color: _statusColor(issue.status),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                issue.status,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(issue.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          issue.timeAgo,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Severity Level
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _severityColor(issue.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _severityColor(issue.severity).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high_rounded,
                            color: _severityColor(issue.severity),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${issue.severity.name.toUpperCase()} Priority',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _severityColor(issue.severity),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${issue.position.latitude.toStringAsFixed(6)}, ${issue.position.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: issue.position,
                                    zoom: 18,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.open_in_new_rounded, size: 20, color: Theme.of(context).primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Community Engagement
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: Theme.of(context).primaryColor, size: 24),
                                const SizedBox(height: 8),
                                Text(
                                  '${issue.upvotes}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Upvotes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.comment_rounded, color: Theme.of(context).primaryColor, size: 24),
                                const SizedBox(height: 8),
                                Text(
                                  '5',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Comments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.arrow_upward_rounded, size: 20),
                            label: Text('Upvote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.share_rounded, size: 20),
                            label: Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(IssueSeverity s) => s == IssueSeverity.high
      ? Colors.red
      : s == IssueSeverity.medium
      ? Colors.orange
      : Colors.green;

  IconData _severityIcon(IssueSeverity s) => s == IssueSeverity.high
      ? Icons.warning_rounded
      : s == IssueSeverity.medium
      ? Icons.info_rounded
      : Icons.check_circle_rounded;

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle_rounded;
      case 'In Progress':
        return Icons.sync_rounded;
      case 'Pending':
        return Icons.pending_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

// -------------------------------------------------------------------------
// MODELS
// -------------------------------------------------------------------------
class IssueMarker {
  final String id;
  final LatLng position;
  final String title;
  final String description;
  final String status;
  final String timeAgo;
  final IssueSeverity severity;
  final String category;
  final int upvotes;

  const IssueMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.description,
    required this.status,
    required this.timeAgo,
    required this.severity,
    required this.category,
    required this.upvotes,
  });
}

enum IssueSeverity { high, medium, low }