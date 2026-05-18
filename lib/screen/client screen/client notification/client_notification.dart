import 'package:flutter/material.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/screen/widgets/notification_list_screen.dart';

class ClientNotification extends StatelessWidget {
  const ClientNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationListScreen(role: NotificationUserRole.client);
  }
}
