import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freelancer/core/chat/chat_unread_scope.dart';
import 'package:freelancer/data/models/chat_inbox_filter.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/chat_service.dart';
import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../../widgets/shell_tab_header.dart';
import 'chat_inbox.dart';
import 'model/chat_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  Map<String, ConversationInboxMeta> _inboxMeta = const {};
  ChatInboxFilter _filter = ChatInboxFilter.all;
  bool _isLoading = true;
  RealtimeChannel? _conversationChannel;
  String _searchQuery = '';

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadConversations();
      _subscribeToUpdates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_conversationChannel != null) {
      ChatService.unsubscribe(_conversationChannel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await ChatService.getConversations();
      final conversations =
          data.map((e) => Conversation.fromMap(e)).toList();
      Map<String, ConversationInboxMeta> meta = const {};
      if (conversations.isNotEmpty) {
        meta = await ChatService.getInboxMetaByConversation(
          conversations: conversations
              .map(
                (c) => (
                  id: c.id,
                  clientId: c.clientId,
                  sellerId: c.sellerId,
                ),
              )
              .toList(),
        );
      }
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _inboxMeta = meta;
          _isLoading = false;
        });
        ChatUnreadScope.refreshGlobal();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  void _subscribeToUpdates() {
    _conversationChannel = ChatService.subscribeToConversations(
      onUpdate: () => _loadConversations(),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final l10n = context.l10n;

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return l10n.calendarYesterday;
      if (diff.inDays < 7) {
        return MaterialLocalizations.of(context).formatMediumDate(dateTime);
      }
      return MaterialLocalizations.of(context).formatShortDate(dateTime);
    }

    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  ConversationInboxMeta _metaFor(Conversation c) =>
      _inboxMeta[c.id] ?? ConversationInboxMeta.empty;

  List<Conversation> get _filteredConversations {
    Iterable<Conversation> list = _conversations.where(
      (c) => _metaFor(c).matches(_filter),
    );

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final other = c.getOtherUser(_currentUserId);
        final name = (other['name'] as String? ?? '').toLowerCase();
        final last = (c.lastMessage ?? '').toLowerCase();
        return name.contains(q) || last.contains(q);
      });
    }
    return list.toList();
  }

  int _countFor(ChatInboxFilter filter) {
    if (filter == ChatInboxFilter.all) return _conversations.length;
    return _conversations.where((c) => _metaFor(c).matches(filter)).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final path = GoRouterState.of(context).uri.path;
    final isClient = path.startsWith('/client');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ClientShellAppBar(
        title: l10n.messages,
        persona: isClient ? ShellPersona.client : ShellPersona.seller,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(primary),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : ListenableBuilder(
                    listenable: ChatUnreadScope.of(context),
                    builder: (context, _) => RefreshIndicator(
                      color: primary,
                      onRefresh: _loadConversations,
                      child: _buildBody(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(Color primary) {
    final l10n = context.l10n;
    final filters = <(ChatInboxFilter, String)>[
      (ChatInboxFilter.all, l10n.filterAll),
      (ChatInboxFilter.applications, l10n.chatFilterApplications),
      (ChatInboxFilter.active, l10n.chatFilterActive),
      (ChatInboxFilter.past, l10n.chatFilterPast),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final selected = _filter == filter;
          final count = _countFor(filter);
          return ChoiceChip(
            selected: selected,
            label: Text(
              count > 0 ? '$label ($count)' : label,
              style: kTextStyle.copyWith(
                color: selected ? kWhite : kNeutralColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            selectedColor: primary,
            backgroundColor: kWhite,
            side: BorderSide(
              color: selected ? primary : kBorderColorTextField,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) => setState(() => _filter = filter),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => setState(() => _searchQuery = q),
        style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.searchChats,
          hintStyle: kTextStyle.copyWith(
            color: kLightNeutralColor,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: kLightNeutralColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: kLightNeutralColor,
                  ),
                ),
          filled: true,
          fillColor: kDarkWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    final filtered = _filteredConversations;

    if (_conversations.isEmpty) {
      return _emptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: l10n.noConversationsYet,
        subtitle: l10n.noConversationsHint,
      );
    }

    if (filtered.isEmpty) {
      final isFilterEmpty =
          _filter != ChatInboxFilter.all && _searchQuery.trim().isEmpty;
      return _emptyState(
        icon: isFilterEmpty
            ? Icons.filter_alt_outlined
            : Icons.search_off_rounded,
        title: isFilterEmpty ? l10n.noChatsInFilter : l10n.noChatMatches,
        subtitle:
            isFilterEmpty ? l10n.noChatsInFilterHint : l10n.tryDifferentSearch,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final conversation = filtered[index];
        return _conversationCard(conversation);
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 28),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimaryColor, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(
              color: kLightNeutralColor,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _tagChip(ConversationInboxMeta meta) {
    final tag = meta.primaryTag;
    if (tag == null) return null;
    final l10n = context.l10n;
    late final String label;
    late final Color fg;
    late final Color bg;
    switch (tag) {
      case ChatInboxTag.applications:
        label = l10n.chatTagApplication;
        fg = StatusColors.warning;
        bg = StatusColors.warningBg;
      case ChatInboxTag.active:
        label = l10n.chatTagActive;
        fg = StatusColors.success;
        bg = StatusColors.successBg;
      case ChatInboxTag.past:
        label = l10n.chatTagPast;
        fg = StatusColors.neutral;
        bg = StatusColors.neutralBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: kTextStyle.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _conversationCard(Conversation conversation) {
    final l10n = context.l10n;
    final otherUser = conversation.getOtherUser(_currentUserId);
    final name = otherUser['name'] as String? ?? l10n.unknown;
    final imageUrl = otherUser['profile_image_url'] as String? ?? '';
    final lastMessage = conversation.lastMessage?.trim();
    final hasLast = lastMessage != null && lastMessage.isNotEmpty;
    final unread =
        ChatUnreadScope.of(context).unreadForConversation(conversation.id);
    final hasUnread = unread > 0;
    final meta = _metaFor(conversation);
    final tag = _tagChip(meta);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            try {
              await ChatInbox(
                conversationId: conversation.id,
                otherUserName: name,
                otherUserImage: imageUrl,
                otherUserId: conversation.getOtherUserId(_currentUserId),
              ).launch(context);
              if (mounted) {
                ChatUnreadScope.refreshGlobal();
                await _loadConversations();
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.couldNotOpenChat)),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasUnread
                  ? kPrimaryColor.withValues(alpha: 0.04)
                  : kWhite,
              borderRadius: BorderRadius.circular(18),
              border: hasUnread
                  ? Border.all(color: kPrimaryColor.withValues(alpha: 0.18))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _avatar(name, imageUrl, unread: unread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: kTextStyle.copyWith(
                                  color: kWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Text(
                              _formatTime(context, conversation.lastMessageAt),
                              style: kTextStyle.copyWith(
                                color: kLightNeutralColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      if (tag != null) ...[
                        const SizedBox(height: 4),
                        tag,
                      ],
                      const SizedBox(height: 4),
                      Text(
                        hasLast ? lastMessage : l10n.noMessagesYet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(
                          color: hasUnread
                              ? kNeutralColor
                              : (hasLast
                                  ? kSubTitleColor
                                  : kLightNeutralColor),
                          fontSize: 13,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                          fontStyle: hasLast
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(context, conversation.lastMessageAt),
                          style: kTextStyle.copyWith(
                            color: kLightNeutralColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(String name, String imageUrl, {int unread = 0}) {
    final initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryColor.withValues(alpha: 0.10),
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: imageUrl.isEmpty
              ? Text(
                  initial,
                  style: kTextStyle.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        if (unread > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: kWhite, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return _Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const _SkeletonBox(width: 52, height: 52, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            child: _SkeletonBox(height: 12, radius: 6),
                          ),
                          SizedBox(width: 24),
                          _SkeletonBox(width: 40, height: 10, radius: 5),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const _SkeletonBox(height: 10, radius: 5),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 140,
                          child: _SkeletonBox(height: 10, radius: 5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE6E6E6),
            Color(0xFFF6F6F6),
            Color(0xFFE6E6E6),
          ],
          stops: const [0.1, 0.5, 0.9],
          transform: _SlidingGradientTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}
