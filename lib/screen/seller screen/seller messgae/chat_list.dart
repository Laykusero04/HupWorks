import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/chat_service.dart';
import '../../../router/app_router.dart';
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
  bool _isLoading = true;
  RealtimeChannel? _conversationChannel;
  String _searchQuery = '';

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    // Defer network work until the first frame is drawn so the skeleton
    // shows instantly instead of competing with the initial layout.
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
      if (mounted) {
        setState(() {
          _conversations = data.map((e) => Conversation.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e')),
        );
      }
    }
  }

  void _subscribeToUpdates() {
    _conversationChannel = ChatService.subscribeToConversations(
      onUpdate: () => _loadConversations(),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dateTime.weekday - 1];
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.trim().isEmpty) return _conversations;
    final q = _searchQuery.toLowerCase();
    return _conversations.where((c) {
      final other = c.getOtherUser(_currentUserId);
      final name = (other['name'] as String? ?? '').toLowerCase();
      final last = (c.lastMessage ?? '').toLowerCase();
      return name.contains(q) || last.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : RefreshIndicator(
                    color: primary,
                    onRefresh: _loadConversations,
                    child: _buildBody(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final persona = path.startsWith('/seller') ? ShellPersona.seller : ShellPersona.client;
    final subtitleText = _conversations.isEmpty
        ? 'Stay connected with your network'
        : '${_conversations.length} '
            '${_conversations.length == 1 ? "conversation" : "conversations"}';

    return ShellTabHeader(
      persona: persona,
      title: 'Messages',
      subtitle: Text(
        subtitleText,
        style: kTextStyle.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
        ),
      ),
      leading: ShellTabIconButton(
        icon: Icons.menu_rounded,
        onPressed: () => openRoleShellDrawer(context),
        tooltip: 'Menu',
      ),
      titleIcon: const ShellTabTitleBadge(icon: Icons.chat_bubble_outline_rounded),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: kLightNeutralColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (q) => setState(() => _searchQuery = q),
                style: kTextStyle.copyWith(
                    color: kNeutralColor, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                  hintText: 'Search conversations',
                  hintStyle: kTextStyle.copyWith(
                      color: kLightNeutralColor, fontSize: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kDarkWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: kNeutralColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final filtered = _filteredConversations;

    if (_conversations.isEmpty) {
      return _emptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No conversations yet',
        subtitle: 'Start a chat from a freelancer or client profile',
      );
    }

    if (filtered.isEmpty) {
      return _emptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches found',
        subtitle: 'Try a different name or keyword',
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
              color: kPrimaryColor.withOpacity(0.10),
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

  Widget _conversationCard(Conversation conversation) {
    final otherUser = conversation.getOtherUser(_currentUserId);
    final name = otherUser['name'] as String? ?? 'Unknown';
    final imageUrl = otherUser['profile_image_url'] as String? ?? '';
    final lastMessage = conversation.lastMessage?.trim();
    final hasLast = lastMessage != null && lastMessage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ChatInbox(
              conversationId: conversation.id,
              otherUserName: name,
              otherUserImage: imageUrl,
            ).launch(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _avatar(name, imageUrl),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(conversation.lastMessageAt),
                            style: kTextStyle.copyWith(
                              color: kLightNeutralColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLast ? lastMessage : 'Start a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(
                          color: hasLast
                              ? kSubTitleColor
                              : kLightNeutralColor,
                          fontSize: 13,
                          fontStyle: hasLast
                              ? FontStyle.normal
                              : FontStyle.italic,
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

  Widget _avatar(String name, String imageUrl) {
    final initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kPrimaryColor.withOpacity(0.10),
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
    );
  }

  // ---------------------------------------------------------------- Skeleton
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
                _SkeletonBox(width: 52, height: 52, radius: 26),
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

// =============================================================
// Shimmer primitives
// =============================================================
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
