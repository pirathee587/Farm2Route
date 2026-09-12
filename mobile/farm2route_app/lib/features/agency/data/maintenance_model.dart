class MaintenanceModel {
  final String id;
  final String vehicleId;
  final String maintenanceType;
  final String title;
  final String description;
  final String cost;
  final String maintenanceDate;
  final String nextDueDate;
  final String serviceCenterName;
  final String invoiceDocumentUrl;
  final String status;
  final String createdAt;
  final String updatedAt;

  const MaintenanceModel(
      {required this.id,
      required this.vehicleId,
      required this.maintenanceType,
      required this.title,
      required this.description,
      required this.cost,
      required this.maintenanceDate,
      required this.nextDueDate,
      required this.serviceCenterName,
      required this.invoiceDocumentUrl,
      required this.status,
      required this.createdAt,
      required this.updatedAt});

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) =>
      MaintenanceModel(
        id: '${json['id'] ?? ''}',
        vehicleId: '${json['vehicleId'] ?? ''}',
        maintenanceType: '${json['maintenanceType'] ?? ''}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        cost: '${json['cost'] ?? '0'}',
        maintenanceDate: '${json['maintenanceDate'] ?? ''}',
        nextDueDate: '${json['nextDueDate'] ?? ''}',
        serviceCenterName: '${json['serviceCenterName'] ?? ''}',
        invoiceDocumentUrl: '${json['invoiceDocumentUrl'] ?? ''}',
        status: '${json['status'] ?? 'SCHEDULED'}',
        createdAt: '${json['createdAt'] ?? ''}',
        updatedAt: '${json['updatedAt'] ?? ''}',
      );
}
