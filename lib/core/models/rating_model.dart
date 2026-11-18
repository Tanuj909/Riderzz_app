class RatingItemModel {
  final int id;
  final int bookingId;
  final String? bookingNumber;
  final int? driverId;
  final String ratingType;
  final int stars;
  final String? review;
  final String? createdAt;
  final String? updatedAt;

  RatingItemModel({
    required this.id,
    required this.bookingId,
    this.bookingNumber,
    this.driverId,
    required this.ratingType,
    required this.stars,
    this.review,
    this.createdAt,
    this.updatedAt,
  });

  factory RatingItemModel.fromJson(Map<String, dynamic> json) {
    return RatingItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookingId: json['bookingId'] is int
          ? json['bookingId']
          : int.tryParse(json['bookingId']?.toString() ?? '0') ?? 0,
      bookingNumber: json['bookingNumber']?.toString(),
      driverId: json['driverId'] != null
          ? (json['driverId'] is int
              ? json['driverId']
              : int.tryParse(json['driverId']?.toString() ?? '0'))
          : null,
      ratingType: json['ratingType']?.toString() ?? 'CUSTOMER_TO_DRIVER',
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      review: json['review']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'driverId': driverId,
      'ratingType': ratingType,
      'stars': stars,
      'review': review,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class BookingRatingData {
  final int bookingId;
  final String? bookingNumber;
  final RatingItemModel? customerToDriverRating;

  BookingRatingData({
    required this.bookingId,
    this.bookingNumber,
    this.customerToDriverRating,
  });

  factory BookingRatingData.fromJson(Map<String, dynamic> json) {
    return BookingRatingData(
      bookingId: json['bookingId'] is int
          ? json['bookingId']
          : int.tryParse(json['bookingId']?.toString() ?? '0') ?? 0,
      bookingNumber: json['bookingNumber']?.toString(),
      customerToDriverRating: json['customerToDriverRating'] != null &&
              json['customerToDriverRating'] is Map
          ? RatingItemModel.fromJson(
              Map<String, dynamic>.from(json['customerToDriverRating'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'customerToDriverRating': customerToDriverRating?.toJson(),
    };
  }
}

class DriverRatingSummary {
  final double averageRating;
  final int ratingCount;

  DriverRatingSummary({
    required this.averageRating,
    required this.ratingCount,
  });

  factory DriverRatingSummary.fromJson(Map<String, dynamic> json) {
    return DriverRatingSummary(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }
}

