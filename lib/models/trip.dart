import 'package:latlong2/latlong.dart';
import '../services/currency_service.dart';

enum RideStatus {
  requested,
  findingDriver,
  driverFound,
  driverOnWay,
  driverArrived,
  inProgress,
  completed,
  cancelled
}

enum PaymentMethod {
  creditCard,
  paypal,
  applePay,
  googlePay,
  cash
}

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final String profileImage;
  final Vehicle vehicle;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.profileImage,
    required this.vehicle,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      profileImage: map['profileImage'] ?? '',
      vehicle: Vehicle.fromMap(map['vehicle'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'rating': rating,
      'profileImage': profileImage,
      'vehicle': vehicle.toMap(),
    };
  }
}

class Vehicle {
  final String licensePlate;
  final String model;
  final String color;
  final String type;

  Vehicle({
    required this.licensePlate,
    required this.model,
    required this.color,
    required this.type,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      licensePlate: map['licensePlate'] ?? '',
      model: map['model'] ?? '',
      color: map['color'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licensePlate': licensePlate,
      'model': model,
      'color': color,
      'type': type,
    };
  }
}

class Trip {
  final String id;
  final String customerId;
  final LatLng pickupLocation;
  final LatLng destination;
  final String pickupAddress;
  final String destinationAddress;
  final String carType;
  final double fare;
  final double distance;
  final int estimatedDuration;
  final PaymentMethod paymentMethod;
  final RideStatus status;
  final Driver? driver;
  final DateTime createdAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.customerId,
    required this.pickupLocation,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.carType,
    required this.fare,
    required this.distance,
    required this.estimatedDuration,
    required this.paymentMethod,
    required this.status,
    this.driver,
    required this.createdAt,
    this.completedAt,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      pickupLocation: LatLng(
        map['pickupLocation']['latitude'] ?? 0.0,
        map['pickupLocation']['longitude'] ?? 0.0,
      ),
      destination: LatLng(
        map['destination']['latitude'] ?? 0.0,
        map['destination']['longitude'] ?? 0.0,
      ),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      carType: map['carType'] ?? '',
      fare: (map['fare'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
        orElse: () => PaymentMethod.cash,
      ),
      status: RideStatus.values.firstWhere(
        (e) => e.toString() == 'RideStatus.${map['status']}',
        orElse: () => RideStatus.requested,
      ),
      driver: map['driver'] != null ? Driver.fromMap(map['driver']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'pickupLocation': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
      },
      'destination': {
        'latitude': destination.latitude,
        'longitude': destination.longitude,
      },
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'carType': carType,
      'fare': fare,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'driver': driver?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Trip copyWith({
    String? id,
    String? customerId,
    LatLng? pickupLocation,
    LatLng? destination,
    String? pickupAddress,
    String? destinationAddress,
    String? carType,
    double? fare,
    double? distance,
    int? estimatedDuration,
    PaymentMethod? paymentMethod,
    RideStatus? status,
    Driver? driver,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      carType: carType ?? this.carType,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      driver: driver ?? this.driver,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Format fare in MAD
  String get formattedFare => CurrencyService.formatAmount(fare);

  // Get price breakdown in MAD
  Map<String, String> get priceBreakdown => CurrencyService.formatPriceBreakdown(fare);
}
