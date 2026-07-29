import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freelancer/core/locale/locale_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freelancer/app.dart';
import 'package:freelancer/core/notifications/notification_tap_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initLocalNotifications();

  final localeController = await LocaleController.create();
  runApp(HupWorksApp(localeController: localeController));
}
