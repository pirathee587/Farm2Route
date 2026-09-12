import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/landing_providers.dart';
import '../widgets/landing_filter_pills.dart';
import '../widgets/landing_location_row.dart';
import '../widgets/landing_package_card.dart';
import '../widgets/landing_promo_carousel.dart';
import '../widgets/landing_search_card.dart';
import '../widgets/landing_top_agencies_section.dart';
import '../widgets/landing_top_bar.dart';

class PublicLandingScreen extends ConsumerStatefulWidget {
  const PublicLandingScreen({super.key});

  @override
  ConsumerState<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends ConsumerState<PublicLandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: _buildHomeTab(),
      ),
    );
  }

  Widget _buildHomeTab() {
    final packagesAsync = ref.watch(filteredPackagesProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(filteredPackagesProvider);
        ref.invalidate(featuredPromosProvider);
        ref.invalidate(topAgenciesProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP BAR (Profile icon, Logo, Login/Signup pills)
                const LandingTopBar(),

                // 2. LOCATION ROW ("Pickup near" -> "📍 Jaffna, Sri Lanka ▼" + 🔔)
                const LandingLocationRow(),
                const SizedBox(height: 4),

                // 3. SEARCH BAR (Pill expanding into 4 transport criteria fields)
                const LandingSearchCard(),
                const SizedBox(height: 4),

                // 4. FILTER PILLS ROW ([ 🏷️ Offers ] [ 💰 Price ▼ ] [ ⭐ Rating ] [ 📏 Nearest ])
                const LandingFilterPills(),
                const SizedBox(height: 10),

                // 6. PROMO/FEATURED CARD CAROUSEL ("🔥 Featured on Farm2Route")
                const LandingPromoCarousel(),
                const SizedBox(height: 18),

                // 7. SECOND HORIZONTAL SECTION ("⭐ Top Rated Agencies")
                const LandingTopAgenciesSection(),
                const SizedBox(height: 20),

                // 8. MAIN VERTICAL LIST HEADER ("📦 Transport Packages Near You")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📦 Transport Packages Near You',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compare transport options from trusted agencies',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // 8. MAIN VERTICAL LIST ITEMS (Only ACTIVE packages)
          packagesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
                child: Center(
                  child: Text(
                    'Unable to load transport packages at this time.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ),
            data: (packages) {
              if (packages.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Transport Packages Found',
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try modifying your cargo weight, produce type, or active filter chips.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(selectedCategoryProvider.notifier).state = 'All';
                            ref.read(filterPillsProvider.notifier).reset();
                            ref.read(searchCriteriaProvider.notifier).reset();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final package = packages[index];
                    return LandingPackageCard(package: package);
                  },
                  childCount: packages.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 28),
          ),
        ],
      ),
    );
  }
}
