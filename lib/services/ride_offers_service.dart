import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_offer.dart';
import '../models/trip.dart';
import 'currency_service.dart';

class RideOffersService extends ChangeNotifier {
  final List<RideOffer> _availableOffers = [];
  final List<RideOffer> _acceptedOffers = [];
  Timer? _offerGenerationTimer;
  Timer? _expiryCheckTimer;
  
  List<RideOffer> get availableOffers => _availableOffers.where((offer) => offer.isPending).toList();
  List<RideOffer> get acceptedOffers => _acceptedOffers;
  List<RideOffer> get allOffers => [..._availableOffers, ..._acceptedOffers];
  
  // Mock locations in Casablanca area
  final List<Map<String, dynamic>> _mockLocations = [
    {
      'name': 'Hassan II Mosque',
      'location': LatLng(33.6084, -7.6326),
    },
    {
      'name': 'Mohammed V Airport',
      'location': LatLng(33.3675, -7.5898),
    },
    {
      'name': 'Casa Port Train Station',
      'location': LatLng(33.5969, -7.6192),
    },
    {
      'name': 'Morocco Mall',
      'location': LatLng(33.5731, -7.6617),
    },
    {
      'name': 'Ain Diab Beach',
      'location': LatLng(33.5731, -7.6617),
    },
    {
      'name': 'Twin Center',
      'location': LatLng(33.5886, -7.6247),
    },
    {
      'name': 'Anfa Place',
      'location': LatLng(33.5886, -7.6247),
    },
    {
      'name': 'Corniche',
      'location': LatLng(33.5731, -7.6617),
    },
  ];
  
  final List<String> _mockNames = [
    'Ahmed Hassan',
    'Fatima Zahra',
    'Mohamed Alami',
    'Aicha Benali',
    'Youssef Tazi',
    'Khadija Mansouri',
    'Omar Benjelloun',
    'Salma Idrissi',
    'Rachid Berrada',
    'Nadia Chraibi',
  ];
  
  void startGeneratingOffers() {
    _generateInitialOffers();
    _startOfferGeneration();
    _startExpiryCheck();
  }
  
  void _generateInitialOffers() {
    // Generate 2-3 initial offers
    final random = Random();
    final offerCount = 2 + random.nextInt(2); // 2-3 offers
    
    for (int i = 0; i < offerCount; i++) {
      _generateRandomOffer();
    }
    notifyListeners();
  }
  
