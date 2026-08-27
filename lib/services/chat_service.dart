import 'dart:io';
import 'package:freelancer/data/models/chat_inbox_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _client = Supabase.instance.client;

  /// Get or create a conversation between the current user and another user.
  /// Determines client/seller roles from profiles.
  static Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if conversation already exists between these two users
    final existing = await _client
        .from('conversations')
        .select()
        .or('and(client_id.eq.${user.id},seller_id.eq.$otherUserId),and(client_id.eq.$otherUserId,seller_id.eq.${user.id})')
        .maybeSingle();

    if (existing != null) return existing;

    // Determine who is client and who is seller
    final myProfile = await _client.from('profiles').select('role').eq('id', user.id).single();
    final myRole = myProfile['role'] as String;

    final clientId = myRole == 'client' ? user.id : otherUserId;
    final sellerId = myRole == 'seller' ? user.id : otherUserId;

    final newConversation = await _client.from('conversations').insert({
      'client_id': clientId,
      'seller_id': sellerId,
    }).select().single();

    return newConversation;
  }

  /// Job-board applications: the **buyer** (job poster) is always `client_id`,
  /// the **applicant** (current user) is always `seller_id`, regardless of
  /// what `profiles.role` says. Fixes freelancers whose profile.role is still
  /// `client` after signing up as a seller.
  static Future<Map<String, dynamic>> getOrCreateJobApplicationConversation({
    required String buyerUserId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (buyerUserId == user.id) {
      throw Exception('Cannot start a job application conversation with yourself');
    }

    const clientIdField = 'client_id';
    const sellerIdField = 'seller_id';
    final clientId = buyerUserId;
    final sellerId = user.id;

    final existing = await _client
        .from('conversations')
        .select()
        .or(
          'and($clientIdField.eq.$clientId,$sellerIdField.eq.$sellerId),'
          'and($clientIdField.eq.$sellerId,$sellerIdField.eq.$clientId)',
        )
        .maybeSingle();

    if (existing != null) return existing;

    return await _client.from('conversations').insert({
      'client_id': clientId,
      'seller_id': sellerId,
    }).select().single();
  }

  /// Fetch conversation list for the current user, joined with profile info
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('conversations')
        .select('*, client:profiles!conversations_client_id_fkey(*), seller:profiles!conversations_seller_id_fkey(*)')
        .or('client_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Batch relationship tags for inbox filters (Applications / Active / Past).
  ///
  /// Keys are conversation ids. Only conversations in [conversationIds] are returned.
  static Future<Map<String, ConversationInboxMeta>> getInboxMetaByConversation({
    required List<({String id, String clientId, String sellerId})> conversations,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || conversations.isEmpty) return {};

    final byPair = <String, String>{};
    for (final c in conversations) {
      byPair[_pairKey(c.clientId, c.sellerId)] = c.id;
    }

    final metaByConversation = {
      for (final c in conversations) c.id: ConversationInboxMeta.empty,
    };

    final ordersFuture = _client
        .from('orders')
        .select('id, status, client_id, seller_id')
        .or('client_id.eq.${user.id},seller_id.eq.${user.id}');

    final offersFuture = _client
        .from('job_offers')
        .select('id, status, seller_id, job_posts!job_post_id(client_id, status)')
        .eq('status', 'pending')
        .eq('seller_id', user.id);

    // Pending offers where I'm the client are filtered client-side via job_posts.
    final clientOffersFuture = _client
        .from('job_offers')
        .select('id, status, seller_id, job_posts!job_post_id!inner(client_id, status)')
        .eq('status', 'pending')
        .eq('job_posts.client_id', user.id);

    final results = await Future.wait([
      ordersFuture,
      offersFuture,
      clientOffersFuture,
    ]);

    final orders = List<Map<String, dynamic>>.from(results[0] as List);
    final sellerSideOffers = List<Map<String, dynamic>>.from(results[1] as List);
    final clientSideOffers = List<Map<String, dynamic>>.from(results[2] as List);

    for (final order in orders) {
      final clientId = order['client_id'] as String?;
      final sellerId = order['seller_id'] as String?;
      if (clientId == null || sellerId == null) continue;
      final convId = byPair[_pairKey(clientId, sellerId)];
      if (convId == null) continue;

      final status = ((order['status'] as String?) ?? '').toLowerCase();
      final current = metaByConversation[convId] ?? ConversationInboxMeta.empty;
      final isActive = const {
        'pending',
        'active',
        'delivered',
        'cancellation_requested',
      }.contains(status);
      final isPast = status == 'completed' || status == 'cancelled';

      metaByConversation[convId] = ConversationInboxMeta(
        hasPendingApplication: current.hasPendingApplication,
        hasActiveContract: current.hasActiveContract || isActive,
        hasPastContract: current.hasPastContract || isPast,
      );
    }

    void applyOffer(Map<String, dynamic> offer) {
      final sellerId = offer['seller_id'] as String?;
      final jobPost = offer['job_posts'];
      Map<String, dynamic>? jp;
      if (jobPost is Map<String, dynamic>) {
        jp = jobPost;
      } else if (jobPost is Map) {
        jp = Map<String, dynamic>.from(jobPost);
      }
      final clientId = jp?['client_id'] as String?;
      if (clientId == null || sellerId == null) return;
      // Only count applications on still-open jobs as "Applications".
      if ((jp?['status'] as String?)?.toLowerCase() != 'open') return;

      final convId = byPair[_pairKey(clientId, sellerId)];
      if (convId == null) return;
      final current = metaByConversation[convId] ?? ConversationInboxMeta.empty;
      metaByConversation[convId] = ConversationInboxMeta(
        hasPendingApplication: true,
        hasActiveContract: current.hasActiveContract,
        hasPastContract: current.hasPastContract,
      );
    }

    for (final offer in sellerSideOffers) {
      applyOffer(offer);
    }
    for (final offer in clientSideOffers) {
      applyOffer(offer);
    }

    return metaByConversation;
  }

  static String _pairKey(String clientId, String sellerId) =>
      '$clientId|$sellerId';

  /// Fetch messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(id, name, profile_image_url)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Send a text message
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
    String messageType = 'text',
    String? jobOfferId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final message = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'content': content,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'message_type': messageType,
      if (jobOfferId != null) 'job_offer_id': jobOfferId,
    }).select('*, sender:profiles!messages_sender_id_fkey(id, name, profile_image_url)').single();

    // Update conversation's last_message and last_message_at
    await _client.from('conversations').update({
      'last_message': content.isNotEmpty ? content : 'Attachment',
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    return message;
  }

  /// Subscribe to new messages in a conversation (Supabase Realtime)
  static RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> message) onNewMessage,
  }) {
    final channel = _client.channel('messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation list updates
  static RealtimeChannel subscribeToConversations({
    required void Function() onUpdate,
  }) {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channel = _client.channel('conversations:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Mark messages as read in a conversation
  static Future<void> markMessagesAsRead(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('messages')
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('read', false);
  }

  /// Get unread message count for a conversation
  static Future<int> getUnreadCount(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final data = await _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('read', false);

    return (data as List).length;
  }

  /// Upload a file attachment to Supabase Storage
  static Future<String> uploadAttachment(File file, String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';

    await _client.storage
        .from('chat-attachments')
        .upload(fileName, file);

    final publicUrl = _client.storage
        .from('chat-attachments')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  /// Get the file extension type (image, document, etc.)
  static String getAttachmentType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return 'document';
    return 'file';
  }

  /// Fetch a single conversation with participant profiles.
  static Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return await _client
        .from('conversations')
        .select(
          '*, client:profiles!conversations_client_id_fkey(*), '
          'seller:profiles!conversations_seller_id_fkey(*)',
        )
        .eq('id', conversationId)
        .maybeSingle();
  }

  /// Unread counts keyed by conversation id for the current user.
  static Future<Map<String, int>> getUnreadCountsByConversation() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final convRows = await _client
        .from('conversations')
        .select('id')
        .or('client_id.eq.${user.id},seller_id.eq.${user.id}');

    final conversationIds = (convRows as List)
        .map((row) => row['id'] as String)
        .toList();
    if (conversationIds.isEmpty) return {};

    final unreadRows = await _client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', conversationIds)
        .neq('sender_id', user.id)
        .eq('read', false);

    final counts = <String, int>{};
    for (final row in unreadRows as List) {
      final id = row['conversation_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// Total unread messages across all conversations for the current user.
  static Future<int> getTotalUnreadCount() async {
    final counts = await getUnreadCountsByConversation();
    return counts.values.fold<int>(0, (sum, n) => sum + n);
  }

  /// Most recent open order between conversation participants (for chat context).
  static Future<Map<String, dynamic>?> getActiveOrderForConversation({
    required String clientId,
    required String sellerId,
  }) async {
    return await _client
        .from('orders')
        .select(
          'id, status, delivery_deadline, '
          'job_offers(job_posts(title)), services(title)',
        )
        .eq('client_id', clientId)
        .eq('seller_id', sellerId)
        .inFilter('status', ['pending', 'active', 'delivered', 'cancellation_requested'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Active contracts + pending applications shared by a client–seller pair.
  static Future<({List<Map<String, dynamic>> orders, List<Map<String, dynamic>> jobOffers})>
      getThreadContextRows({
    required String clientId,
    required String sellerId,
  }) async {
    final ordersFuture = _client
        .from('orders')
        .select(
          'id, status, delivery_deadline, created_at, '
          'job_offers(id, job_posts(id, title)), services(title)',
        )
        .eq('client_id', clientId)
        .eq('seller_id', sellerId)
        .inFilter(
          'status',
          ['pending', 'active', 'delivered', 'cancellation_requested'],
        )
        .order('created_at', ascending: false);

    final offersFuture = _client
        .from('job_offers')
        .select(
          'id, status, price, created_at, '
          'job_posts!job_post_id(id, title, status, client_id)',
        )
        .eq('seller_id', sellerId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final results = await Future.wait([ordersFuture, offersFuture]);
    final orders = List<Map<String, dynamic>>.from(results[0] as List);
    final rawOffers = List<Map<String, dynamic>>.from(results[1] as List);

    // Keep only offers on this client's job posts that are still open.
    final offers = rawOffers.where((offer) {
      final jobPost = offer['job_posts'];
      Map<String, dynamic>? jp;
      if (jobPost is Map<String, dynamic>) {
        jp = jobPost;
      } else if (jobPost is Map) {
        jp = Map<String, dynamic>.from(jobPost);
      }
      if (jp == null) return false;
      if (jp['client_id'] != clientId) return false;
      return (jp['status'] as String?)?.toLowerCase() == 'open';
    }).toList();

    return (orders: orders, jobOffers: offers);
  }

  /// Subscribe to incoming messages for unread badge refresh.
  static RealtimeChannel subscribeToIncomingMessages({
    required void Function() onNewMessage,
  }) {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channel = _client.channel('incoming_messages:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'] as String?;
            if (senderId != null && senderId != user.id) {
              onNewMessage();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (_) => onNewMessage(),
        )
        .subscribe();

    return channel;
  }

  /// Fetch a job offer with job post and seller profile (for chat bid cards).
  static Future<Map<String, dynamic>?> getJobOffer(String offerId) async {
    final data = await _client
        .from('job_offers')
        .select(
          '*, profiles:seller_id(name, profile_image_url), '
          'job_posts(id, title, status, client_id, workers_needed)',
        )
        .eq('id', offerId)
        .maybeSingle();
    return data;
  }

  /// All offers on the same job post (for hire-slot confirmation copy).
  static Future<List<Map<String, dynamic>>> getOffersForJobPost(
    String jobPostId,
  ) async {
    final data = await _client
        .from('job_offers')
        .select('id, status')
        .eq('job_post_id', jobPostId);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Unsubscribe from a realtime channel
  static Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
