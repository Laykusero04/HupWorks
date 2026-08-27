import 'package:freelancer/data/models/hour_report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HourReportsService {
  static final _client = Supabase.instance.client;

  static const _select =
      '*, seller:profiles!seller_id(name)';

  static Future<List<HourReport>> listForOrder(String orderId) async {
    final data = await _client
        .from('hour_reports')
        .select(_select)
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data)
        .map(HourReport.fromJson)
        .toList();
  }

  static Future<void> accept(String reportId) async {
    await _client.rpc(
      'accept_hour_report',
      params: {'p_report_id': reportId},
    );
  }

  static Future<void> decline(String reportId, {String? reason}) async {
    await _client.rpc(
      'decline_hour_report',
      params: {
        'p_report_id': reportId,
        'p_reason': reason,
      },
    );
  }
}
