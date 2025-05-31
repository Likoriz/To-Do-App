import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/db/google_calendar_helper.dart';
import 'package:todo/ui/pages/home_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  GoogleCalendarHelper? _calendarHelper;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await dotenv.load(fileName: '.env');

    final clientId = dotenv.env['CLIENT_ID']!;
    final clientSecret = dotenv.env['CLIENT_SECRET']!;
    final calendarId = dotenv.env['CALENDAR_ID']!;

    try {
      final client = await clientViaUserConsent(
        ClientId(clientId, clientSecret),
        [calendar.CalendarApi.calendarScope],
        (url) async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Could not open the link!'),
                content: SelectableText(url),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ОК'),
                  ),
                ],
              ),
            );
          }
        },
      );

      final calendarApi = calendar.CalendarApi(client);
      _calendarHelper = GoogleCalendarHelper(calendarApi, calendarId);

      final taskController = TaskController(_calendarHelper!);
      Get.put(taskController);
      await taskController.syncFromGoogleCalendar();

      if (mounted) {
        Get.offAll(() => const HomePage());
      }
    } catch (e) {
      print('Auth failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
