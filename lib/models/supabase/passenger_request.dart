class PassengerRequest {

  PassengerRequest({
    required this.id,
    required this.passengerId,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    this.scheduledTime,
    required this.maxPrice,
    required this.paymentMethod,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PassengerRequest.fromJson(Map<String, dynamic> json) {
    return PassengerRequest(
      id: json['id'],
      passengerId: json['passenger_id'],
      originAddress: json['origin_address'],
      originLat: json['origin_lat']?.toDouble() ?? 0.0,
      originLng: json['origin_lng']?.toDouble() ?? 0.0,
      destinationAddress: json['destination_address'],
      destinationLat: json['destination_lat']?.toDouble() ?? 0.0,
      destinationLng: json['destination_lng']?.toDouble() ?? 0.0,
      scheduledTime: json['scheduled_time'] != null 
          ? DateTime.parse(json['scheduled_time']) 
          : null,
      maxPrice: json['max_price']?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  final String id;
  final String passengerId;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final DateTime? scheduledTime;
  final double maxPrice;
  final String paymentMethod;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'passenger_id': passengerId,
      'origin_address': originAddress,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_address': destinationAddress,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'max_price': maxPrice,
      'payment_method': paymentMethod,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  PassengerRequest copyWith({
    String? id,
    String? passengerId,
    String? originAddress,
    double? originLat,
    double? originLng,
    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,
    DateTime? scheduledTime,
    double? maxPrice,
    String? paymentMethod,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PassengerRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      originAddress: originAddress ?? this.originAddress,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      maxPrice: maxPrice ?? this.maxPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}