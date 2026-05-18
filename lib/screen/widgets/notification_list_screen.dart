import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

class NotificationListScreen extends StatefulWidget {
  final NotificationUserRole role;

  const NotificationListScreen({super.key, required this.role});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  late final NotificationRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<NotificationRepository>();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await _repository.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
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
    final hasUnread = _notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Notifications',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                await _repository.markAllAsRead();
                _loadNotifications();
              },
              child: Text('Read All', style: kTextStyle.copyWith(color: kPrimaryColor)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) {
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
    );
  }
}
