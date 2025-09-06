# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is OPTION, a Flutter-based urban mobility application similar to Uber/99. It's a dual-sided platform connecting passengers and drivers with ride-hailing services.

**Key Technologies:**
- Flutter 3.35+ (Dart 3.9+)
- Supabase (Backend-as-a-Service: Database, Auth, Storage)
- Firebase (File Storage, Core services)
- Google Maps API for location services
- OneSignal for push notifications
- Asaas payment integration

## Development Commands

### Running the App

For development with different environments:

```bash
# Development with sandbox environment
make run-sandbox          # Requires ASAAS_API_KEY env variable
make run-prod             # Production environment
make run-web-sandbox      # Web version (Chrome) with sandbox
make run-web-prod         # Web version (Chrome) with production

# Standard Flutter commands also work
flutter run
flutter run -d chrome --web-renderer html
```

### Build Commands

```bash
# Build APK for different environments
make build-apk-sandbox    # Sandbox APK build
make build-apk-prod       # Production APK build

# Build iOS
make build-ios-sandbox    # iOS build (sandbox, no codesign)
make build-ios-prod       # iOS build (production, no codesign)

# Standard Flutter builds
flutter build apk --release
flutter build ios --no-codesign
```

### Testing

```bash
# Run all tests
flutter test

# Run specific tests (based on discovered test files)
flutter test tests/all_tests/
flutter test test_platform_settings_direct.dart

# Integration testing
flutter test integration_test/
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
├── config/           # App configuration (Supabase, API keys)
├── controllers/      # State management controllers
├── core/            # Core utilities, error handling, performance
├── exceptions/      # Custom exception classes
├── models/          # Data models, primarily Supabase models
├── screens/         # UI screens organized by feature
├── services/        # Business logic and API services
├── theme/           # Material Design 3 theming
├── utils/           # Utility functions and helpers
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

### Key Services Architecture

- **UserService**: Core user management with auth integration
- **TripService**: Trip lifecycle management (requests, matching, completion)
- **DriverService**: Driver-specific operations and status management
- **AuthService**: Authentication and authorization
- **LocationService**: GPS and location handling
- **PaymentService**: Asaas payment integration
- **NotificationService**: OneSignal push notifications

### Database Layer

Uses Supabase with these key tables:
- `app_users` - User profiles and authentication
- `drivers` - Driver-specific data and vehicle info
- `passengers` - Passenger-specific data
- `trips` - Trip records and history
- `trip_requests` - Trip matching and requests
- `driver_documents` - Document storage references
- `saved_places` - User favorite locations

### State Management

Uses Provider pattern with controllers:
- `StepperController` - Onboarding flow management
- `DriverStepperController` - Driver registration flow
- `DriverStatusController` - Driver online/offline status
- `SavedPlacesController` - Location management

## Important Configuration

### Environment Variables

Required environment variables for different builds:
- `ASAAS_API_KEY` - Payment gateway API key
- `ASAAS_BASE_URL` - Payment gateway base URL (sandbox/prod)
- `SUPABASE_URL` - Set in AppConfig (hardcoded)
- `SUPABASE_ANON_KEY` - Set in AppConfig (hardcoded)
- `GOOGLE_MAPS_API_KEY` - Set in AppConfig (hardcoded)

### Key Features

**Passenger Flow:**
- Registration → Location selection → Trip request → Driver matching → Trip completion → Rating

**Driver Flow:**
- Registration → Document upload → Vehicle registration → Working hours setup → Go online → Accept trips

**Document Management:**
- Uses Supabase Storage with signed URLs
- Automatic URL refresh system to prevent cache issues
- Support for CNH (driver's license) and CRLV (vehicle registration)

### Critical Implementation Notes

**Authentication:**
- Supabase Auth integrated with custom user profiles
- Row-level security (RLS) policies for data access
- User type distinction (passenger/driver)

**Real-time Features:**
- Trip request subscriptions using Supabase Realtime
- Driver location updates
- Push notifications via OneSignal

**Payment Integration:**
- Asaas gateway for Brazilian market
- Support for PIX, credit cards, digital wallet
- Driver earnings and passenger wallet management

**Location Services:**
- Google Maps integration for address search
- Geolocator for GPS positioning
- Geocoding for address resolution
- Excluded zones and operation areas for drivers

**Error Handling:**
- Custom PostgrestErrorMapper for database errors
- Structured error logging with ErrorLoggingService
- User-friendly error messages in Portuguese

### Testing Strategy

- Unit tests for services and business logic
- Integration tests for critical user flows
- Widget tests for key UI components
- Manual testing scripts for payment and location features

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
- Never expose API keys in client code
- Log security events for audit trails