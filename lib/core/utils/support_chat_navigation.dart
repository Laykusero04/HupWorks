import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/support_chat_screen.dart';
import 'package:nb_utils/nb_utils.dart';

Future<void> openSupportChat(BuildContext context) async {
  await const SupportChatScreen().launch(context);
}
