import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/currency_service.dart';
import 'payment_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String selectedCarType = 'Standard';
  final MapController _mapController = MapController();
  LatLng? _currentLocation; // State variable for current location
  final List<Marker> _markers = []; // List to hold markers
  final TextEditingController _currentLocationController = TextEditingController(); // Controller for the text field
  final TextEditingController _whereToController = TextEditingController(); // Controller for 'Where to?'
  List<LatLng> _routePoints = []; // List to hold route points
  LatLng? _destinationLocation; // Store destination location

  // Define initial position using LatLng from latlong2
  static const LatLng _initialPosition = LatLng(33.5731, -7.5898); // Casablanca, Morocco

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get location when the screen initializes
  }

  @override
  void dispose() {
    _currentLocationController.dispose();
    _whereToController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Method to get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _currentLocationController.text = 'Location services disabled';
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _currentLocationController.text = 'Location permissions denied';
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever. Handle appropriately.
      _currentLocationController.text = 'Location permissions permanently denied';
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      // Add a marker at the current location
      _markers.clear(); // Clear previous markers
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue, // Use a different color for current location
            size: 40,
          ),
        ),
      );
      // Optionally move the map to the current location
      _mapController.move(_currentLocation!, _mapController.camera.zoom);
    });

    try {
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          localeIdentifier: 'en_US' // Optional: specify locale
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format the address to show street, city, and country
        String address = "${place.street}, ${place.locality}, ${place.country}";
        _currentLocationController.text = address;
      } else {
        _currentLocationController.text = 'Address not found for this location'; // More specific message
      }
    } catch (e) {
      // Handle error getting address
      print('Error getting address: \$e'); // Print the actual error
      _currentLocationController.text = 'Could not get address: ${e.toString()}'; // Show error in text field
    }
  }

  // دالة لجلب المسار من OSRM
  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  Future<void> _goToCity() async {
    String city = _whereToController.text.trim();
    if (city.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(city);
      if (locations.isNotEmpty) {
        final loc = locations[0];
        LatLng cityLatLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _destinationLocation = cityLatLng;
          _mapController.move(cityLatLng, 12.0);
        });
        // جلب المسار من OSRM
        if (_currentLocation != null) {
          try {
            final route = await _fetchRoute(_currentLocation!, cityLatLng);
            if (route.isNotEmpty) {
              setState(() {
                _routePoints = route;
              });
            } else {
              // إذا لم يتم جلب مسار، ارسم خط مستقيم
              setState(() {
                _routePoints = [_currentLocation!, cityLatLng];
              });
            }
          } catch (e) {
            print('OSRM error: ' + e.toString());
            // إذا حدث خطأ، ارسم خط مستقيم
            setState(() {
              _routePoints = [_currentLocation!, cityLatLng];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذر جلب مسار الطريق، تم رسم خط مستقيم')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على المدينة. جرب كتابة اسم المدينة مع الدولة (مثال: Casablanca, Morocco)')),
        );
      }
    } catch (e) {
      print('Geocoding error: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء البحث عن المكان')),
      );
    }
  }

  void _requestRide() {
    final l10n = AppLocalizations.of(context)!;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationServicesDisabled)),
      );
      return;
    }

    if (_destinationLocation == null || _whereToController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.whereTo)),
      );
      return;
    }

    // Calculate distance and fare
    final distance = _calculateDistance(_currentLocation!, _destinationLocation!);
    final baseFare = CurrencyService.calculateFare(distance, selectedCarType);

    // Create trip object
    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: 'current_user', // In real app, get from auth
      pickupLocation: _currentLocation!,
      destination: _destinationLocation!,
      pickupAddress: _currentLocationController.text,
      destinationAddress: _whereToController.text,
      carType: selectedCarType,
      fare: baseFare,
      distance: distance,
      estimatedDuration: (distance * 2).round(), // Rough estimate: 2 minutes per km
      paymentMethod: PaymentMethod.cash, // Default, will be selected in payment screen
      status: RideStatus.requested,
      createdAt: DateTime.now(),
    );

    // Navigate to payment screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(trip: trip),
      ),
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Simple distance calculation (in km)
    const double earthRadius = 6371; // Earth's radius in km

    double lat1Rad = start.latitude * (pi / 180);
    double lat2Rad = end.latitude * (pi / 180);
    double deltaLatRad = (end.latitude - start.latitude) * (pi / 180);
    double deltaLngRad = (end.longitude - start.longitude) * (pi / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Use FlutterMap widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _initialPosition, // Use current location if available
              initialZoom: 12.0,
              // minZoom: 3.0, // Optional: set min zoom
              // maxZoom: 18.0, // Optional: set max zoom
            ),
            children: [
              // Add TileLayer for OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yourcompany.waygo', // Replace with your package name
              ),
              // Add MarkerLayer to display markers
              MarkerLayer(
                markers: _markers,
              ),
              // رسم المسار بين الموقع الحالي والوجهة
              PolylineLayer(
                polylines: [
                  if (_routePoints.length >= 2)
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _currentLocationController, // Assign the controller
                      decoration: InputDecoration(
                        hintText: l10n.currentLocation,
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      readOnly: true, // Make the field read-only
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _whereToController,
                      decoration: InputDecoration(
                        hintText: l10n.whereTo,
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _goToCity,
                        ),
                      ),
                      onSubmitted: (_) => _goToCity(),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCarTypeOption(l10n.standard, Icons.car_rental),
                          _buildCarTypeOption(l10n.premium, Icons.car_crash),
                          _buildCarTypeOption(l10n.van, Icons.airport_shuttle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.estimatedArrival,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.attach_money, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.estimatedFare,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestRide,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.requestRide),
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

  Widget _buildCarTypeOption(String type, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(type),
          ],
        ),
        selected: selectedCarType == type,
        onSelected: (selected) {
          setState(() {
            selectedCarType = type;
          });
        },
      ),
    );
  }
}
