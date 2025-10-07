import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/ride_offer.dart';
import '../services/ride_offers_service.dart';
import '../services/ride_simulation_service.dart';
import '../services/currency_service.dart';
import 'ride_waiting_screen.dart';

class RideOfferDetailsScreen extends StatefulWidget {
  final RideOffer offer;

  const RideOfferDetailsScreen({super.key, required this.offer});

  @override
  State<RideOfferDetailsScreen> createState() => _RideOfferDetailsScreenState();
}

class _RideOfferDetailsScreenState extends State<RideOfferDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupCountdownAnimation();
  }

  void _setupCountdownAnimation() {
    final timeLeft = widget.offer.timeUntilExpiry;
    if (timeLeft.isNegative) return;

    _countdownController = AnimationController(
      duration: timeLeft,
      vsync: this,
    );

    _countdownAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_countdownController);

    _countdownController.forward();

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop(); // Auto-close when expired
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _acceptOffer() async {
    if (_isProcessing) return;

    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await _showConfirmDialog(
      l10n.confirmAccept,
      l10n.areYouSureAccept,
    );
    
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    final offersService = Provider.of<RideOffersService>(context, listen: false);
    final success = await offersService.acceptOffer(widget.offer.id);

    if (success && mounted) {
      // Convert offer to trip and start ride simulation
      final trip = offersService.convertOfferToTrip(widget.offer.id);
      if (trip != null) {
        final rideService = Provider.of<RideSimulationService>(context, listen: false);
        rideService.startRideSimulation(trip);

        // Navigate to ride waiting screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RideWaitingScreen(trip: trip),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.rideAccepted)),
        );
      }
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rideOfferExpired)),
      );
    }
  }

  Future<void> _declineOffer() async {
    if (_isProcessing) return;

    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await _showConfirmDialog(
      l10n.confirmDecline,
      l10n.areYouSureDecline,
    );
    
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    final offersService = Provider.of<RideOffersService>(context, listen: false);
    final success = await offersService.declineOffer(widget.offer.id);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rideDeclined)),
      );
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rideOfferDetails),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Countdown Timer
            _buildCountdownTimer(l10n),
            const SizedBox(height: 16),

            // Priority Badge
            if (widget.offer.priority != RideOfferPriority.low)
              _buildPriorityBadge(l10n),

            // Passenger Info Card
            _buildPassengerInfoCard(l10n),
            const SizedBox(height: 16),

            // Ride Info Card
            _buildRideInfoCard(l10n),
            const SizedBox(height: 16),

            // Earnings Card
            _buildEarningsCard(l10n),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _countdownAnimation,
      builder: (context, child) {
        final timeLeft = widget.offer.timeUntilExpiry;
        final seconds = timeLeft.inSeconds.clamp(0, double.infinity).toInt();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seconds < 30 ? Colors.red[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seconds < 30 ? Colors.red : Colors.orange,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: seconds < 30 ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Time left: ${seconds}s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: seconds < 30 ? Colors.red : Colors.orange,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: _countdownAnimation.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    seconds < 30 ? Colors.red : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(AppLocalizations l10n) {
    final priority = widget.offer.priority;
    Color color;
    String text;

    switch (priority) {
      case RideOfferPriority.high:
        color = Colors.red;
        text = l10n.high;
        break;
      case RideOfferPriority.medium:
        color = Colors.orange;
        text = l10n.medium;
        break;
      case RideOfferPriority.low:
        color = Colors.green;
        text = l10n.low;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.priority_high, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${l10n.priority}: $text',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.offer.hasSurge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.offer.surgeMultiplier.toStringAsFixed(1)}x ${l10n.surge}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerInfoCard(AppLocalizations l10n) {
    final passenger = widget.offer.passengerInfo;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.passengerInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue[800]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${passenger.rating.toStringAsFixed(1)}'),
                        ],
                      ),
                      Text(
                        passenger.phoneNumber,
                        style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildRideInfoCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rideInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.my_location, l10n.pickupLocation, widget.offer.pickupAddress, Colors.green),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, l10n.dropoffLocation, widget.offer.dropoffAddress, Colors.red),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.directions_car, l10n.carType, widget.offer.carType, Colors.blue),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(Icons.straighten, l10n.distance, widget.offer.formattedDistance, Colors.purple),
                ),
                Expanded(
                  child: _buildInfoRow(Icons.access_time, l10n.duration, widget.offer.formattedDuration, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.timer, l10n.timeToPickup, widget.offer.formattedTimeToPickup, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(AppLocalizations l10n) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  l10n.earnings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.basePrice),
                Text(widget.offer.formattedBasePrice),
              ],
            ),
            if (widget.offer.hasSurge) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.surgeMultiplier} (${widget.offer.surgeMultiplier}x)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '+${CurrencyService.formatAmount(((widget.offer.basePrice * widget.offer.surgeMultiplier) - widget.offer.basePrice))}',
                    style: const TextStyle(color: Colors.purple),
                  ),
                ],
              ),
            ],
            if (widget.offer.hasBonus) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.bonusEarnings),
                  Text(
                    '+${widget.offer.formattedBonusEarnings}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.offer.formattedEarnings,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _declineOffer,
            icon: const Icon(Icons.close),
            label: Text(l10n.declineRide),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _acceptOffer,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isProcessing ? l10n.processing : l10n.acceptRide),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
