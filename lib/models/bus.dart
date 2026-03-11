class BusStop {
  final String name;
  final double lat;
  final double lng;

  BusStop({required this.name, required this.lat, required this.lng});

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      name: json['name'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class BusRoute {
  final int id;
  final String name;
  final String description;
  final List<BusStop> stops;
  final bool isActive;

  BusRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    required this.isActive,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((s) => BusStop.fromJson(s))
              .toList() ??
          [],
      isActive: json['is_active'] ?? true,
    );
  }
}

class BusLocationUpdate {
  final int id;
  final double latitude;
  final double longitude;
  final String currentStop;
  final String nextStop;
  final String status;
  final String occupancy;
  final String timestamp;
  final String? driverEmail;

  BusLocationUpdate({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.currentStop,
    required this.nextStop,
    required this.status,
    required this.occupancy,
    required this.timestamp,
    this.driverEmail,
  });

  factory BusLocationUpdate.fromJson(Map<String, dynamic> json) {
    return BusLocationUpdate(
      id: json['id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      currentStop: json['current_stop'] ?? '',
      nextStop: json['next_stop'] ?? '',
      status: json['status'] ?? 'off_duty',
      occupancy: json['occupancy'] ?? 'empty',
      timestamp: json['timestamp'] ?? '',
      driverEmail: json['driver_email'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'on_route':
        return 'On Route';
      case 'at_stop':
        return 'At Stop';
      case 'waiting':
        return 'Waiting';
      case 'off_duty':
        return 'Off Duty';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String get occupancyLabel {
    switch (occupancy) {
      case 'empty':
        return 'Empty';
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'full':
        return 'Full';
      default:
        return occupancy;
    }
  }
}

class Bus {
  final int id;
  final String busNumber;
  final BusRoute? route;
  final String? driverEmail;
  final int capacity;
  final bool isActive;
  final BusLocationUpdate? latestLocation;

  Bus({
    required this.id,
    required this.busNumber,
    this.route,
    this.driverEmail,
    required this.capacity,
    required this.isActive,
    this.latestLocation,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      busNumber: json['bus_number'] ?? '',
      route: json['route'] != null ? BusRoute.fromJson(json['route']) : null,
      driverEmail: json['driver_email'],
      capacity: json['capacity'] ?? 40,
      isActive: json['is_active'] ?? false,
      latestLocation: json['latest_location'] != null
          ? BusLocationUpdate.fromJson(json['latest_location'])
          : null,
    );
  }

  String get timeAgo {
    if (latestLocation == null) return 'No updates';
    try {
      final dt = DateTime.parse(latestLocation!.timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}
