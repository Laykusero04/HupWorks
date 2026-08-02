import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/data/models/seller_work_trust_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SellerWorkTrustService {
  static final _client = Supabase.instance.client;

  static Future<SellerWorkTrust> getPublicWorkTrust(String sellerId) async {
    if (sellerId.trim().isEmpty) return SellerWorkTrust.empty;

    try {
      final data = await _client.rpc(
        'get_seller_public_work_trust',
        params: {'p_seller_id': sellerId},
      );
      if (data is! Map) return SellerWorkTrust.empty;
      return SellerWorkTrust.fromJson(Map<String, dynamic>.from(data));
    } catch (e, st) {
      AppLogger.error('SellerWorkTrustService.getPublicWorkTrust', e, st);
      return SellerWorkTrust.empty;
    }
  }
}
