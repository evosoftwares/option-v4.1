class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.expiryDate,
    required this.status,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.isCurrent,
    required this.createdAt,
    this.updatedAt,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) => v == null
        ? null
        : (v is num ? v.toInt() : int.tryParse(v.toString()));

    return DriverDocument(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      documentType: json['document_type'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: _toInt(json['file_size']),
      mimeType: json['mime_type'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      isCurrent: json['is_current'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  final String id;
  final String driverId;
  final String documentType;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final DateTime? expiryDate;
  final String status;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'document_type': documentType,
        'file_url': fileUrl,
        'file_size': fileSize,
        'mime_type': mimeType,
        'expiry_date': expiryDate?.toIso8601String(),
        'status': status,
        'rejection_reason': rejectionReason,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'is_current': isCurrent,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  DriverDocument copyWith({
    String? id,
    String? driverId,
    String? documentType,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    DateTime? expiryDate,
    String? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      documentType: documentType ?? this.documentType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverDocument &&
        other.id == id &&
        other.driverId == driverId &&
        other.documentType == documentType &&
        other.fileUrl == fileUrl &&
        other.fileSize == fileSize &&
        other.mimeType == mimeType &&
        other.expiryDate == expiryDate &&
        other.status == status &&
        other.rejectionReason == rejectionReason &&
        other.reviewedBy == reviewedBy &&
        other.reviewedAt == reviewedAt &&
        other.isCurrent == isCurrent &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      driverId,
      documentType,
      fileUrl,
      fileSize,
      mimeType,
      expiryDate,
      status,
      rejectionReason,
      reviewedBy,
      reviewedAt,
      isCurrent,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'DriverDocument(id: $id, driverId: $driverId, documentType: $documentType, status: $status, isCurrent: $isCurrent)';
  }
}

// Enum para tipos de documentos
enum DocumentType {
  cnhFront('CNH_FRONT'),
  cnhBack('CNH_BACK'),
  crlv('CRLV'),
  vehicleFront('VEHICLE_FRONT'),
  vehicleBack('VEHICLE_BACK'),
  vehicleLeft('VEHICLE_LEFT'),
  vehicleRight('VEHICLE_RIGHT'),
  vehicleInterior('VEHICLE_INTERIOR');

  const DocumentType(this.value);
  final String value;

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid document type: $value'),
    );
  }
}

// Enum para status dos documentos
enum DocumentStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  expired('EXPIRED');

  const DocumentStatus(this.value);
  final String value;

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid document status: $value'),
    );
  }
}