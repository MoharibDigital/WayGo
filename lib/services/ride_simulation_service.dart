import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';

class RideSimulationService extends ChangeNotifier {
  Timer? _simulationTimer;
  Trip? _currentTrip;
  
  Trip? get currentTrip => _currentTrip;
  
  // Mock drivers pool
  static final List<Driver> _mockDrivers = [
    Driver(
      id: 'driver_001',
      name: 'Ahmed Hassan',
      phoneNumber: '+212 6 12 34 56 78',
      rating: 4.8,
      profileImage: '',
      vehicle: Vehicle(
        licensePlate: 'A 123456',
        model: 'Toyota Corolla',
        color: 'White',
        type: 'Standard',
      ),
    ),
    Driver(
      id: 'driver_002',
      name: 'Fatima Zahra',
      phoneNumber: '+212 6 87 65 43 21',
      rating: 4.9,
      profileImage: '',
      vehicle: Vehicle(
        licensePlate: 'B 789012',
        model: 'Mercedes C-Class',
        color: 'Black',
        type: 'Premium',
      ),
    ),
    Driver(
      id: 'driver_003',
      name: 'Mohamed Alami',
      phoneNumber: '+212 6 55 44 33 22',
      rating: 4.7,
      profileImage: '',
      vehicle: Vehicle(
        licensePlate: 'C 345678',
        model: 'Ford Transit',
        color: 'Blue',
        type: 'Van',
      ),
    ),
  ];
  
  void startRideSimulation(Trip trip) {
    _currentTrip = trip;
    _simulateRideProgress();
  }
  
  void _simulateRideProgress() {
    _simulationTimer?.cancel();
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentTrip == null) {
        timer.cancel();
        return;
      }
      
      switch (_currentTrip!.status) {
        case RideStatus.findingDriver:
          _assignDriver();
          break;
        case RideStatus.driverFound:
          _updateStatus(RideStatus.driverOnWay);
          break;
        case RideStatus.driverOnWay:
          _updateStatus(RideStatus.driverArrived);
          break;
        case RideStatus.driverArrived:
          _updateStatus(RideStatus.inProgress);
          break;
        case RideStatus.inProgress:
          _completeRide();
          timer.cancel();
          break;
        default:
          timer.cancel();
          break;
      }
    });
  }
  
  void _assignDriver() {
    // Find a suitable driver based on car type
    final suitableDrivers = _mockDrivers.where(
      (driver) => driver.vehicle.type == _currentTrip!.carType
    ).toList();
    
    if (suitableDrivers.isEmpty) {
      // If no exact match, use any available driver
      final randomDriver = _mockDrivers[Random().nextInt(_mockDrivers.length)];
      _currentTrip = _currentTrip!.copyWith(
        status: RideStatus.driverFound,
        driver: randomDriver,
      );
    } else {
      final randomDriver = suitableDrivers[Random().nextInt(suitableDrivers.length)];
      _currentTrip = _currentTrip!.copyWith(
        status: RideStatus.driverFound,
        driver: randomDriver,
      );
    }
    
    notifyListeners();
  }
  
  void _updateStatus(RideStatus newStatus) {
    _currentTrip = _currentTrip!.copyWith(status: newStatus);
    notifyListeners();
  }
  
  void _completeRide() {
    _currentTrip = _currentTrip!.copyWith(
      status: RideStatus.completed,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }
  
  void cancelRide() {
    _simulationTimer?.cancel();
    if (_currentTrip != null) {
      _currentTrip = _currentTrip!.copyWith(status: RideStatus.cancelled);
      notifyListeners();
    }
  }
  
  void resetSimulation() {
    _simulationTimer?.cancel();
    _currentTrip = null;
    notifyListeners();
  }
  
  // Get estimated time for current status
  int getEstimatedTime() {
    if (_currentTrip == null) return 0;
    
    switch (_currentTrip!.status) {
      case RideStatus.findingDriver:
        return 2; // 2 minutes to find driver
      case RideStatus.driverFound:
        return 1; // 1 minute for driver to start
      case RideStatus.driverOnWay:
        return 5; // 5 minutes for driver to arrive
      case RideStatus.driverArrived:
        return 1; // 1 minute to start ride
      case RideStatus.inProgress:
        return _currentTrip!.estimatedDuration; // Trip duration
      default:
        return 0;
    }
  }
  
  // Get status message key for localization
  String getStatusMessageKey() {
    if (_currentTrip == null) return '';
    
    switch (_currentTrip!.status) {
      case RideStatus.findingDriver:
        return 'findingDriver';
      case RideStatus.driverFound:
        return 'driverFound';
      case RideStatus.driverOnWay:
        return 'driverOnWay';
      case RideStatus.driverArrived:
        return 'driverArrived';
      case RideStatus.inProgress:
        return 'rideInProgress';
      case RideStatus.completed:
        return 'rideCompleted';
      case RideStatus.cancelled:
        return 'rideCancelled';
      default:
        return '';
    }
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
