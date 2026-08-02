import 'package:freelancer/data/models/seller_job_alert_rule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SellerJobAlertService {
  static final _client = Supabase.instance.client;

  static Future<List<SellerJobAlertRule>> listMyRules() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('seller_job_alert_rules')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => SellerJobAlertRule.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<SellerJobAlertRule> createRule(SellerJobAlertRule draft) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final row = await _client
        .from('seller_job_alert_rules')
        .insert(draft.toInsertJson(sellerId: user.id))
        .select()
        .single();

    return SellerJobAlertRule.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<SellerJobAlertRule> updateRule(SellerJobAlertRule rule) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final row = await _client
        .from('seller_job_alert_rules')
        .update(rule.toUpdateJson())
        .eq('id', rule.id)
        .eq('seller_id', user.id)
        .select()
        .single();

    return SellerJobAlertRule.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<void> deleteRule(String ruleId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client
        .from('seller_job_alert_rules')
        .delete()
        .eq('id', ruleId)
        .eq('seller_id', user.id);
  }

  static Future<void> setEnabled(String ruleId, bool enabled) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client
        .from('seller_job_alert_rules')
        .update({'enabled': enabled})
        .eq('id', ruleId)
        .eq('seller_id', user.id);
  }
}
