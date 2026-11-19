import 'dart:async';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/notifications/notification_scope.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/core/notifications/notification_text.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/notification_service.dart';

import 'constant.dart';
import 'notification_list_skeleton.dart';

enum _NotifMenuAction { readAll, deleteAll }

class NotificationListScreen extends StatefulWidget {
  final NotificationUserRole role;

  const NotificationListScreen({super.key, required this.role});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final List<AppNotification> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _markingAll = false;
  bool _deletingAll = false;
  bool _rowDeleteBusy = false;

  /// Ids confirmed deleted on the server. Any list response (refresh or
  /// load-more) that was requested before the delete is filtered by this, so a
  /// stale snapshot can never bring a deleted row back.
  final Set<String> _deletedIds = <String>{};

  /// Bumped when "Delete all" succeeds; responses requested earlier are dropped.
  int _deleteAllEpoch = 0;
  bool _hasMore = true;
  int _nextOffset = 0;
  late final NotificationRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<NotificationRepository>();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 280) {
      return;
    }
    unawaited(_loadMore());
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _nextOffset = 0;
    });
    final epoch = _deleteAllEpoch;
    try {
      final fetched = await _repository.getNotifications(
        limit: NotificationService.pageSize,
        offset: 0,
      );
      if (!mounted) return;
      if (epoch != _deleteAllEpoch) {
        // "Delete all" finished while this was in flight: the snapshot is stale.
        setState(() => _isLoading = false);
        return;
      }
      final notifs = fetched.where((n) => !_deletedIds.contains(n.id)).toList();
      setState(() {
        _notifications
          ..clear()
          ..addAll(notifs);
        _nextOffset = fetched.length;
        _hasMore = fetched.length >= NotificationService.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final epoch = _deleteAllEpoch;
    try {
      final fetched = await _repository.getNotifications(
        limit: NotificationService.pageSize,
        offset: _nextOffset,
      );
      if (!mounted) return;
      if (epoch != _deleteAllEpoch) {
        setState(() => _isLoadingMore = false);
        return;
      }
      final notifs = fetched
          .where((n) =>
              !_deletedIds.contains(n.id) &&
              !_notifications.any((e) => e.id == n.id))
          .toList();
      setState(() {
        _notifications.addAll(notifs);
        _nextOffset += fetched.length;
        _hasMore = fetched.length >= NotificationService.pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  String _timeAgo(DateTime date) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _onTapNotification(AppNotification notif) async {
    if (!notif.read) {
      await _repository.markAsRead(notif.id);
      if (mounted) {
        setState(() {
          // The list may have changed during the await: look the row up by id.
          final index = _notifications.indexWhere((n) => n.id == notif.id);
          if (index < 0) return;
          _notifications[index] = AppNotification(
            id: notif.id,
            userId: notif.userId,
            title: notif.title,
            body: notif.body,
            type: notif.type,
            referenceId: notif.referenceId,
            read: true,
            createdAt: notif.createdAt,
          );
        });
        await NotificationScope.of(context).refreshUnreadCount();
      }
    }
    if (!mounted) return;
    await NotificationNavigation.open(
      context,
      role: widget.role,
      notification: notif,
    );
  }

  IconData _iconForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'order':
      case 'hire_onboarding':
      case 'job_offer':
      case 'job_match':
        return Icons.work_outline;
      case 'attendance':
      case 'hour_report':
        return Icons.qr_code_2_outlined;
      case 'review':
        return Icons.star_outline;
      default:
        return FeatherIcons.bell;
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _repository.markAllAsRead();
      if (!mounted) return;
      await _loadInitial();
      if (mounted) await NotificationScope.of(context).refreshUnreadCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Swipe-to-delete: confirm, delete on the server, then let Dismissible
  /// animate the row away. Returns false (row snaps back) on cancel or error.
  Future<bool> _confirmAndDeleteOne(AppNotification notif) async {
    final l10n = context.l10n;
    final ok = await _confirmDialog(
      title: l10n.notificationDeleteConfirmTitle,
      body: l10n.notificationDeleteConfirmBody,
      confirmLabel: l10n.notificationDeleteAction,
    );
    if (!ok || !mounted) return false;
    try {
      await _repository.deleteNotification(notif.id);
      _deletedIds.add(notif.id);
      if (mounted) _afterSingleDelete();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
      return false;
    }
  }

  void _removeLocal(AppNotification notif) {
    if (!mounted) return;
    final before = _notifications.length;
    setState(() => _notifications.removeWhere((n) => n.id == notif.id));
    if (_notifications.length < before && _nextOffset > 0) _nextOffset--;
  }

  /// Non-swipe delete (screen-reader action / long press).
  Future<void> _deleteViaAction(AppNotification notif) async {
    if (_rowDeleteBusy) return;
    _rowDeleteBusy = true;
    try {
      final ok = await _confirmAndDeleteOne(notif);
      if (ok) _removeLocal(notif);
    } finally {
      _rowDeleteBusy = false;
    }
  }

  void _afterSingleDelete() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.notificationDeleted)));
    // Realtime only listens to insert/update, so refresh the badge manually.
    unawaited(NotificationScope.of(context).refreshUnreadCount());
  }

  Future<void> _deleteAll() async {
    if (_deletingAll) return;
    final l10n = context.l10n;
    final ok = await _confirmDialog(
      title: l10n.deleteAllNotificationsTitle,
      body: l10n.deleteAllNotificationsBody,
      confirmLabel: l10n.deleteAllNotifications,
    );
    if (!ok || !mounted) return;
    setState(() => _deletingAll = true);
    try {
      final hadRows = _notifications.isNotEmpty;
      final deleted = await _repository.deleteAllNotifications();
      if (deleted == 0 && hadRows) {
        // RLS filters silently (204, no rows): do not pretend it worked.
        throw Exception('Notifications were not deleted');
      }
      if (!mounted) return;
      _deleteAllEpoch++;
      setState(() {
        _notifications.clear();
        _nextOffset = 0;
        _hasMore = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(context.l10n.allNotificationsDeleted)));
      await NotificationScope.of(context).refreshUnreadCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasUnread = _notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.notifications,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<_NotifMenuAction>(
              enabled: !_markingAll && !_deletingAll,
              icon: _markingAll || _deletingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _NotifMenuAction.readAll:
                    _markAllRead();
                  case _NotifMenuAction.deleteAll:
                    _deleteAll();
                }
              },
              itemBuilder: (_) => [
                if (hasUnread)
                  PopupMenuItem(
                    value: _NotifMenuAction.readAll,
                    child: Text(l10n.readAll,
                        style: kTextStyle.copyWith(color: kNeutralColor)),
                  ),
                PopupMenuItem(
                  value: _NotifMenuAction.deleteAll,
                  child: Text(l10n.deleteAllNotifications,
                      style: kTextStyle.copyWith(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Material(
          color: kWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: _isLoading
                ? const NotificationListSkeleton()
                : RubikRefreshIndicator(
                    onRefresh: _loadInitial,
                    child: _notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.15,
                              ),
                              EmptyStateWidget(
                                message: l10n.noNotifications,
                                hint: l10n.noNotificationsHint,
                                icon: Icons.notifications_none_outlined,
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding:
                                const EdgeInsets.only(top: 15.0, bottom: 15.0),
                            itemCount: _notifications.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _notifications.length) {
                                return const NotificationListLoadMoreSkeleton();
                              }

                              final notif = _notifications[i];
                              final isRead = notif.read;

                              final tile = ListTile(
                                onTap: () => _onTapNotification(notif),
                                onLongPress: () => _deleteViaAction(notif),
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRead
                                        ? kDarkWhite
                                        : kPrimaryColor.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    _iconForType(notif.type),
                                    color: isRead
                                        ? kLightNeutralColor
                                        : kPrimaryColor,
                                  ),
                                ),
                                title: Text(
                                  notif.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (notif.body != null &&
                                        notif.body!.isNotEmpty)
                                      Text(
                                        localizedNotificationBody(
                                                l10n, notif) ??
                                            notif.body!,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: kTextStyle.copyWith(
                                            color: kSubTitleColor),
                                      ),
                                    Text(
                                      _timeAgo(notif.createdAt),
                                      style: kTextStyle.copyWith(
                                          color: kLightNeutralColor),
                                    ),
                                  ],
                                ),
                              );

                              return Dismissible(
                                key: ValueKey(notif.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) =>
                                    _confirmAndDeleteOne(notif),
                                onDismissed: (_) => _removeLocal(notif),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Semantics(
                                    label: l10n.notificationDeleteAction,
                                    child: const Icon(Icons.delete_outline,
                                        color: Colors.white),
                                  ),
                                ),
                                child: Semantics(
                                  customSemanticsActions: {
                                    CustomSemanticsAction(
                                      label: l10n.notificationDeleteAction,
                                    ): () => _deleteViaAction(notif),
                                  },
                                  child: tile,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}
