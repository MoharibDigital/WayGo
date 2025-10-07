import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../services/ride_simulation_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class RideWaitingScreen extends StatefulWidget {
  final Trip trip;

  const RideWaitingScreen({super.key, required this.trip});

  @override
  State<RideWaitingScreen> createState() => _RideWaitingScreenState();
}

class _RideWaitingScreenState extends State<RideWaitingScreen>
    with TickerProviderStateMixin {
  late RideSimulationService _rideService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeRideService();
  }

  void _initializeRideService() {
    _rideService = Provider.of<RideSimulationService>(context, listen: false);
    _rideService.startRideSimulation(widget.trip);

    // Initialize chat service context for notifications
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.setContext(context);
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<RideSimulationService>(
      builder: (context, rideService, child) {
        final currentTrip = rideService.currentTrip;
        
        if (currentTrip == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.rideStatus)),
            body: const Center(child: Text('No active ride')),
          );
        }

        // Show completion dialog when ride is completed
        if (currentTrip.status == RideStatus.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRideCompletedDialog(currentTrip);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_getStatusTitle(l10n, currentTrip)),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status Animation
                _buildStatusAnimation(l10n, currentTrip),
                const SizedBox(height: 24),

                // Trip Details Card
                _buildTripDetailsCard(l10n, currentTrip),
                const SizedBox(height: 16),

                // Driver Info Card (only show when driver is assigned)
                if (currentTrip.driver != null) _buildDriverInfoCard(l10n, currentTrip),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(l10n, currentTrip),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRideCompletedDialog(Trip trip) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.rideCompleted),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('${l10n.total}: \$${trip.fare.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to map
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAnimation(AppLocalizations l10n, Trip trip) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(trip.status),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusMessage(l10n, trip.status),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (trip.status == RideStatus.driverOnWay ||
                trip.status == RideStatus.driverArrived)
              Text(
                '${l10n.estimatedTime}: ${_getEstimatedTime(trip.status)} ${l10n.minutes}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsCard(AppLocalizations l10n, Trip trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rideDetails,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.from}: ${trip.pickupAddress}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.to}: ${trip.destinationAddress}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 8),
                Text('${trip.carType}'),
                const Spacer(),
                Text('${l10n.fare}: \$${trip.fare.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(AppLocalizations l10n, Trip trip) {
    final driver = trip.driver!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.driverInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${driver.rating}'),
                        ],
                      ),
                      Text(
                        '${driver.vehicle.model} - ${driver.vehicle.color}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${l10n.licensePlate}: ${driver.vehicle.licensePlate}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, Trip trip) {
    return Column(
      children: [
        if (trip.driver != null && trip.status != RideStatus.completed) ...[
          // Chat and Call buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(trip: trip),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: Text(l10n.chat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final chatService = Provider.of<ChatService>(context, listen: false);
                    chatService.startCall(trip.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.calling} ${trip.driver!.name}...')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: Text(l10n.call),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (trip.status != RideStatus.inProgress && trip.status != RideStatus.completed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(l10n),
              icon: const Icon(Icons.cancel),
              label: Text(l10n.cancelRide),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelRide),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _rideService.cancelRide();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to map
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(AppLocalizations l10n, Trip trip) {
    switch (trip.status) {
      case RideStatus.findingDriver:
        return l10n.findingDriver;
      case RideStatus.driverFound:
        return l10n.driverFound;
      case RideStatus.driverOnWay:
        return l10n.driverOnWay;
      case RideStatus.driverArrived:
        return l10n.driverArrived;
      case RideStatus.inProgress:
        return l10n.rideInProgress;
      case RideStatus.completed:
        return l10n.rideCompleted;
      default:
        return l10n.rideStatus;
    }
  }

  String _getStatusMessage(AppLocalizations l10n, RideStatus status) {
    switch (status) {
      case RideStatus.findingDriver:
        return l10n.waitingForDriver;
      case RideStatus.driverFound:
        return l10n.driverFound;
      case RideStatus.driverOnWay:
        return l10n.driverOnWay;
      case RideStatus.driverArrived:
        return l10n.driverArrived;
      case RideStatus.inProgress:
        return l10n.rideInProgress;
      case RideStatus.completed:
        return l10n.rideCompleted;
      default:
        return '';
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.findingDriver:
        return Icons.search;
      case RideStatus.driverFound:
        return Icons.person;
      case RideStatus.driverOnWay:
        return Icons.directions_car;
      case RideStatus.driverArrived:
        return Icons.location_on;
      case RideStatus.inProgress:
        return Icons.navigation;
      case RideStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.findingDriver:
        return Colors.orange;
      case RideStatus.driverFound:
        return Colors.blue;
      case RideStatus.driverOnWay:
        return Colors.purple;
      case RideStatus.driverArrived:
        return Colors.green;
      case RideStatus.inProgress:
        return Colors.teal;
      case RideStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  int _getEstimatedTime(RideStatus status) {
    switch (status) {
      case RideStatus.driverOnWay:
        return 5;
      case RideStatus.driverArrived:
        return 1;
      default:
        return 0;
    }
  }
}
