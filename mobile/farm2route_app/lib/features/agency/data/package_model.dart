class PackageModel {
  final String id;
  final String title;
  final String description;
  final String packageType;
  final String basePrice;
  final String pricePerKm;
  final String pricePerKg;
  final String maxWeightKg;
  final String routeOrigin;
  final String routeDestination;
  final List<String> scheduleDays;
  final bool isActive;
  final String estimatedCost;
  final String createdAt;

  const PackageModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.packageType,
      required this.basePrice,
      required this.pricePerKm,
      required this.pricePerKg,
      required this.maxWeightKg,
      required this.routeOrigin,
      required this.routeDestination,
      required this.scheduleDays,
      required this.isActive,
      required this.estimatedCost,
      required this.createdAt});

  factory PackageModel.fromJson(Map<String, dynamic> json) => PackageModel(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        packageType: '${json['packageType'] ?? 'STANDARD'}',
        basePrice: '${json['basePrice'] ?? '0'}',
        pricePerKm: '${json['pricePerKm'] ?? '0'}',
        pricePerKg: '${json['pricePerKg'] ?? '0'}',
        maxWeightKg: '${json['maxWeightKg'] ?? '0'}',
        routeOrigin: '${json['routeOrigin'] ?? ''}',
        routeDestination: '${json['routeDestination'] ?? ''}',
        scheduleDays: (json['scheduleDays'] as List? ?? const [])
            .map((x) => '$x')
            .toList(),
        isActive: json['isActive'] == true,
        estimatedCost:
            '${json['estimatedCost'] ?? json['estimatedPrice'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
      );
}
