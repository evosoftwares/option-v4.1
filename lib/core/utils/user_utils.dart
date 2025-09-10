class UserUtils {
  /// Safely extracts user's full name, handling corrupted data
  /// 
  /// Returns a clean name, attempts to derive from email, or fallback if corrupted
  static String getSafeName(String? fullName, {String? email, String fallback = 'Usuário'}) {
    if (fullName == null || fullName.isEmpty) {
      return _getNameFromEmail(email) ?? fallback;
    }
    
    // Check if the name contains JSON-like content (corrupted data)
    if (fullName.contains('{') && fullName.contains('}')) {
      return _getNameFromEmail(email) ?? fallback;
    }
    
    // Check for specific error messages that might be stored in name field
    if (fullName.contains('missing_passenger_records') || 
        fullName.contains('issue') ||
        fullName.contains('count') ||
        fullName.contains('error')) {
      return _getNameFromEmail(email) ?? fallback;
    }
    
    // Check for other database query-like content
    if (fullName.toLowerCase().contains('select') ||
        fullName.toLowerCase().contains('from') ||
        fullName.toLowerCase().contains('where')) {
      return _getNameFromEmail(email) ?? fallback;
    }
    
    return fullName.trim();
  }

  /// Attempts to derive a name from email address
  /// 
  /// Extracts the part before @ and formats it as a readable name
  static String? _getNameFromEmail(String? email) {
    if (email == null || email.isEmpty || !email.contains('@')) {
      return null;
    }
    
    final namePart = email.split('@')[0];
    
    // Skip if it looks like a generic/system email
    if (namePart.toLowerCase().contains('user') ||
        namePart.toLowerCase().contains('test') ||
        namePart.toLowerCase().contains('admin') ||
        namePart.isNumeric()) {
      return null;
    }
    
    // Convert to readable format
    // Replace dots, underscores, dashes with spaces and capitalize
    final cleanName = namePart
        .replaceAll(RegExp('[._-]'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? 
             word[0].toUpperCase() + word.substring(1).toLowerCase() : '',)
        .join(' ')
        .trim();
    
    return cleanName.isNotEmpty ? cleanName : null;
  }
}

extension on String {
  bool isNumeric() => double.tryParse(this) != null;
}