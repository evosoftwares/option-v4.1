# Firebase Storage Buckets Guide

This document provides an overview of the Firebase Storage buckets/folders used in the project and guidelines for developers on how to interact with them.

**Important**: This project uses **Firebase Storage** for file storage, not Supabase Storage.

## Storage Structure

Firebase Storage organizes files in a hierarchical folder structure:

### 1. driver-documents/
- **Purpose**: Store driver document uploads (CNH, CRLV, etc.)
- **Path Pattern**: `driver-documents/drivers/{driver_id}/documents/{filename}`
- **File Types**: 
  - image/jpeg
  - image/jpg  
  - image/png
  - image/webp
  - application/pdf
- **Size Limit**: 50MB per file
- **Compression**: Enabled for images (85% quality, max 1920x1920px)
- **Access**: Private (authenticated users only)

### 2. user-photos/
- **Purpose**: Store user profile photos
- **Path Pattern**: `user-photos/users/{user_id}/profile/{filename}`  
- **File Types**:
  - image/jpeg
  - image/jpg
  - image/png
  - image/webp
- **Size Limit**: 50MB per file
- **Compression**: Enabled (85% quality, max 1920x1920px)
- **Access**: Private (authenticated users only)

## Developer Guidelines

### Uploading Files

1. **Authentication**: Ensure user has valid Supabase authentication session before uploading
2. **File Validation**: Validate file size and MIME type client-side before upload
3. **Path Convention**: Follow the established path patterns for consistency
4. **Service Usage**: Always use `FirebaseFileUploadService` for uploads

### Example Upload Code

```dart
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firebase_file_upload_service.dart';

// Upload driver document
Future<String?> uploadDriverDocument(File file, String driverId, String documentType) async {
  final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final path = 'drivers/$driverId/documents/$fileName';
  
  return await FirebaseFileUploadService.uploadDriverDocument(
    file: file,
    folder: 'driver-documents',
    path: path,
    compress: true,
  );
}

// Upload user profile photo  
Future<String?> uploadProfilePhoto(File file, String userId) async {
  final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final path = 'users/$userId/profile/$fileName';
  
  return await FirebaseFileUploadService.uploadImage(
    file: file,
    folder: 'user-photos', 
    path: path,
    compress: true,
  );
}
```

### Downloading/Accessing Files

Firebase Storage returns download URLs that can be used directly:

```dart
// The upload methods return download URLs
String downloadUrl = await uploadDriverDocument(file, driverId, 'cnh');

// Use the URL to display images
NetworkImage(downloadUrl)

// Or for documents
launchUrl(Uri.parse(downloadUrl));
```

### Error Handling

Handle common Firebase Storage errors:

- **File Size Limit**: Files exceeding 50MB will be rejected
- **MIME Type Error**: Only allowed file types can be uploaded
- **Authentication Error**: Session must be valid for uploads
- **Network Errors**: Implement retry logic for network issues
- **Permission Denied**: Check Firebase Storage security rules

### File Management

```dart
// Delete old file when uploading new one
await FirebaseFileUploadService.deleteFile(
  folder: 'user-photos',
  path: oldFilePath,
);

// Get file metadata
final metadata = await FirebaseFileUploadService.getFileMetadata(
  folder: 'driver-documents',
  path: filePath,
);
```

## Security

### Firebase Storage Rules

Configure Firebase Storage security rules to:
- Require authentication for all uploads
- Validate file sizes and types
- Restrict access to user's own files
- Prevent unauthorized access

### Path-based Security

The service enforces security through:
- Structured file paths that include user/driver IDs
- Session validation before uploads
- File type and size validation
- Authentication checks

## Best Practices

1. **Unique Filenames**: Use timestamps and UUIDs to prevent conflicts
2. **Compression**: Enable compression for images to reduce bandwidth
3. **Cleanup**: Delete old files when updating profiles/documents  
4. **Progress Tracking**: Show upload progress for better user experience
5. **Error Handling**: Provide user-friendly error messages
6. **Validation**: Validate files client-side before upload

## Monitoring

Monitor storage usage through:
- Firebase Console Storage section
- Usage metrics and analytics
- Error logs and crash reports
- Storage and bandwidth costs

## Migration from Supabase Storage

If migrating from Supabase Storage:

1. **Code Changes**: Update all storage references to use `FirebaseFileUploadService`
2. **File Migration**: Transfer existing files from Supabase to Firebase
3. **URL Updates**: Update any stored file URLs in the database
4. **Security Rules**: Configure Firebase Storage security rules
5. **Testing**: Thoroughly test all upload/download functionality

## Cost Optimization

- Enable compression for images to reduce storage and bandwidth costs
- Implement file cleanup policies for temporary files
- Monitor usage patterns and optimize based on analytics
- Consider CDN integration for frequently accessed files