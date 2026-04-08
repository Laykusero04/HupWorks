import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  static final _client = Supabase.instance.client;

  /// Fetch all transactions for current user
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create a deposit transaction
  static Future<Map<String, dynamic>> createDeposit({
    required double amount,
    required String gateway,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client.from('transactions').insert({
      'user_id': user.id,
      'type': 'deposit',
      'amount': amount,
      'status': 'pending',
      'gateway': gateway,
    }).select().single();

    return data;
  }

  /// Fetch deposit history (type = deposit only)
  static Future<List<Map<String, dynamic>>> getDepositHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .eq('type', 'deposit')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
