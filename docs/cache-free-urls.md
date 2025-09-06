# Cache-Free URLs for Driver Documents

This guide explains how to remove cache dependency for driver document URLs (CNH and CRLV) in the Supabase project.

## Overview

The system now uses **signed URLs** from Supabase Storage instead of cached URLs, ensuring:
- ✅ No cache dependency
- ✅ Fresh URLs on every request
- ✅ Automatic expiration handling
- ✅ Better security with time-limited URLs

## Changes Made

### 1. Database Migration
Created migration: `20250906120001_update_driver_documents_fresh_urls_simple.sql`
- Added view `driver_current_documents` with URL freshness tracking
- No cache columns removed (URLs are generated dynamically)

### 2. New Services

#### StorageUrlFreshner (`/lib/utils/storage_url_freshner.dart`)
- Generates fresh signed URLs from Supabase Storage
- Handles URL caching with automatic refresh
- Supports batch URL generation
- Includes cache management utilities

#### DriverDocumentRefreshService (`/lib/services/driver_document_refresh_service.dart`)
- Specialized service for driver documents
- Uses signed URLs to prevent cache issues
- Provides methods for refreshing document URLs

### 3. Updated Services

#### DriverDocumentService (`/lib/services/driver_document_service.dart`)
- Modified `getCurrentDriverDocuments()` to use fresh URLs
- Added `_getFreshSignedUrl()` helper method
- Updated `getExpiringDocuments()` with fresh URLs

### 4. New Widget

#### DriverDocumentCardFresh (`/lib/widgets/driver_document_card_fresh.dart`)
- Displays documents with automatically refreshed URLs
- Includes manual refresh button
- Shows loading states and error handling

## Usage Examples

### Get fresh URLs for driver documents:

```dart
// Get all documents with fresh URLs
final documents = await StorageUrlFreshner.getDriverDocumentsWithFreshUrls(driverId);

// Get single fresh URL
final freshUrl = await StorageUrlFreshner.getFreshSignedUrl(
  bucket: 'driver-documents',
  filePath: 'driver-uuid/document-type/file-name.jpg',
);

// Use the specialized service
final refreshService = DriverDocumentRefreshService(supabase);
final docs = await refreshService.getDocumentsWithFreshUrls(driverId);
```

### In Flutter widgets:

```dart
// Use the fresh document card
DriverDocumentCardFresh(
  document: documentData,
  onRefresh: () => _refreshDocuments(),
)

// Or use with CachedNetworkImage directly
CachedNetworkImage(
  imageUrl: freshUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## Configuration

### Supabase Storage Setup
1. Ensure the `driver-documents` bucket exists
2. Set appropriate file size limits
3. Configure CORS if needed for web

### Environment Variables
No additional environment variables needed - uses existing Supabase configuration.

## Cache Management

The system automatically manages URL caching:
- URLs expire after 55 minutes (renewed before 1-hour limit)
- Cache can be manually cleared: `StorageUrlFreshner.clearCache()`
- Individual URLs can be removed from cache
- Cache statistics available via `StorageUrlFreshner.getCacheStats()`

## Migration Steps

1. **Apply database migration:**
   ```bash
   supabase migration up
   ```

2. **Update Flutter dependencies:**
   Ensure `cached_network_image` is in `pubspec.yaml`:
   ```yaml
   cached_network_image: ^3.3.0
   ```

3. **Replace old widgets:**
   Replace any cached URL usage with the new services/widgets.

## Testing

### Manual Testing
1. Upload new driver documents
2. Verify URLs are fresh (not cached)
3. Check manual refresh functionality
4. Verify cache statistics

### Automated Testing
```bash
flutter test test/services/driver_document_refresh_service_test.dart
```

## Troubleshooting

### Common Issues

**URLs not refreshing:**
- Check Supabase Storage bucket permissions
- Verify file paths are correct
- Check network connectivity

**Cache not working:**
- Ensure `_SignedUrlCache` is properly initialized
- Check cache key format

**Images not loading:**
- Verify file exists in storage
- Check CORS settings for web
- Ensure bucket name is correct

### Debug Commands

```dart
// Check cache status
print(StorageUrlFreshner.getCacheStats());

// Clear all cache
StorageUrlFreshner.clearCache();

// Force refresh specific URL
StorageUrlFreshner.removeFromCache('bucket-name', 'file-path');
```

## Performance Notes

- Signed URLs expire after 1 hour (Supabase limit)
- Cache reduces API calls while maintaining freshness
- URLs are renewed 5 minutes before expiration
- No impact on upload performance

## Security

- URLs are time-limited (1 hour max)
- Uses Supabase's built-in signed URL security
- No sensitive data in URLs
- Proper bucket permissions enforced