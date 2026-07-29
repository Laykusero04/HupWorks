import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/notifications/notification_scope.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/notification_service.dart';

import 'constant.dart';
import 'notification_list_skeleton.dart';

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
    try {
      final notifs = await _repository.getNotifications(
        limit: NotificationService.pageSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(notifs);
        _nextOffset = notifs.length;
        _hasMore = notifs.length >= NotificationService.pageSize;
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
    try {
      final notifs = await _repository.getNotifications(
        limit: NotificationService.pageSize,
        offset: _nextOffset,
      );
      if (!mounted) return;
      setState(() {
        _notifications.addAll(notifs);
        _nextOffset += notifs.length;
        _hasMore = notifs.length >= NotificationService.pageSize;
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

  Future<void> _onTapNotification(int index) async {
    final notif = _notifications[index];
    if (!notif.read) {
      await _repository.markAsRead(notif.id);
      if (mounted) {
        setState(() {
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
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                await _repository.markAllAsRead();
                await _loadInitial();
                if (mounted) await NotificationScope.of(context).refreshUnreadCount();
              },
              child: Text(l10n.readAll, style: kTextStyle.copyWith(color: kPrimaryColor)),
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
                : _notifications.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noNotifications,
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      )
                    : RefreshIndicator(
                        color: kPrimaryColor,
                        onRefresh: _loadInitial,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                          itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _notifications.length) {
                              return const NotificationListLoadMoreSkeleton();
                            }

                            final notif = _notifications[i];
                            final isRead = notif.read;

                            return ListTile(
                              onTap: () => _onTapNotification(i),
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRead ? kDarkWhite : kPrimaryColor.withOpacity(0.1),
                                ),
                                child: Icon(
                                  FeatherIcons.bell,
                                  color: isRead ? kLightNeutralColor : kPrimaryColor,
                                ),
                              ),
                              title: Text(
                                notif.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (notif.body != null && notif.body!.isNotEmpty)
                                    Text(
                                      notif.body!,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  Text(
                                    _timeAgo(notif.createdAt),
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ],
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
