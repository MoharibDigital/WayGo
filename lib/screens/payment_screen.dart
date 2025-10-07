import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/currency_service.dart';
import 'ride_waiting_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Trip trip;

  const PaymentScreen({super.key, required this.trip});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == PaymentMethod.creditCard) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // Navigate to ride waiting screen
      final updatedTrip = widget.trip.copyWith(
        paymentMethod: _selectedPaymentMethod,
        status: RideStatus.findingDriver,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RideWaitingScreen(trip: updatedTrip),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serviceFee = CurrencyService.calculateServiceFee(widget.trip.fare);
    final tax = CurrencyService.calculateTax(widget.trip.fare);
    final total = CurrencyService.calculateTotal(widget.trip.fare);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payment),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Summary Card
            Card(
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
                            '${l10n.from}: ${widget.trip.pickupAddress}',
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
                            '${l10n.to}: ${widget.trip.destinationAddress}',
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
                        Text('${widget.trip.carType}'),
                        const Spacer(),
                        Text('${widget.trip.distance.toStringAsFixed(1)} ${l10n.km}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectPaymentMethod,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodTile(PaymentMethod.creditCard, Icons.credit_card, l10n.creditCard),
                    _buildPaymentMethodTile(PaymentMethod.paypal, Icons.payment, l10n.paypal),
                    _buildPaymentMethodTile(PaymentMethod.applePay, Icons.phone_iphone, l10n.applePay),
                    _buildPaymentMethodTile(PaymentMethod.googlePay, Icons.android, l10n.googlePay),
                    _buildPaymentMethodTile(PaymentMethod.cash, Icons.money, l10n.cash),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Credit Card Form (only show if credit card is selected)
            if (_selectedPaymentMethod == PaymentMethod.creditCard)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.enterCardDetails,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: InputDecoration(
                            labelText: l10n.cardNumber,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card number';
                            }
                            if (value.length < 16) {
                              return 'Card number must be 16 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryDateController,
                                decoration: InputDecoration(
                                  labelText: l10n.expiryDate,
                                  border: const OutlineInputBorder(),
                                  hintText: 'MM/YY',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 4) {
                                    return 'Invalid date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                decoration: InputDecoration(
                                  labelText: l10n.cvv,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 3) {
                                    return 'Invalid CVV';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardHolderController,
                          decoration: InputDecoration(
                            labelText: l10n.cardHolderName,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card holder name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Price Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.subtotal),
                        Text(CurrencyService.formatAmount(widget.trip.fare)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.serviceFee),
                        Text(CurrencyService.formatAmount(serviceFee)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.tax),
                        Text(CurrencyService.formatAmount(tax)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.total,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          CurrencyService.formatAmount(total),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.processing),
                        ],
                      )
                    : Text(
                        '${l10n.payNow} - ${CurrencyService.formatAmount(total)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, IconData icon, String title) {
    return RadioListTile<PaymentMethod>(
      value: method,
      groupValue: _selectedPaymentMethod,
      onChanged: (PaymentMethod? value) {
        setState(() {
          _selectedPaymentMethod = value!;
        });
      },
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}