  void _startOfferGeneration() {
    _offerGenerationTimer?.cancel();
    _offerGenerationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // Generate new offer every 15-30 seconds
      final random = Random();
      if (random.nextBool() && _availableOffers.length < 5) {
        _generateRandomOffer();
        notifyListeners();
      }
    });
  }
  
  void _startExpiryCheck() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      bool hasExpired = false;
      
      for (int i = _availableOffers.length - 1; i >= 0; i--) {
        if (_availableOffers[i].isExpired) {
          _availableOffers[i] = _availableOffers[i].copyWith(
            status: RideOfferStatus.expired,
          );
          _availableOffers.removeAt(i);
          hasExpired = true;
        }
      }
      
      if (hasExpired) {
        notifyListeners();
      }
    });
  }
  
  void _generateRandomOffer() {
    final random = Random();
    final pickupLocation = _mockLocations[random.nextInt(_mockLocations.length)];
    final dropoffLocation = _mockLocations[random.nextInt(_mockLocations.length)];
    
    // Ensure pickup and dropoff are different
    if (pickupLocation['name'] == dropoffLocation['name']) {
      return _generateRandomOffer();
    }
    
    final distance = _calculateDistance(
      pickupLocation['location'],
      dropoffLocation['location'],
    );
    
    final estimatedDuration = (distance * 2.5).round(); // ~2.5 min per km
    final timeToPickup = 3 + random.nextInt(12); // 3-15 minutes
    
    // Calculate pricing in MAD
    final basePrice = CurrencyService.calculateFare(distance, _getRandomCarType());
    final surgeMultiplier = _getSurgeMultiplier();
    final bonusEarnings = _getBonusEarnings();
    final totalEarnings = CurrencyService.generateOfferAmount(basePrice, surgeMultiplier, bonusEarnings);
    
    final priority = _getPriority(surgeMultiplier, bonusEarnings);
    
    final passenger = PassengerInfo(
      id: 'passenger_${DateTime.now().millisecondsSinceEpoch}',
      name: _mockNames[random.nextInt(_mockNames.length)],
      phoneNumber: '+212 6 ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10} ${random.nextInt(90) + 10}',
      rating: 3.5 + (random.nextDouble() * 1.5), // 3.5-5.0 rating
    );
    
    final offer = RideOffer(
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      customerId: passenger.id,
      passengerInfo: passenger,
      pickupLocation: pickupLocation['location'],
      dropoffLocation: dropoffLocation['location'],
      pickupAddress: pickupLocation['name'],
      dropoffAddress: dropoffLocation['name'],
      carType: _getRandomCarType(),
      distance: distance,
      estimatedDuration: estimatedDuration,
      basePrice: basePrice,
      surgeMultiplier: surgeMultiplier,
      totalEarnings: totalEarnings,
      bonusEarnings: bonusEarnings,
      priority: priority,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 2)), // 2 minutes to accept
      timeToPickup: timeToPickup,
    );
    
    _availableOffers.add(offer);
  }
  
  double _calculateDistance(LatLng start, LatLng end) {
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
  
  double _getSurgeMultiplier() {
    final random = Random();
    final chance = random.nextDouble();
    
    if (chance < 0.7) return 1.0; // 70% normal pricing
    if (chance < 0.9) return 1.2 + (random.nextDouble() * 0.3); // 20% low surge (1.2-1.5x)
    return 1.5 + (random.nextDouble() * 1.0); // 10% high surge (1.5-2.5x)
  }
  
  double _getBonusEarnings() {
    final random = Random();
    final chance = random.nextDouble();

    if (chance < 0.8) return 0.0; // 80% no bonus
    return 20.0 + (random.nextDouble() * 80.0); // 20% bonus (20-100 DH)
  }
  
  RideOfferPriority _getPriority(double surge, double bonus) {
    if (surge >= 2.0 || bonus >= 50.0) return RideOfferPriority.high; // 50+ DH bonus
    if (surge >= 1.3 || bonus >= 20.0) return RideOfferPriority.medium; // 20+ DH bonus
    return RideOfferPriority.low;
  }
  
  String _getRandomCarType() {
    final types = ['Standard', 'Premium', 'Van'];
    return types[Random().nextInt(types.length)];
  }
  
  // Accept a ride offer
  Future<bool> acceptOffer(String offerId) async {
    final offerIndex = _availableOffers.indexWhere((offer) => offer.id == offerId);
    if (offerIndex == -1) return false;
    
    final offer = _availableOffers[offerIndex];
    if (!offer.isPending) return false;
    
    // Update offer status
    final acceptedOffer = offer.copyWith(
      status: RideOfferStatus.accepted,
      acceptedAt: DateTime.now(),
    );
    
    _availableOffers.removeAt(offerIndex);
    _acceptedOffers.add(acceptedOffer);
    
    notifyListeners();
    return true;
  }
  
  // Decline a ride offer
  Future<bool> declineOffer(String offerId) async {
    final offerIndex = _availableOffers.indexWhere((offer) => offer.id == offerId);
    if (offerIndex == -1) return false;
    
    final offer = _availableOffers[offerIndex];
    if (!offer.isPending) return false;
    
    // Update offer status
    final declinedOffer = offer.copyWith(
      status: RideOfferStatus.declined,
      declinedAt: DateTime.now(),
    );
    
    _availableOffers.removeAt(offerIndex);
    
    notifyListeners();
    return true;
  }
  
  // Get offer by ID
  RideOffer? getOfferById(String offerId) {
    try {
      return allOffers.firstWhere((offer) => offer.id == offerId);
    } catch (e) {
      return null;
    }
  }
  
  // Convert accepted offer to Trip for ride simulation
  Trip? convertOfferToTrip(String offerId) {
    final offer = _acceptedOffers.where((o) => o.id == offerId).firstOrNull;
    if (offer == null) return null;
    
    return Trip(
      id: 'trip_${offer.id}',
      customerId: offer.customerId,
      pickupLocation: offer.pickupLocation,
      destination: offer.dropoffLocation,
      pickupAddress: offer.pickupAddress,
      destinationAddress: offer.dropoffAddress,
      carType: offer.carType,
      fare: offer.totalEarnings,
      distance: offer.distance,
      estimatedDuration: offer.estimatedDuration,
      paymentMethod: PaymentMethod.cash, // Default
      status: RideStatus.driverFound,
      createdAt: offer.createdAt,
      driver: Driver(
        id: 'current_driver',
        name: 'You',
        phoneNumber: '+212 6 12 34 56 78',
        rating: 4.8,
        profileImage: '',
        vehicle: Vehicle(
          licensePlate: 'A 123456',
          model: 'Toyota Corolla',
          color: 'White',
          type: offer.carType,
        ),
      ),
    );
  }
  
  void stopGeneratingOffers() {
    _offerGenerationTimer?.cancel();
    _expiryCheckTimer?.cancel();
  }
  
  @override
  void dispose() {
    stopGeneratingOffers();
    super.dispose();
  }
}
