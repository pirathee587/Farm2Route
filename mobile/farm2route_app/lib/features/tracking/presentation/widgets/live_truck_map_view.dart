import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class LiveTruckMapView extends StatefulWidget {
  const LiveTruckMapView({super.key});

  @override
  State<LiveTruckMapView> createState() => _LiveTruckMapViewState();
}

class _LiveTruckMapViewState extends State<LiveTruckMapView>
    with SingleTickerProviderStateMixin {
  int _selectedTruckIndex = 0;
  late AnimationController _pulseController;
  Timer? _telemetryTimer;

  // Real-time animated simulation offsets for the selected lorry
  double _simProgress = 0.0;

  final List<Map<String, dynamic>> _truckFleet = [
    {
      'id': 'WP-NB-4412',
      'type': '10-Ton Isuzu Elf Refrigerated',
      'driver': 'Kamal Silva',
      'driverRating': '4.9',
      'driverPhone': '+94 77 123 4567',
      'origin': 'Dambulla DEC Hub',
      'destination': 'Colombo Manning Market',
      'currentLocation': 'Near Kurunegala Bypass (A6 Highway)',
      'speed': 54, // km/h
      'temp': '12.4°C',
      'tempStatus': 'Optimal Chilled',
      'eta': '1 hr 35 min',
      'distanceRemaining': '74 km',
      'cargo': '4,800 kg Leeks & Cabbage',
      'progress': 0.65,
      // Coordinate on relative map canvas: 0.0 to 1.0
      'coords': const Offset(0.48, 0.58),
      'heading': 215.0, // degrees
      'routeColor': const Color(0xFF06C167),
      'status': 'IN_TRANSIT',
    },
    {
      'id': 'CP-DA-8821',
      'type': '6-Ton Tata LPT Medium Hauler',
      'driver': 'Sunil Wickramasinghe',
      'driverRating': '4.8',
      'driverPhone': '+94 71 987 6543',
      'origin': 'Nuwara Eliya Central Hub',
      'destination': 'Dambulla DEC Hub',
      'currentLocation': 'Approaching Naula Pass (A9 Highway)',
      'speed': 42,
      'temp': 'Ambient 21°C',
      'tempStatus': 'Ventilated',
      'eta': '38 min',
      'distanceRemaining': '26 km',
      'cargo': '3,200 kg Carrots & Beetroots',
      'progress': 0.78,
      'coords': const Offset(0.56, 0.46),
      'heading': 345.0,
      'routeColor': const Color(0xFFE08A00),
      'status': 'IN_TRANSIT',
    },
    {
      'id': 'NP-GH-3190',
      'type': '4-Ton Mitsubishi Canter Express',
      'driver': 'Ramesh Rajan',
      'driverRating': '4.95',
      'driverPhone': '+94 76 555 8899',
      'origin': 'Jaffna Thirunelveli Market',
      'destination': 'Dambulla DEC Hub',
      'currentLocation': 'Medawachchiya A9 Junction',
      'speed': 62,
      'temp': 'Ambient 28°C',
      'tempStatus': 'Tarpaulin Covered',
      'eta': '1 hr 12 min',
      'distanceRemaining': '88 km',
      'cargo': '2,500 kg Red Onions & Chillies',
      'progress': 0.52,
      'coords': const Offset(0.52, 0.32),
      'heading': 175.0,
      'routeColor': const Color(0xFF1B4965),
      'status': 'IN_TRANSIT',
    },
    {
      'id': 'WP-LK-1029',
      'type': '14-Ton Multi-Axle Prime Mover',
      'driver': 'Priyantha Kumara',
      'driverRating': '4.7',
      'driverPhone': '+94 70 333 2211',
      'origin': 'Embilipitiya Agri Center',
      'destination': 'Meegoda Economic Centre',
      'currentLocation': 'Avissawella Highway Link',
      'speed': 48,
      'temp': 'Ambient 26°C',
      'tempStatus': 'Ventilated Open',
      'eta': '48 min',
      'distanceRemaining': '39 km',
      'cargo': '8,000 kg Papaya & Bananas',
      'progress': 0.60,
      'coords': const Offset(0.44, 0.76),
      'heading': 310.0,
      'routeColor': const Color(0xFF7C3AED),
      'status': 'IN_TRANSIT',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Subtle live telemetry pulse
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _simProgress = (_simProgress + 0.01) % 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTruck = _truckFleet[_selectedTruckIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar with Live Tracking Indicator
            _buildTopHeader(),

            // 2. Active Lorry Filter Selector Pills
            _buildTruckSelectorBar(),

            // 3. Interactive Map Canvas (Pan & Zoom)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // The Map Viewport
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECE9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6DFD8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(40),
                        minScale: 0.8,
                        maxScale: 2.5,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _SriLankaAgriRoutePainter(
                                fleet: _truckFleet,
                                selectedIndex: _selectedTruckIndex,
                                pulseValue: _pulseController.value,
                              ),
                              child: Container(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Floating Map Badges & Overlay Controls
                  Positioned(
                    top: 16,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE GPS • Sri Lanka Agri Arteries',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Re-Center / Zoom info
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),

                  // Live Speedometer Tag overlay
                  Positioned(
                    bottom: 16,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2E23).withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${activeTruck['speed']} km/h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 14,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.ac_unit_rounded, size: 16, color: Color(0xFF64B5F6)),
                          const SizedBox(width: 4),
                          Text(
                            '${activeTruck['temp']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Lorry Telemetry & Details Card (Bottom half)
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: _buildLorryTelemetryCard(activeTruck),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Header Bar
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: AppColors.primaryDark, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Live Fleet Radar',
                    style: AppTextStyles.headingMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tracking 4 Active Heavy Lorries Across Transit Corridors',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '4 Active',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Selector Bar for active trucks
  Widget _buildTruckSelectorBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8, left: 12),
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _truckFleet.length,
        itemBuilder: (context, index) {
          final truck = _truckFleet[index];
          final isSelected = _selectedTruckIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTruckIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B2E23) : const Color(0xFFF3F5F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    size: 16,
                    color: isSelected ? AppColors.primary : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    truck['id'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Telemetry and details card for the active truck
  Widget _buildLorryTelemetryCard(Map<String, dynamic> truck) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECE8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lorry ID, Vehicle Type & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        truck['id'] as String,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ON TIME',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    truck['type'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // ETA Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ETA',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      truck['eta'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Route Timeline (Origin -> Current -> Destination)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                        Container(width: 2, height: 28, color: const Color(0xFFDDDDDD)),
                        const Icon(Icons.location_on, size: 18, color: Color(0xFFE11900)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                truck['origin'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const Text('Dispatched 04:30 AM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Now: ${truck['currentLocation']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                truck['destination'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                '${truck['distanceRemaining']} left',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Telemetry Gauges Grid: Speed, Temp, Cargo Weight
          Row(
            children: [
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.speed_rounded,
                  title: 'Speed',
                  value: '${truck['speed']} km/h',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.thermostat_rounded,
                  title: 'Reefer Temp',
                  value: truck['temp'] as String,
                  color: const Color(0xFF0288D1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryTile(
                  icon: Icons.scale_rounded,
                  title: 'Cargo Payload',
                  value: '4.8 Tons',
                  color: const Color(0xFFE08A00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Driver Contact & Cargo Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      (truck['driver'] as String).substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck['driver'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: AppColors.starAmber),
                          const SizedBox(width: 2),
                          Text(
                            '${truck['driverRating']} (342 trips)',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling Driver ${truck['driver']} (${truck['driverPhone']})...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Call Driver'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Cargo Manifest Tag
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2EFE5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manifest: ${truck['cargo']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Canvas Painter rendering Sri Lanka's Agricultural Arteries & Live GPS Lorries
class _SriLankaAgriRoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> fleet;
  final int selectedIndex;
  final double pulseValue;

  _SriLankaAgriRoutePainter({
    required this.fleet,
    required this.selectedIndex,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Grid Background
    final gridPaint = Paint()
      ..color = const Color(0xFFD6DFD8).withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Island Silhouette (Stylized Sri Lanka outline)
    final islandPath = Path();
    islandPath.moveTo(w * 0.48, h * 0.08); // Jaffna Point Pedro
    islandPath.quadraticBezierTo(w * 0.42, h * 0.16, w * 0.36, h * 0.28); // Mannar / Kalpitiya
    islandPath.quadraticBezierTo(w * 0.32, h * 0.45, w * 0.34, h * 0.65); // Negombo / Colombo
    islandPath.quadraticBezierTo(w * 0.35, h * 0.82, w * 0.44, h * 0.92); // Galle / Matara
    islandPath.quadraticBezierTo(w * 0.58, h * 0.94, w * 0.66, h * 0.84); // Hambantota / Yala
    islandPath.quadraticBezierTo(w * 0.74, h * 0.62, w * 0.68, h * 0.44); // Batticaloa / Trincomalee
    islandPath.quadraticBezierTo(w * 0.62, h * 0.24, w * 0.52, h * 0.12); // Mullaitivu / Kilinochchi
    islandPath.close();

    final islandFill = Paint()
      ..color = const Color(0xFFF1F5F2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(islandPath, islandFill);

    final islandBorder = Paint()
      ..color = const Color(0xFFB5C4B7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(islandPath, islandBorder);

    // 3. Agricultural Corridors (Highways A1, A6, A9, Central Hubs)
    final highwayPaint = Paint()
      ..color = const Color(0xFF8BA692)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hub Nodes coordinates
    final dambullaHub = Offset(w * 0.52, h * 0.45);
    final colomboHub = Offset(w * 0.38, h * 0.68);
    final kandyHub = Offset(w * 0.54, h * 0.58);
    final nuwaraEliyaHub = Offset(w * 0.56, h * 0.66);
    final jaffnaHub = Offset(w * 0.48, h * 0.12);
    final kurunegalaHub = Offset(w * 0.46, h * 0.55);
    final embilipitiyaHub = Offset(w * 0.52, h * 0.82);

    // Corridor 1: A9 Highway (Jaffna -> Dambulla)
    final a9Path = Path()
      ..moveTo(jaffnaHub.dx, jaffnaHub.dy)
      ..quadraticBezierTo(w * 0.50, h * 0.28, dambullaHub.dx, dambullaHub.dy);
    canvas.drawPath(a9Path, highwayPaint);
    canvas.drawPath(a9Path, dashPaint);

    // Corridor 2: A6 Highway (Dambulla -> Kurunegala -> Colombo)
    final a6Path = Path()
      ..moveTo(dambullaHub.dx, dambullaHub.dy)
      ..lineTo(kurunegalaHub.dx, kurunegalaHub.dy)
      ..quadraticBezierTo(w * 0.42, h * 0.62, colomboHub.dx, colomboHub.dy);
    canvas.drawPath(a6Path, highwayPaint);
    canvas.drawPath(a6Path, dashPaint);

    // Corridor 3: Nuwara Eliya -> Kandy -> Dambulla
    final highlandPath = Path()
      ..moveTo(nuwaraEliyaHub.dx, nuwaraEliyaHub.dy)
      ..lineTo(kandyHub.dx, kandyHub.dy)
      ..lineTo(dambullaHub.dx, dambullaHub.dy);
    canvas.drawPath(highlandPath, highwayPaint);
    canvas.drawPath(highlandPath, dashPaint);

    // Corridor 4: Southern produce link (Embilipitiya -> Colombo)
    final southernPath = Path()
      ..moveTo(embilipitiyaHub.dx, embilipitiyaHub.dy)
      ..quadraticBezierTo(w * 0.46, h * 0.76, colomboHub.dx, colomboHub.dy);
    canvas.drawPath(southernPath, highwayPaint);
    canvas.drawPath(southernPath, dashPaint);

    // 4. Draw Major Agri Hub Nodes
    _drawHubNode(canvas, dambullaHub, 'Dambulla DEC Hub', true);
    _drawHubNode(canvas, colomboHub, 'Pettah Manning Market', false);
    _drawHubNode(canvas, nuwaraEliyaHub, 'Nuwara Eliya Hub', false);
    _drawHubNode(canvas, jaffnaHub, 'Jaffna Hub', false);
    _drawHubNode(canvas, kurunegalaHub, 'Kurunegala Junction', false);
    _drawHubNode(canvas, embilipitiyaHub, 'Embilipitiya', false);

    // 5. Draw Lorries with Live Location & Pulse radar
    for (int i = 0; i < fleet.length; i++) {
      final truck = fleet[i];
      final rawCoords = truck['coords'] as Offset;
      final truckPos = Offset(w * rawCoords.dx, h * rawCoords.dy);
      final isSelected = i == selectedIndex;
      final truckColor = truck['routeColor'] as Color;

      if (isSelected) {
        // Draw expanding GPS Radar Pulse Rings
        final pulsePaint = Paint()
          ..color = truckColor.withValues(alpha: (1.0 - pulseValue) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(truckPos, 14 + (pulseValue * 22), pulsePaint);

        final pulseInner = Paint()
          ..color = truckColor.withValues(alpha: (1.0 - pulseValue) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(truckPos, 8 + (pulseValue * 12), pulseInner);
      }

      // Truck Marker Pin
      final markerShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(truckPos.translate(0, 2), isSelected ? 16 : 12, markerShadow);

      final markerFill = Paint()
        ..color = isSelected ? const Color(0xFF1B2E23) : truckColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(truckPos, isSelected ? 15 : 11, markerFill);

      final markerBorder = Paint()
        ..color = isSelected ? AppColors.primary : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.8;
      canvas.drawCircle(truckPos, isSelected ? 15 : 11, markerBorder);

      // Inner vehicle icon / dot
      final centerDot = Paint()
        ..color = isSelected ? AppColors.primary : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(truckPos, isSelected ? 5 : 3.5, centerDot);

      // Lorry Registration Tag Callout
      final tagText = truck['id'] as String;
      final textSpan = TextSpan(
        text: tagText,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1B2E23),
          fontSize: isSelected ? 10 : 8.5,
          fontWeight: FontWeight.w800,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final tagBg = Paint()
        ..color = isSelected ? const Color(0xFF1B2E23) : Colors.white.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      final tagBorder = Paint()
        ..color = isSelected ? AppColors.primary : const Color(0xFFB0C2B4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final tagRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(truckPos.dx, truckPos.dy - (isSelected ? 26 : 20)),
          width: textPainter.width + 12,
          height: textPainter.height + 6,
        ),
        const Radius.circular(6),
      );

      canvas.drawRRect(tagRect, tagBg);
      canvas.drawRRect(tagRect, tagBorder);
      textPainter.paint(
        canvas,
        Offset(
          truckPos.dx - (textPainter.width / 2),
          truckPos.dy - (isSelected ? 26 : 20) - (textPainter.height / 2),
        ),
      );
    }
  }

  void _drawHubNode(Canvas canvas, Offset pos, String name, bool isMajorHub) {
    final hubFill = Paint()
      ..color = isMajorHub ? AppColors.primaryDark : const Color(0xFF4A6B53)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isMajorHub ? 6 : 4, hubFill);

    final hubRing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, isMajorHub ? 6 : 4, hubRing);

    if (isMajorHub) {
      final labelSpan = TextSpan(
        text: name,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          backgroundColor: Color(0xCCFFFFFF),
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(pos.dx + 8, pos.dy - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _SriLankaAgriRoutePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.pulseValue != pulseValue;
  }
}
