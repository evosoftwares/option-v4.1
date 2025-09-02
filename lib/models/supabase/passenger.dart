class Passenger {

  Passenger({
    required this.id,
    required this.userId,
    required this.averageRating,
    required this.totalTrips,
    required this.consecutiveCancellations,
    this.paymentMethodId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      averageRating: json['average_rating']?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      consecutiveCancellations: json['consecutive_cancellations'] as int? ?? 0,
      paymentMethodId: json['payment_method_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  final String id;
  final String userId;
  final double averageRating;
  final int totalTrips;
  final int consecutiveCancellations;
  final String? paymentMethodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'average_rating': averageRating,
      'total_trips': totalTrips,
      'consecutive_cancellations': consecutiveCancellations,
      'payment_method_id': paymentMethodId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  Passenger copyWith({
    String? id,
    String? userId,
    double? averageRating,
    int? totalTrips,
    int? consecutiveCancellations,
    String? paymentMethodId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Passenger(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      averageRating: averageRating ?? this.averageRating,
      totalTrips: totalTrips ?? this.totalTrips,
      consecutiveCancellations: consecutiveCancellations ?? this.consecutiveCancellations,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}