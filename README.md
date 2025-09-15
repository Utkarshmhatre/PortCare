# 🏥 PortCare - Healthcare Management System

A comprehensive Flutter-based healthcare management application that connects patients, doctors, and medical booths through an intuitive mobile platform.

## 📋 Overview

PortCare is a complete healthcare management solution featuring:
- **Real-time Booth Management** with location services and availability tracking
- **Appointment Scheduling** with doctor-patient matching
- **Document Management** for medical records and prescriptions
- **QR Code Check-in** for seamless booth access
- **Firebase Integration** with optimized database queries
- **Cross-platform Support** (Android, iOS, Web, Desktop)

## 🚀 Features

### Core Functionality
- ✅ **Booth Management**: Real-time booth status, location-based discovery, service filtering
- ✅ **Appointment Booking**: Doctor selection, time slot management, booking confirmation
- ✅ **User Authentication**: Email/Phone authentication with Firebase Auth
- ✅ **Document Storage**: Secure medical document upload and management
- ✅ **Location Services**: GPS-based booth discovery and distance calculation
- ✅ **Real-time Updates**: Live data synchronization across all features

### Technical Features
- 🔧 **Firebase Integration**: Firestore, Authentication, Storage, Cloud Messaging
- 📱 **Cross-platform**: Flutter framework for Android, iOS, Web, and Desktop
- 🎨 **Material Design**: Beautiful, accessible UI with custom theming
- 📍 **Geolocation**: Advanced location services with permission handling
- 🔍 **Advanced Search**: Filter booths by services, location, and availability
- 📊 **Analytics**: Firebase Analytics for user behavior insights

## 🛠️ Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **Backend**: Firebase (Firestore, Auth, Storage, Functions)
- **State Management**: Provider Pattern
- **Architecture**: Repository Pattern with Clean Architecture
- **Database**: Firestore with optimized indexes
- **Authentication**: Firebase Auth (Email, Phone, Google Sign-in)
- **Storage**: Firebase Cloud Storage
- **Location**: Geolocator package with permission handling

## 📱 Screenshots

*Add screenshots of your app here*

## 🔧 Installation

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Firebase CLI
- Android Studio / Xcode (for mobile development)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Utkarshmhatre/PortCare.git
   cd portcare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at https://console.firebase.google.com/
   - Enable Firestore, Authentication, and Storage
   - Download `google-services.json` and place it in `android/app/`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Deploy Firebase Rules and Indexes**
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── models/           # Data models (Appointment, Booth, Doctor, etc.)
├── providers/        # State management (Auth, Appointment providers)
├── repositories/     # Data access layer (Firebase repositories)
├── screens/          # UI screens organized by feature
│   ├── auth/         # Authentication screens
│   ├── booths/       # Booth management screens
│   ├── appointments/ # Appointment booking screens
│   ├── doctors/      # Doctor management screens
│   └── home/         # Main dashboard
├── services/         # Business logic services
├── widgets/          # Reusable UI components
└── design/           # Theme, colors, typography
```

## 🔒 Firebase Configuration

### Required Firebase Services:
- **Firestore**: Main database with optimized indexes
- **Authentication**: User authentication and authorization
- **Storage**: Document and image storage
- **Cloud Messaging**: Push notifications (optional)

### Security Rules:
- Comprehensive Firestore security rules in `firestore.rules`
- Storage security rules in `storage.rules`
- User-based access control for all resources

## 📊 Database Schema

### Collections:
- **users**: User profiles and authentication data
- **doctors**: Doctor information and specializations
- **booths**: Medical booth details and availability
- **appointments**: Appointment bookings and schedules
- **documents**: Medical records and prescriptions

### Optimized Indexes:
22 composite indexes for efficient querying across all collections.

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📦 Build & Deployment

### Android APK:
```bash
flutter build apk --release
```

### iOS App Store:
```bash
flutter build ios --release
```

### Web Deployment:
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Utkarsh Mhatre** - *Initial work* - [Utkarshmhatre](https://github.com/Utkarshmhatre)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for comprehensive backend services
- Material Design team for design inspiration
- Healthcare professionals for domain expertise

## 📞 Support

For support, email utkarshmhatre@example.com or create an issue in this repository.

---

**Made with ❤️ for better healthcare management**
