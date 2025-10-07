# WayGo

A Flutter ride-sharing application with multi-language support.

## Features

- 🚗 **Ride Booking**: Complete ride booking system with payment processing
- 💳 **Payment Integration**: Multiple payment methods (Credit Card, PayPal, Apple Pay, Google Pay, Cash)
- 🗺️ **Interactive Maps**: Real-time location tracking and route planning
- 👥 **Dual User Types**: Support for both customers and drivers
- 🌍 **Multi-Language Support**: English and French languages
- 📱 **Cross-Platform**: Works on both Android and iOS
- 🔥 **Firebase Integration**: User data storage with Firestore
- 🚙 **Real-time Tracking**: Live ride status updates and driver tracking
- 💰 **Moroccan Dirham (MAD)**: Local currency pricing optimized for Morocco
- 💸 **Smart Pricing**: Fare calculation based on distance and car type in MAD
- 💬 **Real-time Chat**: In-app messaging between drivers and customers
- 📞 **Voice Calls**: Integrated voice calling system
- 🔔 **Smart Notifications**: In-app notifications for messages and calls
- 🎯 **Auto-responses**: Intelligent driver response simulation
- 🎁 **Driver Ride Offers**: Real-time ride offers for drivers with smart matching
- ⏰ **Time-limited Offers**: Expiring offers with countdown timers
- 💰 **Dynamic Pricing**: Surge pricing and bonus earnings system
- 🏆 **Priority System**: High, medium, and low priority ride offers

## Language Support

The app supports the following languages:
- **English** (en)
- **French** (fr)

### Changing Language

1. Open the app and navigate to the **Profile** screen
2. Look for the **Language** option
3. Select your preferred language from the dropdown
4. The app will immediately switch to the selected language

### Adding New Languages

To add support for a new language:

1. Create a new ARB file in `lib/l10n/` (e.g., `app_es.arb` for Spanish)
2. Copy the structure from `app_en.arb` and translate the values
3. Add the new locale to `LanguageService.supportedLocales` in `lib/services/language_service.dart`
4. Add the language name to `LanguageService.languageNames`
5. Run `flutter gen-l10n` to generate the localization files

## Getting Started

### Prerequisites

- Flutter SDK (>=3.1.3)
- Firebase project setup
- Android Studio / VS Code

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up Firebase configuration
4. Run `flutter gen-l10n` to generate localization files
5. Run `flutter run` to start the app

### Dependencies

- `flutter_map`: Interactive maps
- `geolocator`: Location services
- `geocoding`: Address conversion
- `firebase_core` & `cloud_firestore`: Backend services
- `provider`: State management
- `shared_preferences`: Local storage
- `intl`: Internationalization support

## Ride Booking Flow

1. **Map Screen**: Select pickup and destination locations
2. **Car Selection**: Choose from Standard, Premium, or Van
3. **Fare Calculation**: Automatic fare calculation based on distance and car type
4. **Payment Screen**: Select payment method and enter payment details
5. **Ride Tracking**: Real-time status updates from booking to completion
   - Finding Driver
   - Driver Found
   - Driver On Way
   - Driver Arrived
   - Ride In Progress
   - Ride Completed
6. **Communication**: Chat and call with driver during the ride

## Communication Features

### 💬 **Real-time Chat**
- **Instant Messaging**: Send and receive messages in real-time
- **Message Status**: Delivery and read receipts
- **Typing Indicators**: See when the other person is typing
- **Auto-responses**: Smart driver responses for realistic simulation
- **System Messages**: Automated updates about ride status

### 📞 **Voice Calling**
- **One-tap Calling**: Easy voice call initiation
- **Call Status**: Visual indicators for call progress
- **Call Duration**: Real-time call timer
- **Call Controls**: Mute, speaker, and end call options

### 🔔 **Smart Notifications**
- **In-app Notifications**: Elegant overlay notifications for new messages
- **Call Notifications**: Full-screen incoming call interface
- **Haptic Feedback**: Tactile feedback for important notifications
- **Auto-dismiss**: Notifications automatically disappear after a few seconds

## Driver Features

### 🎁 **Real-time Ride Offers**
- **Live Offer Feed**: Continuous stream of ride requests from customers
- **Smart Matching**: Offers matched based on driver location and car type
- **Detailed Information**: Complete passenger and trip details before accepting
- **Time-limited**: Each offer expires after 2 minutes to ensure quick decisions

### 💰 **Dynamic Earnings System**
- **Base Pricing**: Standard fare calculation based on distance and time
- **Surge Pricing**: Automatic price multipliers during high demand (1.2x - 2.5x)
- **Bonus Earnings**: Additional incentives for completing certain rides ($2-10)
- **Priority Offers**: High-value rides highlighted with special badges

### ⏰ **Offer Management**
- **Countdown Timers**: Visual countdown showing time left to accept
- **Priority Badges**: High, medium, low priority classification
- **Quick Actions**: Accept or decline with confirmation dialogs
- **Auto-expiry**: Offers automatically removed when time expires

### 📊 **Offer Details**
- **Passenger Information**: Name, rating, and contact details
- **Trip Information**: Pickup/dropoff locations, distance, duration
- **Earnings Breakdown**: Base price, surge multiplier, bonus earnings
- **Time to Pickup**: Estimated time to reach passenger location

## Currency System

### 💰 **Moroccan Dirham (MAD) Integration**
- **Local Currency**: All prices displayed in Moroccan Dirham (DH)
- **Realistic Pricing**: Optimized fare structure for Moroccan market
- **Smart Conversion**: Automatic currency formatting and calculations
- **Price Breakdown**: Transparent fare calculation with fees and taxes

### 💸 **Pricing Structure**
- **Base Fare**: Starting from 15 DH (Standard), 25 DH (Premium), 20 DH (Van)
- **Per Kilometer**: 8 DH (Standard), 12 DH (Premium), 10 DH (Van)
- **Service Fee**: 10% of base fare
- **Tax**: 5% of base fare
- **Surge Pricing**: 1.2x - 2.5x during high demand
- **Bonus Earnings**: 20-100 DH for special offers

## Project Structure

```
lib/
├── main.dart                         # App entry point
├── models/
│   ├── trip.dart                     # Trip, Driver, Vehicle models
│   ├── message.dart                  # Chat message models
│   └── ride_offer.dart               # Ride offer models for drivers
├── services/
│   ├── language_service.dart         # Language management
│   ├── ride_simulation_service.dart  # Ride status simulation
│   ├── chat_service.dart             # Chat and calling functionality
│   ├── notification_service.dart     # In-app notifications
│   ├── ride_offers_service.dart      # Driver ride offers management
│   └── currency_service.dart         # Moroccan Dirham currency handling
├── screens/
│   ├── login_screen.dart             # Authentication
│   ├── map_screen.dart               # Main map interface
│   ├── payment_screen.dart           # Payment processing
│   ├── ride_waiting_screen.dart      # Ride tracking & status
│   ├── chat_screen.dart              # Real-time chat interface
│   ├── ride_offer_details_screen.dart # Driver offer details
│   ├── trips_screen.dart             # Trip history
│   ├── profile_screen.dart           # User profile & settings
│   └── driver_home_page.dart         # Driver interface with offers
└── l10n/
    ├── app_en.arb                   # English translations
    └── app_fr.arb                   # French translations
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add translations for new text strings
5. Test the app in both languages
6. Submit a pull request
