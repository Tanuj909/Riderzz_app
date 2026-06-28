class DriverProfileModel {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String userStatus;
  final String approvalStatus;
  final String licenseNumber;
  final String vehicleNumber;
  final bool isOnline;
  final double rating;
  final int totalTrips;
  final DriverVehicleModel? vehicle;
  final List<DriverDocumentModel> documents;
  final String createdAt;
  
  // New API fields
  final String color;
  final int manufacturingYear;
  final String vehicleStatus;
  final String licenseExpiry;
  final String insuranceExpiry;
  final String bio;
  final String gender;
  final String? dob;
  final String? approvedAt;
  final String vehicleTypeName;

  DriverProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.userStatus,
    required this.approvalStatus,
    required this.licenseNumber,
    required this.vehicleNumber,
    required this.isOnline,
    required this.rating,
    required this.totalTrips,
    this.vehicle,
    required this.documents,
    required this.createdAt,
    
    // New fields
    this.color = '',
    this.manufacturingYear = 2020,
    this.vehicleStatus = 'PENDING',
    this.licenseExpiry = '',
    this.insuranceExpiry = '',
    this.bio = '',
    this.gender = 'MALE',
    this.dob,
    this.approvedAt,
    this.vehicleTypeName = '',
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    var docsList = json['documents'] as List? ?? [];
    List<DriverDocumentModel> parsedDocs = docsList
        .map((d) => DriverDocumentModel.fromJson(Map<String, dynamic>.from(d)))
        .toList();

    double ratingValue = 0.0;
    if (json['rating'] != null) {
      ratingValue = double.tryParse(json['rating'].toString()) ?? 0.0;
    }

    return DriverProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      name: json['fullName'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      userStatus: json['userStatus'] as String? ?? 'INACTIVE',
      approvalStatus: json['approvalStatus'] as String? ?? 'PENDING',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      vehicleNumber: json['registrationNumber'] as String? ?? json['vehicleNumber'] as String? ?? '',
      isOnline: json['online'] as bool? ?? json['isOnline'] as bool? ?? false,
      rating: ratingValue,
      totalTrips: json['completedTrips'] as int? ?? json['totalTrips'] as int? ?? 0,
      vehicle: json['vehicle'] != null
          ? DriverVehicleModel.fromJson(Map<String, dynamic>.from(json['vehicle']))
          : (json['vehicleId'] != null
              ? DriverVehicleModel(
                  id: json['vehicleId'] as int,
                  vehicleTypeId: json['vehicleTypeId'] as int? ?? 0,
                  vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
                  make: json['make'] as String? ?? '',
                  model: json['model'] as String? ?? '',
                  perKmRate: 0.0,
                  status: json['vehicleStatus'] as String? ?? 'PENDING',
                  maxWeightKg: 0,
                  createdAt: '',
                )
              : null),
      documents: parsedDocs,
      createdAt: json['createdAt'] as String? ?? '',
      color: json['color'] as String? ?? '',
      manufacturingYear: json['manufacturingYear'] as int? ?? 2020,
      vehicleStatus: json['vehicleStatus'] as String? ?? 'PENDING',
      licenseExpiry: json['licenseExpiry'] as String? ?? '',
      insuranceExpiry: json['insuranceExpiry'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String? ?? 'MALE',
      dob: json['dob'] as String?,
      approvedAt: json['approvedAt'] as String?,
      vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
    );
  }
}

class DriverVehicleModel {
  final int id;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final String make;
  final String model;
  final double perKmRate;
  final String status;
  final int maxWeightKg;
  final String? rejectionReason;
  final String? approvedAt;
  final String createdAt;

  DriverVehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.make,
    required this.model,
    required this.perKmRate,
    required this.status,
    required this.maxWeightKg,
    this.rejectionReason,
    this.approvedAt,
    required this.createdAt,
  });

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    double rateValue = 0.0;
    if (json['perKmRate'] != null) {
      rateValue = double.tryParse(json['perKmRate'].toString()) ?? 0.0;
    }

    return DriverVehicleModel(
      id: json['id'] as int? ?? 0,
      vehicleTypeId: json['vehicleTypeId'] as int? ?? 0,
      vehicleTypeName: json['vehicleTypeName'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      perKmRate: rateValue,
      status: json['status'] as String? ?? 'PENDING',
      maxWeightKg: json['maxWeightKg'] as int? ?? 0,
      rejectionReason: json['rejectionReason'] as String?,
      approvedAt: json['approvedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class DriverDocumentModel {
  final int id;
  final String docType;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final String uploadedAt;

  DriverDocumentModel({
    required this.id,
    required this.docType,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
    required this.uploadedAt,
  });

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      id: json['documentId'] as int? ?? json['id'] as int? ?? 0,
      docType: json['documentType'] as String? ?? json['docType'] as String? ?? '',
      fileUrl: json['documentUrl'] as String? ?? json['fileUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      rejectionReason: json['rejectionReason'] as String?,
      uploadedAt: json['uploadedAt'] as String? ?? '',
    );
  }
}
