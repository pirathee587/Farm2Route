import '../../data/models/agro_agency_model.dart';
import '../../data/models/featured_promo_model.dart';
import '../../data/models/transport_package_model.dart';

abstract class LandingRepository {
  Future<List<TransportPackageModel>> getActivePackages({
    String? category,
    String? district,
    String? produceType,
    double? maxPrice,
    bool? offersOnly,
  });

  Future<List<FeaturedPromoModel>> getFeaturedPromos();

  Future<List<AgroAgencyModel>> getTopAgencies();
}
