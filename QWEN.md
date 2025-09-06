# OPTION v4.1 - Urban Mobility Application

## Project Overview

OPTION is a Flutter-based urban mobility application built with Material Design 3, targeting both Android and iOS platforms. The application serves as a ride-sharing platform connecting passengers with drivers, featuring comprehensive driver management, trip coordination, payment processing, and real-time location tracking.

The application uses Supabase as its primary backend for database, authentication, and storage, with Firebase for additional services and OneSignal for push notifications.

## Technology Stack

- **Frontend**: Flutter (Dart) with Material Design 3
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Push Notifications**: OneSignal
- **Maps**: Google Maps
- **Payments**: Asaas (Brazilian payment gateway)
- **Additional Services**: Firebase Core, Geolocation services

## Project Structure

```
option-v4.1/
├── lib/                 # Main Flutter application source code
│   ├── config/          # Configuration files
│   ├── controllers/     # State management controllers
│   ├── core/            # Core utilities and error handling
│   ├── debug/           # Debug tools and screens
│   ├── exceptions/      # Custom exception classes
│   ├── models/          # Data models
│   ├── screens/         # UI screens and components
│   ├── services/        # Business logic and API services
│   ├── theme/           # Application theming
│   ├── utils/           # Utility functions
│   ├── validators/      # Input and data validators
│   └── widgets/         # Custom reusable widgets
├── supabase/           # Supabase configuration and migrations
│   └── migrations/     # Database schema migrations
├── scripts/            # Automation and maintenance scripts
├── assets/             # Images and other static assets
├── tests/              # Test files
└── docs/               # Documentation
```

## Key Features

1. **User Management**
   - Passenger and driver registration
   - Authentication and session management
   - Profile management

2. **Driver Management**
   - Driver registration with vehicle information
   - Document verification (CNH, CRLV)
   - Working hours management
   - Online/offline status
   - Operation zones and excluded zones

3. **Trip Management**
   - Passenger trip requests
   - Driver selection and matching
   - Real-time location tracking
   - Trip history and ratings

4. **Payment System**
   - Wallet management
   - Integration with Asaas payment gateway
   - Trip pricing and fee calculation

5. **Notifications**
   - Push notifications via OneSignal
   - In-app notification center

## Development Setup

1. **Environment Variables**
   The application requires several environment variables configured in `lib/config/app_config.dart`:
   - Supabase URL and Anon Key
   - Asaas API credentials
   - Google Maps API key

2. **Dependencies**
   Key dependencies are listed in `pubspec.yaml`:
   - Flutter SDK 3.0.0+
   - Supabase Flutter package
   - Google Maps integration
   - Firebase services
   - HTTP client and geolocation packages

## Database Schema

The application uses a PostgreSQL database hosted on Supabase with key tables including:
- `drivers` - Driver profiles and vehicle information
- `driver_documents` - Driver document storage (CNH, CRLV)
- `working_hours` - Driver availability schedules
- `trips` - Trip records and status tracking
- `users` - User accounts and authentication

## Recent Fixes and Improvements

The project has undergone several fixes for common issues:
1. **Working Hours View Fix** - Corrected `driver_effective_status` view to properly calculate driver availability
2. **Document Duplication Fix** - Eliminated duplicate storage of CNH/CRLV documents in both `drivers` and `driver_documents` tables
3. **CNH Photo URL Constraint Fix** - Resolved null value constraint violations for `cnh_photo_url` field

## Building and Running

To run the application locally:

1. Ensure Flutter SDK 3.0.0+ is installed
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure environment variables in `lib/config/app_config.dart`
4. Run the application:
   ```bash
   flutter run
   ```

## Testing

The project includes unit and integration tests:
- Unit tests for services and models
- Integration tests for key workflows
- Widget tests for UI components

Run tests with:
```bash
flutter test
```

## Deployment

The application is configured for deployment to both Android and iOS platforms. Ensure proper signing configurations are set up for each platform before building release versions.

For iOS deployment:
1. Update signing certificates in Xcode project
2. Configure provisioning profiles
3. Build with: `flutter build ios`

For Android deployment:
1. Configure keystore and signing configurations
2. Build with: `flutter build apk`

## Maintenance and Operations

The project includes several maintenance scripts:
- Database backup scripts (`scripts/supabase_backup.py`)
- Database schema migration files
- Debug and diagnostic tools

Regular maintenance tasks include:
1. Database backups
2. Schema migrations
3. Dependency updates
4. Performance monitoring