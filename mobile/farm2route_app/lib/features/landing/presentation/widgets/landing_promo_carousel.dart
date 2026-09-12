import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/landing_providers.dart';
import 'login_required_sheet.dart';

class LandingPromoCarousel extends ConsumerStatefulWidget {
  const LandingPromoCarousel({super.key});

  @override
  ConsumerState<LandingPromoCarousel> createState() => _LandingPromoCarouselState();
}

class _LandingPromoCarouselState extends ConsumerState<LandingPromoCarousel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollNext() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    const cardStep = 294.0; // 280 card width + 14 separator width

    if (currentOffset >= maxScroll - 10) {
      // Loop back to the beginning when at the end
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      final target = (currentOffset + cardStep).clamp(0.0, maxScroll);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(featuredPromosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '🔥 Featured on Farm2Route',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('featured_promos_view_all_button'),
                  onTap: _scrollNext,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Banner Carousel
        promosAsync.when(
          loading: () => const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (promos) {
            return SizedBox(
              height: 205,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: promos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final promo = promos[index];

                  return InkWell(
                    onTap: () {
                      LoginRequiredBottomSheet.show(
                        context,
                        title: 'Claim Promo Code ${promo.code ?? ""}',
                        subtitle: 'Sign in to apply ${promo.title} to your first agricultural haulage trip.',
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner Visual Card with Ribbon
                          Stack(
                            children: [
                              Container(
                                height: 135,
                                width: 280,
                                decoration: BoxDecoration(
                                  color: promo.bannerColor,
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      promo.bannerColor,
                                      promo.bannerColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: promo.bannerColor.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Subtle Decorative Background Icon
                                    Positioned(
                                      right: -10,
                                      bottom: -15,
                                      child: Icon(
                                        promo.icon,
                                        size: 110,
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    // Headline Content
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 36, 16, 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            promo.title,
                                            style: AppTextStyles.headingSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to unlock harvest discount',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Green "OFF" Ribbon Badge (like Uber Eats promotion badge)
                              Positioned(
                                top: 12,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    promo.ribbonBadge,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Below Card: Agency Name • ⭐ rating • ETA/availability tag
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  promo.agencyName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.star_rounded, size: 15, color: AppColors.starAmber),
                              const SizedBox(width: 2),
                              Text(
                                '${promo.rating} (${promo.reviewsCount}+)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '• ${promo.availabilityTag}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
