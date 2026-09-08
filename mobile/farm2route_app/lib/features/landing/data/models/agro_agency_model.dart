import 'package:flutter/material.dart';

class AgroAgencyModel {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final int availableTrucks;
  final String district;
  final bool isVerified;
  final IconData icon;

  const AgroAgencyModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.availableTrucks,
    required this.district,
    this.isVerified = true,
    this.icon = Icons.local_shipping_rounded,
  });
}
