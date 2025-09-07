# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is OPTION, a Flutter-based urban mobility application similar to Uber/99. It's a dual-sided platform connecting passengers and drivers with ride-hailing services.

**Key Technologies:**
- Flutter 3.0+ (Dart 3.0+)
- Supabase (Backend-as-a-Service: Database, Auth, Storage)
- Firebase (File Storage, Core services)
- Google Maps API for location services
- OneSignal for push notifications
- Asaas payment integration

## Development Commands

### Running the App

```bash
# Standard Flutter commands for development
flutter run                                    # Debug mode
flutter run --release                         # Release mode
flutter run -d chrome --web-renderer html     # Web version

# With environment variables
SUPABASE_URL=https://qlbwacmavngtonauxnte.supabase.co SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E flutter run
```

### Build Commands

```bash
# Build APK
flutter build apk --release

# Build iOS (no codesigning)
flutter build ios --no-codesign

# Build for web
flutter build web
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/user_registration_test.dart
flutter test test_platform_settings_direct.dart

# Run integration tests
flutter test integration_test/

# Generate mocks for testing
./generate_mocks.sh
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting and Analysis

```bash
flutter analyze
flutter pub deps
```

## Architecture Overview

### Directory Structure

```
lib/
├── config/           # App configuration (Supabase, API keys, feature flags)
├── controllers/      # State management controllers
├── core/            # Core utilities, error handling, performance
├── debug/           # Debug utilities and screens
├── exceptions/      # Custom exception classes
├── examples/        # Example code and demos
├── models/          # Data models, primarily Supabase models
├── screens/         # UI screens organized by feature
│   ├── auth/        # Authentication screens
│   ├── driver/      # Driver-specific screens
│   ├── passenger/   # Passenger-specific screens
│   ├── payments/    # Payment screens
│   ├── stepper/     # Onboarding flows
│   ├── trip/        # Trip-related screens
│   └── wallet/      # Wallet management screens
├── services/        # Business logic and API services
├── theme/           # Material Design 3 theming
├── utils/           # Utility functions and helpers
├── validators/      # Input validation logic
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

### Key Services Architecture

**Core Services:**
- **UserService**: User management with auth integration
- **AuthService**: Authentication and authorization (including bypass options)
- **TripService**: Trip lifecycle management
- **DriverService**: Driver operations and status management
- **LocationService**: GPS and location handling
- **PaymentService**: Asaas payment integration
- **NotificationService**: OneSignal push notifications

**Driver-Specific Services:**
- **DriverDocumentService**: Document upload and validation
- **DriverExcludedZonesService**: Geographic restriction management
- **DriverWalletService**: Driver earnings and wallet management
- **DriverStatusService**: Online/offline status management

**Passenger Services:**
- **PassengerPaymentService**: Payment processing for trips
- **SavedPlacesService**: Favorite locations management
- **TripRequestManager**: Trip request handling

**Supporting Services:**
- **DataIntegrityService**: Data validation and consistency
- **SecurityService**: Security features and validation
- **MonitoringService**: App performance and error tracking

### Database Layer

Uses Supabase with these key tables:
- `app_users` - User profiles and authentication
- `drivers` - Driver-specific data and vehicle info
- `passengers` - Passenger-specific data
- `trips` - Trip records and history
- `trip_requests` - Trip matching and requests
- `driver_documents` - Document storage references
- `saved_places` - User favorite locations
- `platform_settings` - App configuration settings

### State Management

Uses Provider pattern with controllers:
- `StepperController` - Onboarding flow management
- `DriverStepperController` - Driver registration flow
- `DriverStatusController` - Driver online/offline status
- `SavedPlacesController` - Location management

## Important Configuration

### Environment Variables

Environment variables can be set for different configurations:
- `SUPABASE_URL` - Supabase project URL (defaults to production)
- `SUPABASE_ANON_KEY` - Supabase anonymous key (defaults to production)
- `ASAAS_API_KEY` - Payment gateway API key
- `ASAAS_BASE_URL` - Payment gateway base URL
- `GOOGLE_MAPS_API_KEY` - Google Maps API key

Configuration is handled in `lib/config/app_config.dart` with production defaults.

### Key Features

**Passenger Flow:**
- Registration → Location selection → Trip request → Driver matching → Trip completion → Rating

**Driver Flow:**
- Registration → Document upload → Vehicle registration → Go online → Accept trips → Complete trips

**Document Management:**
- Uses Supabase Storage with signed URLs
- Automatic URL refresh system to prevent cache issues
- Support for CNH (driver's license) and CRLV (vehicle registration)
- Document validation and approval workflow

### Critical Implementation Notes

**Authentication:**
- Supabase Auth integrated with custom user profiles
- Row-level security (RLS) policies for data access
- User type distinction (passenger/driver)
- Bypass auth available for testing (`BypassAuthService`)

**Real-time Features:**
- Trip request subscriptions using Supabase Realtime
- Driver location updates
- Push notifications via OneSignal

**Payment Integration:**
- Asaas gateway for Brazilian market
- Support for PIX, credit cards, digital wallet
- Driver earnings and passenger wallet management
- Cancellation fee handling

**Location Services:**
- Google Maps integration for address search
- Geolocator for GPS positioning
- Geocoding for address resolution
- Driver excluded zones and operation areas
- Geographic validation services

**Error Handling:**
- Custom PostgrestErrorMapper for database errors
- Structured error logging with multiple logging services
- User-friendly error messages in Portuguese
- Comprehensive monitoring and health checks

### Testing Strategy

- Unit tests for services and business logic (`test/services/`)
- Integration tests for critical user flows (`test/integration/`)
- Widget tests for key UI components (`test/widgets/`)
- End-to-end tests for complete user journeys
- Mock generation using `build_runner` and `mockito`

**Key Test Files:**
- `test/user_registration_test.dart` - User registration flows
- `test_platform_settings_direct.dart` - Platform settings testing
- Various driver flow tests for registration and operations

## Development Guidelines

**Code Organization:**
- Follow existing patterns for new features
- Use existing error handling infrastructure
- Maintain Portuguese user-facing text
- Follow Material Design 3 principles

**Database Operations:**
- Always use service layer, never direct Supabase calls in UI
- Implement proper error handling for all database operations
- Use transactions for multi-table operations
- Validate user permissions before data access

**UI Development:**
- Use existing theme components and colors
- Follow established navigation patterns
- Implement loading states for async operations
- Handle offline scenarios gracefully

**Security Considerations:**
- Validate user permissions in all service methods
- Use RLS policies in Supabase
- API keys are configured in `app_config.dart` with environment variable support
- Log security events for audit trails