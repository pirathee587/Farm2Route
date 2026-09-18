class AdminStatsModel {
  final int totalUsers;
  final int totalFarmers;
  final int totalAgencies;
  final int totalDrivers;
  final int pendingKycs;
  final int activeBookings;
  final int openIncidents;

  const AdminStatsModel({
    required this.totalUsers,
    required this.totalFarmers,
    required this.totalAgencies,
    required this.totalDrivers,
    required this.pendingKycs,
    required this.activeBookings,
    required this.openIncidents,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalFarmers: (json['totalFarmers'] as num?)?.toInt() ?? 0,
      totalAgencies: (json['totalAgencies'] as num?)?.toInt() ?? 0,
      totalDrivers: (json['totalDrivers'] as num?)?.toInt() ?? 0,
      pendingKycs: (json['pendingKycs'] as num?)?.toInt() ?? 0,
      activeBookings: (json['activeBookings'] as num?)?.toInt() ?? 0,
      openIncidents: (json['openIncidents'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalFarmers': totalFarmers,
      'totalAgencies': totalAgencies,
      'totalDrivers': totalDrivers,
      'pendingKycs': pendingKycs,
      'activeBookings': activeBookings,
      'openIncidents': openIncidents,
    };
  }
}
