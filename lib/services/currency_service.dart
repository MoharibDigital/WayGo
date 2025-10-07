class CurrencyService {
  static const String _currencyCode = 'MAD';
  static const String _currencySymbol = 'DH';
  static const double _usdToMadRate = 10.0; // تقريبي: 1 USD = 10 MAD
  
  // Convert USD to MAD
  static double convertFromUSD(double usdAmount) {
    return usdAmount * _usdToMadRate;
  }
  
  // Format amount in MAD
  static String formatAmount(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    return showSymbol ? '$formattedAmount $_currencySymbol' : formattedAmount;
  }
  
  // Format amount with currency code
  static String formatAmountWithCode(double amount) {
    return '${amount.toStringAsFixed(2)} $_currencyCode';
  }
  
  // Get currency symbol
  static String get currencySymbol => _currencySymbol;
  
  // Get currency code
  static String get currencyCode => _currencyCode;
  
  // Parse amount from string (remove currency symbols)
  static double parseAmount(String amountString) {
    final cleanString = amountString
        .replaceAll(_currencySymbol, '')
        .replaceAll(_currencyCode, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleanString) ?? 0.0;
  }
  
  // Calculate fare in MAD (updated from USD pricing)
  static double calculateFare(double distance, String carType) {
    double baseFare = 15.0; // Base fare in MAD (was $5 = ~50 MAD, reduced for local pricing)
    double perKmRate = 8.0; // Rate per km in MAD (was $2 = ~20 MAD, reduced)
    
    // Adjust rate based on car type
    switch (carType) {
      case 'Premium':
        perKmRate = 12.0; // was $3 = ~30 MAD
        baseFare = 25.0; // was $8 = ~80 MAD
        break;
      case 'Van':
        perKmRate = 10.0; // was $2.5 = ~25 MAD
        baseFare = 20.0; // was $6 = ~60 MAD
        break;
      default: // Standard
        break;
    }
    
    return baseFare + (distance * perKmRate);
  }
  
  // Calculate service fee in MAD
  static double calculateServiceFee(double baseFare) {
    return baseFare * 0.1; // 10% service fee
  }
  
  // Calculate tax in MAD
  static double calculateTax(double baseFare) {
    return baseFare * 0.05; // 5% tax
  }
  
  // Calculate total with fees
  static double calculateTotal(double baseFare) {
    final serviceFee = calculateServiceFee(baseFare);
    final tax = calculateTax(baseFare);
    return baseFare + serviceFee + tax;
  }
  
  // Format price breakdown
  static Map<String, String> formatPriceBreakdown(double baseFare) {
    final serviceFee = calculateServiceFee(baseFare);
    final tax = calculateTax(baseFare);
    final total = calculateTotal(baseFare);
    
    return {
      'subtotal': formatAmount(baseFare),
      'serviceFee': formatAmount(serviceFee),
      'tax': formatAmount(tax),
      'total': formatAmount(total),
    };
  }
  
  // Generate realistic MAD amounts for offers
  static double generateOfferAmount(double baseAmount, double surgeMultiplier, double bonusAmount) {
    // Convert base amount to MAD if it was in USD
    final madBaseAmount = baseAmount > 100 ? baseAmount : convertFromUSD(baseAmount);
    final madBonusAmount = bonusAmount > 50 ? bonusAmount : convertFromUSD(bonusAmount);
    
    return (madBaseAmount * surgeMultiplier) + madBonusAmount;
  }
}
