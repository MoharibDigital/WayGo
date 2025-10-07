import 'package:latlong2/latlong.dart';
import '../services/currency_service.dart';

enum RideOfferStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled
}

enum RideOfferPriority {
  low,
  medium,
  high
}

class PassengerInfo {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final String? profileImage;

  PassengerInfo({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    this.profileImage,
  });

  factory PassengerInfo.fromMap(Map<String, dynamic> map) {
    return PassengerInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      profileImage: map['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'rating': rating,
      'profileImage': profileImage,
    };
  }
}

class RideOffer {
  final String id;
  final String customerId;
  final PassengerInfo passengerInfo;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final String carType;
  final double distance;
  final int estimatedDuration;
  final double basePrice;
  final double surgeMultiplier;
  final double totalEarnings;
  final double bonusEarnings;
  final RideOfferStatus status;
  final RideOfferPriority priority;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final int timeToPickup; // in minutes
  final Map<String, dynamic>? metadata;

  RideOffer({
    required this.id,
    required this.customerId,
    required this.passengerInfo,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.carType,
    required this.distance,
    required this.estimatedDuration,
    required this.basePrice,
    this.surgeMultiplier = 1.0,
    required this.totalEarnings,
    this.bonusEarnings = 0.0,
    this.status = RideOfferStatus.pending,
    this.priority = RideOfferPriority.medium,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.declinedAt,
    required this.timeToPickup,
    this.metadata,
  });

  factory RideOffer.fromMap(Map<String, dynamic> map) {
    return RideOffer(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      passengerInfo: PassengerInfo.fromMap(map['passengerInfo'] ?? {}),
      pickupLocation: LatLng(
        map['pickupLocation']['latitude'] ?? 0.0,
        map['pickupLocation']['longitude'] ?? 0.0,
      ),
      dropoffLocation: LatLng(
        map['dropoffLocation']['latitude'] ?? 0.0,
        map['dropoffLocation']['longitude'] ?? 0.0,
      ),
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      carType: map['carType'] ?? '',
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      surgeMultiplier: (map['surgeMultiplier'] ?? 1.0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      bonusEarnings: (map['bonusEarnings'] ?? 0.0).toDouble(),
      status: RideOfferStatus.values.firstWhere(
        (e) => e.toString() == 'RideOfferStatus.${map['status']}',
        orElse: () => RideOfferStatus.pending,
      ),
      priority: RideOfferPriority.values.firstWhere(
        (e) => e.toString() == 'RideOfferPriority.${map['priority']}',
        orElse: () => RideOfferPriority.medium,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      acceptedAt: map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      declinedAt: map['declinedAt'] != null ? DateTime.parse(map['declinedAt']) : null,
      timeToPickup: map['timeToPickup'] ?? 0,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'passengerInfo': passengerInfo.toMap(),
      'pickupLocation': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'latitude': dropoffLocation.latitude,
        'longitude': dropoffLocation.longitude,
      },
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'carType': carType,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'basePrice': basePrice,
      'surgeMultiplier': surgeMultiplier,
      'totalEarnings': totalEarnings,
      'bonusEarnings': bonusEarnings,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'declinedAt': declinedAt?.toIso8601String(),
      'timeToPickup': timeToPickup,
      'metadata': metadata,
    };
  }

  RideOffer copyWith({
    String? id,
    String? customerId,
    PassengerInfo? passengerInfo,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    String? pickupAddress,
    String? dropoffAddress,
    String? carType,
    double? distance,
    int? estimatedDuration,
    double? basePrice,
    double? surgeMultiplier,
    double? totalEarnings,
    double? bonusEarnings,
    RideOfferStatus? status,
    RideOfferPriority? priority,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    int? timeToPickup,
    Map<String, dynamic>? metadata,
  }) {
    return RideOffer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      passengerInfo: passengerInfo ?? this.passengerInfo,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      carType: carType ?? this.carType,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      basePrice: basePrice ?? this.basePrice,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      bonusEarnings: bonusEarnings ?? this.bonusEarnings,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      timeToPickup: timeToPickup ?? this.timeToPickup,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == RideOfferStatus.pending && !isExpired;
  bool get isAccepted => status == RideOfferStatus.accepted;
  bool get isDeclined => status == RideOfferStatus.declined;
  bool get hasSurge => surgeMultiplier > 1.0;
  bool get hasBonus => bonusEarnings > 0;
  
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedDuration => '${estimatedDuration} min';
  String get formattedEarnings => CurrencyService.formatAmount(totalEarnings);
  String get formattedTimeToPickup => '${timeToPickup} min';
  String get formattedBasePrice => CurrencyService.formatAmount(basePrice);
  String get formattedBonusEarnings => CurrencyService.formatAmount(bonusEarnings);
}
