import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  final Set<Marker> _markers = {};
  bool _isLocationLoaded = false;
  List<Map<String, dynamic>> _nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLocationLoaded = true;
      _markers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Your Current Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition.latitude != 0.0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    }
  }

  void _showPlaceDetailsDialog(String placeType) {
    // Simulate finding nearby places (in a real app, you would use Google Places API)
    setState(() {
      _nearbyPlaces = _getMockPlaces(placeType);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nearby ${_capitalizeFirstLetter(placeType)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _nearbyPlaces.length,
              itemBuilder: (context, index) {
                final place = _nearbyPlaces[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(_getPlaceIcon(placeType), color: Colors.blue),
                    title: Text(place['name']),
                    subtitle: Text('${place['distance']} km away'),
                    trailing: IconButton(
                      icon: const Icon(Icons.directions, color: Colors.green),
                      onPressed: () => _showDirectionsDialog(place),
                    ),
                    onTap: () => _showPlaceInfoDialog(place),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showPlaceInfoDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(place['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance: ${place['distance']} km'),
              const SizedBox(height: 8),
              Text('Address: ${place['address']}'),
              const SizedBox(height: 8),
              Text('Rating: ${place['rating'] ?? 'Not available'}'),
              if (place['phone'] != null) ...[
                const SizedBox(height: 8),
                Text('Phone: ${place['phone']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Get Directions'),
              onPressed: () {
                Navigator.of(context).pop();
                _showDirectionsDialog(place);
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showDirectionsDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Directions to ${place['name']}'),
          content: const Text('How would you like to get directions?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('In-App Directions'),
              onPressed: () {
                Navigator.of(context).pop();
                _openInAppDirections(place);
              },
            ),
            TextButton(
              child: const Text('Open Google Maps'),
              onPressed: () {
                Navigator.of(context).pop();
                _launchMapsForDirections(place['lat'], place['lng']);
              },
            ),
          ],
        );
      },
    );
  }

  void _openInAppDirections(Map<String, dynamic> place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DirectionsMapPage(
          destination: LatLng(place['lat'], place['lng']),
          currentLocation: _currentPosition,
          placeName: place['name'],
          placeAddress: place['address'],
        ),
      ),
    );
  }

  Future<void> _launchMapsForDirections(double lat, double lng) async {
    final currentLat = _currentPosition.latitude;
    final currentLng = _currentPosition.longitude;
    final directionsUrl = 'https://www.google.com/maps/dir/?api=1&origin=$currentLat,$currentLng&destination=$lat,$lng&travelmode=driving';
    
    try {
      if (await canLaunchUrl(Uri.parse(directionsUrl))) {
        await launchUrl(Uri.parse(directionsUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch directions';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting directions: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getMockPlaces(String placeType) {
    // Mock data - in a real app, you would fetch this from Google Places API
    final baseLat = _currentPosition.latitude;
    final baseLng = _currentPosition.longitude;
    
    List<Map<String, dynamic>> places = [];
    
    if (placeType == 'antenatal clinics') {
      places = [
        {
          'name': 'City Antenatal Care Center',
          'address': '123 Health St, Medical District',
          'distance': 1.2,
          'rating': 4.5,
          'phone': '+1234567890',
          'lat': baseLat + 0.01,
          'lng': baseLng + 0.01,
        },
        {
          'name': 'Women\'s Pregnancy Clinic',
          'address': '456 Maternity Ave',
          'distance': 2.5,
          'rating': 4.2,
          'phone': '+1234567891',
          'lat': baseLat + 0.02,
          'lng': baseLng - 0.01,
        },
      ];
    } else if (placeType == 'hospitals') {
      places = [
        {
          'name': 'General City Hospital',
          'address': '789 Main St',
          'distance': 0.8,
          'rating': 4.1,
          'phone': '+1234567892',
          'lat': baseLat - 0.01,
          'lng': baseLng + 0.005,
        },
        {
          'name': 'Metropolitan Medical Center',
          'address': '321 Wellness Blvd',
          'distance': 3.0,
          'rating': 4.7,
          'phone': '+1234567893',
          'lat': baseLat + 0.03,
          'lng': baseLng + 0.02,
        },
      ];
    } else if (placeType == 'maternity clinics') {
      places = [
        {
          'name': 'Mother & Baby Maternity Center',
          'address': '555 Birth Rd',
          'distance': 1.8,
          'rating': 4.8,
          'phone': '+1234567894',
          'lat': baseLat + 0.015,
          'lng': baseLng - 0.005,
        },
      ];
    } else if (placeType == 'gynecologists') {
      places = [
        {
          'name': 'Dr. Smith - Women\'s Health',
          'address': '777 Specialist Lane, Suite 201',
          'distance': 0.5,
          'rating': 4.9,
          'phone': '+1234567895',
          'lat': baseLat - 0.005,
          'lng': baseLng - 0.005,
        },
        {
          'name': 'Women\'s Wellness Clinic',
          'address': '888 Care Circle',
          'distance': 2.2,
          'rating': 4.3,
          'phone': '+1234567896',
          'lat': baseLat + 0.025,
          'lng': baseLng + 0.015,
        },
      ];
    }
    
    return places;
  }

  IconData _getPlaceIcon(String placeType) {
    switch (placeType) {
      case 'antenatal clinics':
        return Icons.pregnant_woman;
      case 'hospitals':
        return Icons.local_hospital;
      case 'maternity clinics':
        return Icons.child_care;
      case 'gynecologists':
        return Icons.person;
      default:
        return Icons.place;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSearchOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Find Healthcare Facilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.pregnant_woman, color: Colors.pink),
                title: const Text('Antenatal Clinics'),
                subtitle: const Text('Find specialized pregnancy care'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceDetailsDialog('antenatal clinics');
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.red),
                title: const Text('Hospitals'),
                subtitle: const Text('Find nearby hospitals'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceDetailsDialog('hospitals');
                },
              ),
              ListTile(
                leading: const Icon(Icons.child_care, color: Colors.purple),
                title: const Text('Maternity Clinics'),
                subtitle: const Text('Find maternity care centers'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceDetailsDialog('maternity clinics');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.teal),
                title: const Text('Gynecologists'),
                subtitle: const Text('Find women\'s health specialists'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceDetailsDialog('gynecologists');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Of PregMama'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchOptions,
            tooltip: 'Search Healthcare Facilities',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_mapController != null && _isLocationLoaded) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition, 15),
                );
              } else {
                _determinePosition();
              }
            },
            tooltip: 'Go to My Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 5,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (!_isLocationLoaded)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isLocationLoaded
          ? FloatingActionButton.extended(
              onPressed: _showSearchOptions,
              label: const Text('Find Clinics'),
              icon: const Icon(Icons.search),
              backgroundColor: Colors.pink,
            )
          : null,
    );
  }
}

