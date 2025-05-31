import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:todo/services/notification_services.dart';
import 'package:todo/services/theme_services.dart';
import 'package:todo/ui/pages/auth_gate.dart';
import 'package:todo/ui/theme.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:googleapis/calendar/v3.dart' as calendar;

import 'db/db_helper.dart';

// Future<AuthClient> getGoogleAuthClient() async {
//   await dotenv.load(fileName: '.env');
//   String clientId = dotenv.env['CLIENT_ID'] ??
//       (throw Exception('CLIENT_ID not found in .env'));
//   String clientSecret = dotenv.env['CLIENT_SECRET'] ??
//       (throw Exception('CLIENT_SECRET not found in .env'));

//   final client = ClientId(clientId, clientSecret);
//   const scopes = [calendar.CalendarApi.calendarScope];

//   return await clientViaUserConsent(client, scopes, (url) {
//     print('Перейдите по ссылке: $url');
//   });
// }

//future
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DBHelper.initDb();
  await GetStorage.init();

  final notifyHelper = NotifyHelper();
  await notifyHelper.initializeNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // Новый стартовый экран
    );
  }
}
