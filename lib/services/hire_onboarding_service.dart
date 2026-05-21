import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HireOnboardingService {
  static final _client = Supabase.instance.client;

  static Future<HireOnboardingPacket?> getPacketForOrder(
    String orderId, {
    bool sellerView = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    var query = _client
        .from('hire_onboarding_packets')
        .select()
        .eq('order_id', orderId);

    if (sellerView) {
      query = query.eq('status', 'published');
    }

    final row = await query.maybeSingle();
    if (row == null) return null;

    final acknowledged = sellerView
        ? await hasAcknowledged(orderId)
        : await _clientHasAckView(orderId);

    return HireOnboardingPacket.fromJson(
      Map<String, dynamic>.from(row),
      acknowledged: acknowledged,
    );
  }

  static Future<bool> _clientHasAckView(String orderId) async {
    final ack = await _client
        .from('hire_onboarding_acknowledgments')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();
    return ack != null;
  }

  static Future<String?> getOrderIdForJobOffer(String jobOfferId) async {
    final row = await _client
        .from('orders')
        .select('id')
        .eq('job_offer_id', jobOfferId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  static Future<HireOnboardingPacket?> getPacketForJobOffer(String jobOfferId) async {
    final orderId = await getOrderIdForJobOffer(jobOfferId);
    if (orderId == null) return null;
    return getPacketForOrder(orderId);
  }

  static Future<String> ensureDraft(String orderId) async {
    final result = await _client.rpc(
      'create_hire_onboarding_draft',
      params: {'p_order_id': orderId},
    );
    return result.toString();
  }

  static Future<void> updateDraftSections({
    required String packetId,
    required List<HireOnboardingSection> sections,
  }) async {
    await _client.from('hire_onboarding_packets').update({
      'sections': sections.map((s) => s.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', packetId);
  }

  static Future<void> publish(String packetId) async {
    await _client.rpc(
      'publish_hire_onboarding',
      params: {'p_packet_id': packetId},
    );
  }

  static Future<void> acknowledge(String orderId) async {
    await _client.rpc(
      'acknowledge_hire_onboarding',
      params: {'p_order_id': orderId},
    );
  }

  static Future<bool> hasAcknowledged(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final row = await _client
        .from('hire_onboarding_acknowledgments')
        .select('id')
        .eq('order_id', orderId)
        .eq('seller_id', user.id)
        .maybeSingle();
    return row != null;
  }

  /// Pre-fill "where" from job post location when body is empty.
  static List<HireOnboardingSection> sectionsWithLocationHint({
    required List<HireOnboardingSection> sections,
    String? location,
    String? locationType,
    String? attendanceMode,
  }) {
    var result = sections;
    if (location != null && location.trim().isNotEmpty) {
      result = result.map((s) {
        if (s.key != 'where' || s.body.trim().isNotEmpty) return s;
        final type = locationType?.trim();
        final prefix = type != null && type.isNotEmpty ? '$type — ' : '';
        return s.copyWith(body: '$prefix$location');
      }).toList();
    }
    result = result.map((s) {
      if (s.key != 'attendance' || s.body.trim().isNotEmpty) return s;
      final mode = attendanceMode ?? AttendanceMode.qrInOut;
      return s.copyWith(body: AttendanceMode.onboardingSectionBody(mode));
    }).toList();
    return result;
  }
}
