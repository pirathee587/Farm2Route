import 'package:flutter/material.dart';

class FeaturedPromoModel {
  final String id;
  final String title;
  final String ribbonBadge;
  final String agencyName;
  final double rating;
  final int reviewsCount;
  final String availabilityTag;
  final Color bannerColor;
  final IconData icon;
  final String? code;

  const FeaturedPromoModel({
    required this.id,
    required this.title,
    required this.ribbonBadge,
    required this.agencyName,
    required this.rating,
    required this.reviewsCount,
    required this.availabilityTag,
    required this.bannerColor,
    required this.icon,
    this.code,
  });
}