// New DirectionsMapPage class for in-app directions
class DirectionsMapPage extends StatefulWidget {
  final LatLng destination;
  final LatLng currentLocation;
  final String placeName;
  final String placeAddress;

  const DirectionsMapPage({
    Key? key,
    required this.destination,
    required this.currentLocation,
    required this.placeName,
    required this.placeAddress,
  }) : super(key: key);

  @override
  _DirectionsMapPageState createState() => _DirectionsMapPageState();
}

class _DirectionsMapPageState extends State<DirectionsMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double _distance = 0.0;
  String _duration = '';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Add markers for current location and destination
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(
          title: widget.placeName,
          snippet: widget.placeAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Calculate distance
    _distance = Geolocator.distanceBetween(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
      widget.destination.latitude,
      widget.destination.longitude,
    ) / 1000; // Convert to kilometers

    // Estimate duration (assuming average speed of 40 km/h in city)
    double estimatedHours = _distance / 40;
    int minutes = (estimatedHours * 60).round();
    _duration = minutes < 60 ? '$minutes min' : '${(minutes / 60).toStringAsFixed(1)} hr';

    // Create a simple polyline (straight line for demo)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [widget.currentLocation, widget.destination],
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Fit the map to show both markers
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.currentLocation.latitude < widget.destination.latitude
            ? widget.currentLocation.latitude
            : widget.destination.latitude,
        widget.currentLocation.longitude < widget.destination.longitude
            ? widget.currentLocation.longitude
            : widget.destination.longitude,
      ),
      northeast: LatLng(
        widget.currentLocation.latitude > widget.destination.latitude
            ? widget.currentLocation.latitude
            : widget.destination.latitude,
        widget.currentLocation.longitude > widget.destination.longitude
            ? widget.currentLocation.longitude
            : widget.destination.longitude,
      ),
    );
    
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _startNavigation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Navigation'),
          content: const Text('This would start turn-by-turn navigation. In a real app, you would integrate with a navigation service.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _startNavigation,
            tooltip: 'Start Navigation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Route info card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.placeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_distance.toStringAsFixed(1)} km • $_duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _startNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('START'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Map
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              mapType: MapType.normal,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Recenter on current location
                if (_mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(widget.currentLocation, 15),
                  );
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('My Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Recenter on destination
                if (_mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(widget.destination, 15),
                  );
                }
              },
              icon: const Icon(Icons.place),
              label: const Text('Destination'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}