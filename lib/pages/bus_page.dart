import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus.dart';
import '../services/bus_service.dart';
import '../services/auth_service.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  String? _userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final type = await AuthService.getCurrentUserType();
    if (mounted) {
      setState(() {
        _userType = type;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A1538)),
          ),
        ),
      );
    }

    if (_userType == 'bus_driver') {
      return const _DriverDashboard();
    }
    return const _StudentBusView();
  }
}

// ═══════════════════════════════════════════════════════════
// STUDENT VIEW — Map + active bus list
// ═══════════════════════════════════════════════════════════

class _StudentBusView extends StatefulWidget {
  const _StudentBusView();

  @override
  State<_StudentBusView> createState() => _StudentBusViewState();
}

class _StudentBusViewState extends State<_StudentBusView> {
  static const Color primaryMaroon = Color(0xFF8A1538);
  static const LatLng _quCenter = LatLng(25.3770, 51.4870);

  List<Bus> _activeBuses = [];
  List<BusRoute> _routes = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final buses = await BusService.getActiveBuses();
    final routes = await BusService.getRoutes();
    if (mounted) {
      setState(() {
        _activeBuses = buses;
        _routes = routes;
        _isLoading = false;
      });
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final colors = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
    ];

    for (int i = 0; i < _activeBuses.length; i++) {
      final bus = _activeBuses[i];
      if (bus.latestLocation != null) {
        markers.add(Marker(
          markerId: MarkerId('bus_${bus.id}'),
          position: LatLng(
            bus.latestLocation!.latitude,
            bus.latestLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(colors[i % colors.length]),
          infoWindow: InfoWindow(
            title: bus.busNumber,
            snippet: '${bus.latestLocation!.statusLabel} • ${bus.latestLocation!.occupancyLabel}',
          ),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        backgroundColor: primaryMaroon,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryMaroon),
              ),
            )
          : Column(
              children: [
                // Map
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _quCenter,
                      zoom: 15.5,
                    ),
                    markers: _buildMarkers(),
                    myLocationEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),

                // Active buses header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: primaryMaroon),
                      const SizedBox(width: 8),
                      Text(
                        'Active Buses (${_activeBuses.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _activeBuses.isNotEmpty ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _activeBuses.isNotEmpty ? 'Live' : 'No buses',
                        style: TextStyle(
                          fontSize: 12,
                          color: _activeBuses.isNotEmpty ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bus list
                Expanded(
                  child: _activeBuses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No active buses right now',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Buses will appear here when drivers start their trips',
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _activeBuses.length,
                            itemBuilder: (context, index) {
                              return _BusCard(
                                bus: _activeBuses[index],
                                onTap: () => _showBusDetail(_activeBuses[index]),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showBusDetail(Bus bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BusDetailSheet(bus: bus),
    );
  }
}

class _BusCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;

  const _BusCard({required this.bus, required this.onTap});

  Color _occupancyColor(String occupancy) {
    switch (occupancy) {
      case 'empty':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'full':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = bus.latestLocation;
    const primaryMaroon = Color(0xFF8A1538);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Bus icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_bus, color: primaryMaroon, size: 28),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bus.busNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (loc != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _occupancyColor(loc.occupancy).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loc.occupancyLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _occupancyColor(loc.occupancy),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (bus.route != null)
                      Text(
                        bus.route!.name,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    if (loc != null && loc.currentStop.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                loc.nextStop.isNotEmpty
                                    ? '${loc.currentStop} → ${loc.nextStop}'
                                    : loc.currentStop,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Status + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (loc != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: loc.status == 'on_route'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: loc.status == 'on_route' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    bus.timeAgo,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusDetailSheet extends StatelessWidget {
  final Bus bus;
  const _BusDetailSheet({required this.bus});

  @override
  Widget build(BuildContext context) {
    const primaryMaroon = Color(0xFF8A1538);
    final route = bus.route;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bus header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryMaroon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus, color: primaryMaroon, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.busNumber,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (route != null)
                          Text(route.name, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Route stops
              if (route != null && route.stops.isNotEmpty) ...[
                const Text(
                  'Route Stops',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...route.stops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stop = entry.value;
                  final isCurrentStop = bus.latestLocation != null &&
                      bus.latestLocation!.currentStop == stop.name;
                  final isNextStop = bus.latestLocation != null &&
                      bus.latestLocation!.nextStop == stop.name;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Timeline dot
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCurrentStop
                                    ? primaryMaroon
                                    : isNextStop
                                        ? Colors.orange
                                        : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCurrentStop
                                    ? const Icon(Icons.directions_bus, size: 14, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isNextStop ? Colors.white : Colors.grey[600],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentStop || isNextStop
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentStop
                                  ? primaryMaroon
                                  : isNextStop
                                      ? Colors.orange[800]
                                      : null,
                            ),
                          ),
                        ),
                        if (isCurrentStop)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryMaroon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HERE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryMaroon,
                              ),
                            ),
                          ),
                        if (isNextStop)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEXT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DRIVER DASHBOARD — Update status, start/end trips
// ═══════════════════════════════════════════════════════════

class _DriverDashboard extends StatefulWidget {
  const _DriverDashboard();

  @override
  State<_DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<_DriverDashboard> {
  static const Color primaryMaroon = Color(0xFF8A1538);

  Bus? _myBus;
  bool _isLoading = true;
  bool _isTripActive = false;
  String _selectedStatus = 'on_route';
  String _selectedOccupancy = 'empty';
  String _currentStop = '';
  String _nextStop = '';
  Timer? _autoUpdateTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMyBus();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMyBus() async {
    final bus = await BusService.getMyBus();
    if (mounted) {
      setState(() {
        _myBus = bus;
        _isTripActive = bus?.isActive ?? false;
        _isLoading = false;
        if (bus?.latestLocation != null) {
          _selectedStatus = bus!.latestLocation!.status;
          _selectedOccupancy = bus.latestLocation!.occupancy;
          _currentStop = bus.latestLocation!.currentStop;
          _nextStop = bus.latestLocation!.nextStop;
        } else if (bus?.route != null && bus!.route!.stops.isNotEmpty) {
          _currentStop = bus.route!.stops.first.name;
          if (bus.route!.stops.length > 1) {
            _nextStop = bus.route!.stops[1].name;
          }
        }
      });
      if (_isTripActive) {
        _startAutoUpdate();
      }
    }
  }

  void _startAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendLocationUpdate();
    });
  }

  void _stopAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
  }

  Future<void> _toggleTrip() async {
    if (_isTripActive) {
      final result = await BusService.endTrip();
      if (result['success'] == true) {
        _stopAutoUpdate();
        setState(() => _isTripActive = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip ended.'), backgroundColor: Colors.orange),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      final result = await BusService.startTrip();
      if (result['success'] == true) {
        _startAutoUpdate();
        setState(() => _isTripActive = true);
        _sendLocationUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip started!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    }
    _loadMyBus();
  }

  Future<void> _sendLocationUpdate() async {
    if (_isSending || _myBus == null) return;
    setState(() => _isSending = true);

    // Use route stop coordinates as fallback location
    double lat = 25.3770;
    double lng = 51.4870;

    if (_myBus!.route != null) {
      final stopMatch = _myBus!.route!.stops.where((s) => s.name == _currentStop);
      if (stopMatch.isNotEmpty) {
        lat = stopMatch.first.lat;
        lng = stopMatch.first.lng;
      }
    }

    final success = await BusService.updateLocation(
      latitude: lat,
      longitude: lng,
      currentStop: _currentStop,
      nextStop: _nextStop,
      status: _selectedStatus,
      occupancy: _selectedOccupancy,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: primaryMaroon,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMyBus),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryMaroon),
              ),
            )
          : _myBus == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bus_alert, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No Bus Assigned',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact an administrator to assign a bus to your account.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // My Bus card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryMaroon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.directions_bus,
                                        color: primaryMaroon, size: 36),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _myBus!.busNumber,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_myBus!.route != null)
                                          Text(
                                            _myBus!.route!.name,
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        Text(
                                          'Capacity: ${_myBus!.capacity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Trip status indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _isTripActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _isTripActive ? Colors.green : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isTripActive ? 'Active' : 'Off Duty',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _isTripActive ? Colors.green : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Start / End trip button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _toggleTrip,
                                  icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
                                  label: Text(
                                    _isTripActive ? 'End Trip' : 'Start Trip',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isTripActive ? Colors.red : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Controls (only when trip active)
                      if (_isTripActive) ...[
                        // Status selector
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _statusChip('on_route', 'On Route', Icons.route),
                                    _statusChip(
                                        'at_stop', 'At Stop', Icons.location_on),
                                    _statusChip(
                                        'waiting', 'Waiting', Icons.hourglass_empty),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Occupancy selector
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Occupancy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _occupancyChip('empty', 'Empty', Colors.green),
                                    _occupancyChip('low', 'Low', Colors.lightGreen),
                                    _occupancyChip('medium', 'Medium', Colors.orange),
                                    _occupancyChip(
                                        'high', 'High', Colors.deepOrange),
                                    _occupancyChip('full', 'Full', Colors.red),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Current / Next stop
                        if (_myBus!.route != null) ...[
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stops',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _myBus!.route!.stops
                                            .any((s) => s.name == _currentStop)
                                        ? _currentStop
                                        : _myBus!.route!.stops.first.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Current Stop',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: _myBus!.route!.stops.map((stop) {
                                      return DropdownMenuItem(
                                        value: stop.name,
                                        child: Text(stop.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _currentStop = val;
                                          // Auto-advance next stop
                                          final stops = _myBus!.route!.stops;
                                          final idx = stops
                                              .indexWhere((s) => s.name == val);
                                          if (idx >= 0 &&
                                              idx < stops.length - 1) {
                                            _nextStop = stops[idx + 1].name;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _myBus!.route!.stops
                                            .any((s) => s.name == _nextStop)
                                        ? _nextStop
                                        : (_myBus!.route!.stops.length > 1
                                            ? _myBus!.route!.stops[1].name
                                            : _myBus!.route!.stops.first.name),
                                    decoration: const InputDecoration(
                                      labelText: 'Next Stop',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: _myBus!.route!.stops.map((stop) {
                                      return DropdownMenuItem(
                                        value: stop.name,
                                        child: Text(stop.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _nextStop = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Send update button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendLocationUpdate,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _isSending ? 'Sending...' : 'Send Update Now',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Auto-updates every 30 seconds while trip is active',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _statusChip(String value, String label, IconData icon) {
    final selected = _selectedStatus == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : primaryMaroon),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      selectedColor: primaryMaroon,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
      onSelected: (sel) {
        if (sel) setState(() => _selectedStatus = value);
      },
    );
  }

  Widget _occupancyChip(String value, String label, Color color) {
    final selected = _selectedOccupancy == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (sel) {
        if (sel) setState(() => _selectedOccupancy = value);
      },
    );
  }
}
