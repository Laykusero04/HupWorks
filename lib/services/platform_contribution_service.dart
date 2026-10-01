import 'package:freelancer/data/models/platform_contribution.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformContributionService {
  static final _client = Supabase.instance.client;

  /// Signed-in user's share of completed platform work.
  /// Totals only — see migrations/0049_platform_contribution.sql.
  static Future<PlatformContribution> getMine() async {
    final data = await _client.rpc('my_platform_contribution');
    if (data is Map) {
      return PlatformContribution.fromJson(Map<String, dynamic>.from(data));
    }
    return PlatformContribution.empty;
  }
}
