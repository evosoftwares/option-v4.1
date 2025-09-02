# Supabase Storage Buckets Guide

This document provides an overview of the Supabase Storage buckets used in the project and guidelines for developers on how to interact with them.

## Buckets

### 1. user-photos
- **ID:** user-photos
- **Name:** user-photos
- **Public:** Yes
- **Type:** STANDARD
- **File Size Limit:** None (null)
- **Allowed MIME Types:**
  - image/jpeg
  - image/png
  - image/webp
  - image/jpg
- **Created At:** 2025-08-29T02:40:55.764Z
- **Updated At:** 2025-08-29T02:40:55.764Z

## Developer Guidelines

### Uploading Files

1. **Authentication:** Ensure the user is authenticated with Supabase Auth before attempting to upload files.
2. **File Validation:** Before uploading, validate the file size and MIME type on the client-side to match the bucket's restrictions.
3. **File Path:** Use a clear and consistent naming convention for files. For example, for user photos, you might use:
   `user-photos/{user_id}/{filename}.{extension}`

### Downloading Files

1. **Public Access:** Files in public buckets can be accessed directly via URL:
   `https://qlbwacmavngtonauxnte.supabase.co/storage/v1/object/public/{bucket_name}/{file_path}`

### Error Handling

- **MIME Type Error:** Handle the error when a file type is not allowed. Show a user-friendly message listing the accepted file types.
- **Network Errors:** Implement retry logic for network-related errors during upload or download.

### Example Code (Flutter/Dart)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Upload a file
Future<String?> uploadUserPhoto(Uint8List fileBytes, String fileName, String userId) async {
 try {
   final fileOptions = FileOptions(
     cacheControl: '3600',
     upsert: false,
     contentType: 'image/jpeg', // Or determine dynamically
   );

   final response = await supabase.storage
       .from('user-photos')
       .uploadBinary(
         'user-photos/$userId/$fileName',
         fileBytes,
         fileOptions: fileOptions,
       );

   return response; // Path to the uploaded file
 } on StorageException catch (error) {
   // Handle specific storage errors (e.g., mime type)
   print('Storage error: ${error.message}');
   return null;
 } catch (error) {
   // Handle other errors
   print('Unexpected error: $error');
   return null;
 }
}

// Get public URL for a file
String getUserPhotoUrl(String filePath) {
 return supabase.storage.from('user-photos').getPublicUrl(filePath);
}

// Download a file
Future<Uint8List?> downloadUserPhoto(String filePath) async {
 try {
   final data = await supabase.storage.from('user-photos').download(filePath);
   return data; // Uint8List of the file content
 } on StorageException catch (error) {
   print('Download error: ${error.message}');
   return null;
 } catch (error) {
   print('Unexpected error: $error');
   return null;
 }
}
```

### Best Practices

1.  **Organize Files:** Use folders (prefixes in the file path) to organize files within a bucket.
2.  **Unique Filenames:** Generate unique filenames to prevent collisions (e.g., using UUIDs or timestamps).
3.  **Security:** Regularly review bucket permissions. Although these buckets are public, ensure that file paths are not easily guessable if the content should not be publicly accessible by default.
4.  **Cleanup:** Implement a strategy for deleting unused or temporary files to manage storage costs and keep buckets organized.