import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/db/google_calendar_helper.dart';
import 'package:todo/services/notification_services.dart';
import 'package:todo/services/theme_services.dart';
import 'package:todo/ui/pages/home_page.dart';
import 'package:todo/ui/theme.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

import 'db/db_helper.dart';

Future<AuthClient> getGoogleAuthClient() async {
  await dotenv.load(fileName: '.env');
  String clientId = dotenv.env['CLIENT_ID'] ??
      (throw Exception('CLIENT_ID not found in .env'));
  String clientSecret = dotenv.env['CLIENT_SECRET'] ??
      (throw Exception('CLIENT_SECRET not found in .env'));

  final client = ClientId(clientId, clientSecret);
  const scopes = [calendar.CalendarApi.calendarScope];

  return await clientViaUserConsent(client, scopes, (url) {
    print('Перейдите по ссылке: $url');
  });
}

//future
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final client = await getGoogleAuthClient();
  final calendarApi = calendar.CalendarApi(client);

  String calendarId = dotenv.env['CALENDAR_ID'] ??
      (throw Exception('CALENDAR_ID not found in .env'));

  final calendarHelper = GoogleCalendarHelper(calendarApi, calendarId);

  await DBHelper.initDb();
  await GetStorage.init();

  NotifyHelper notifyHelper = NotifyHelper();
  await notifyHelper.initializeNotification();

  final taskController = TaskController(calendarHelper);
  Get.put(taskController);
  await taskController.syncFromGoogleCalendar();

  runApp(MyApp(calendarHelper: calendarHelper));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.calendarHelper}) : super(key: key);

  final GoogleCalendarHelper calendarHelper;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
