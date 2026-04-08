import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/services/notification_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerNotification extends StatefulWidget {
  const SellerNotification({Key? key}) : super(key: key);

  @override
  State<SellerNotification> createState() => _SellerNotificationState();
}

class _SellerNotificationState extends State<SellerNotification> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await NotificationService.getNotifications();
      if (mounted) setState(() { _notifications = notifs; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  String _timeAgo(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Notifications', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            TextButton(onPressed: () async { await NotificationService.markAllAsRead(); _loadNotifications(); },
              child: Text('Read All', style: kTextStyle.copyWith(color: kPrimaryColor))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0), width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _notifications.isEmpty
                  ? Center(child: Text('No notifications', style: kTextStyle.copyWith(color: kLightNeutralColor)))
                  : RefreshIndicator(
                      color: kPrimaryColor, onRefresh: _loadNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) {
                          final notif = _notifications[i];
                          final isRead = notif['read'] == true;
                          return ListTile(
                            onTap: () async {
                              if (!isRead) { await NotificationService.markAsRead(notif['id']); setState(() { _notifications[i] = {...notif, 'read': true}; }); }
                            },
                            contentPadding: EdgeInsets.zero,
                            leading: Container(padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: isRead ? kDarkWhite : kPrimaryColor.withOpacity(0.1)),
                              child: Icon(FeatherIcons.bell, color: isRead ? kLightNeutralColor : kPrimaryColor)),
                            title: Text(notif['title'] ?? 'Notification', overflow: TextOverflow.ellipsis, maxLines: 2,
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (notif['body'] != null && notif['body'].toString().isNotEmpty)
                                Text(notif['body'], overflow: TextOverflow.ellipsis, maxLines: 1, style: kTextStyle.copyWith(color: kSubTitleColor)),
                              Text(_timeAgo(notif['created_at']), style: kTextStyle.copyWith(color: kLightNeutralColor)),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
