class CropModel {
  final String id;
  final String name;      // e.g., "Tomato" or displayName
  final String category;  // Crop type name (e.g., "Vegetables", "Fruits")
  final double acres;     // How much land is used
  final DateTime? plantingDate; // Sowing date
  final String? imageUrl; // For the photo
  final String? cropTypeName; // Full crop type name
  final String? cropDisplayName; // Display name from backend
  
  // Additional fields from backend
  final int? farmId;
  final String? farmName;
  final int? cropTypeId;
  final String? cropTypeDisplayName;
  final int? cropNameId;
  final String? cropName;
  final String? cropLocalName;
  final DateTime? harvestingDate;
  final String? cropStatus;
  final bool? isActive;

  CropModel({
    required this.id,
    required this.name,
    required this.category,
    required this.acres,
    this.plantingDate,
    this.imageUrl,
    this.cropTypeName,
    this.cropDisplayName,
    this.farmId,
    this.farmName,
    this.cropTypeId,
    this.cropTypeDisplayName,
    this.cropNameId,
    this.cropName,
    this.cropLocalName,
    this.harvestingDate,
    this.cropStatus,
    this.isActive,
  });

  // Factory for API
  factory CropModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return CropModel(
      id: json['id']?.toString() ?? '',
      name: json['cropDisplayName'] ?? json['cropName'] ?? '',
      category: json['cropTypeDisplayName'] ?? json['cropTypeName'] ?? '',
      acres: (json['areaAcres'] ?? 0.0).toDouble(),
      plantingDate: parseDate(json['sowingDate']),
      imageUrl: json['iconUrl'],
      cropTypeName: json['cropTypeName'],
      cropDisplayName: json['cropDisplayName'] ?? json['cropName'],
      farmId: json['farmId'],
      farmName: json['farmName'],
      cropTypeId: json['cropTypeId'],
      cropTypeDisplayName: json['cropTypeDisplayName'],
      cropNameId: json['cropNameId'],
      cropName: json['cropName'],
      cropLocalName: json['cropLocalName'],
      harvestingDate: parseDate(json['harvestingDate']),
      cropStatus: json['cropStatus'],
      isActive: json['isActive'],
    );
  }
}