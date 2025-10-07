import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/ride_offer.dart';
import '../services/ride_offers_service.dart';
import 'ride_offer_details_screen.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Start generating ride offers when driver page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offersService = Provider.of<RideOffersService>(context, listen: false);
      offersService.startGeneratingOffers();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<String> _getTitles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.rideOffers,
      l10n.earnings,
      l10n.account,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = _getTitles(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
        elevation: 2,
      ),
      body: _buildCurrentPage(l10n),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.request_page),
            label: l10n.requests,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.earnings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.account,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0:
        return _buildRideOffersPage(l10n);
      case 1:
        return _buildEarningsPage(l10n);
      case 2:
        return _buildAccountPage(l10n);
      default:
        return _buildRideOffersPage(l10n);
    }
  }

  Widget _buildRideOffersPage(AppLocalizations l10n) {
    return Consumer<RideOffersService>(
      builder: (context, offersService, child) {
        final offers = offersService.availableOffers;

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_taxi, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  l10n.noRideOffers,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.waitingForRides,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh offers
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildOfferCard(offer, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildOfferCard(RideOffer offer, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RideOfferDetailsScreen(offer: offer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (offer.priority == RideOfferPriority.high)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.high,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (offer.hasSurge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${offer.surgeMultiplier.toStringAsFixed(1)}x',
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
                  Text(
                    offer.formattedEarnings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Passenger info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, size: 16, color: Colors.blue[800]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    offer.passengerInfo.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(
                    offer.passengerInfo.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route info
              Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      offer.pickupAddress,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      offer.dropoffAddress,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Trip details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailChip(Icons.straighten, offer.formattedDistance),
                  _buildDetailChip(Icons.access_time, offer.formattedDuration),
                  _buildDetailChip(Icons.timer, '${offer.timeToPickup} min'),
                ],
              ),
              const SizedBox(height: 12),

              // Countdown and action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Expires in ${offer.timeUntilExpiry.inSeconds}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: offer.timeUntilExpiry.inSeconds < 30 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    l10n.viewDetails,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsPage(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(l10n.totalEarnings, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('0.00 ${l10n.currencySymbol}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildAccountPage(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchDriverData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null) {
          return Center(child: Text(l10n.noDriverDataFound));
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 50, color: Colors.blue[800]),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Name'),
              subtitle: Text(data['name'] ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(data['email'] ?? ''),
            ),
            if (data['car'] != null) ...[
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('Car Type'),
                subtitle: Text(data['car']['type'] ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text('Car Plate'),
                subtitle: Text(data['car']['plate'] ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Car Color'),
                subtitle: Text(data['car']['color'] ?? ''),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    }
    return null;
  }
}
