import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Schedules and cancels a single "timer ended" local notification for when the app is in background.
class TimerLocalNotificationService {
  TimerLocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const int timerNotificationId = 1;
  static const String androidChannelId = 'timer_end_channel';
  static const String androidChannelName = 'Timer';

  bool _initialized = false;

  /// Initialize the plugin and timezone. Call once before scheduling (e.g. in main()).
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              androidChannelId,
              androidChannelName,
              description: 'Notification when the rest timer ends',
              importance: Importance.high,
              playSound: true,
            ),
          );
    }

    _initialized = true;
  }

  /// Schedule a notification at [endTime]. [title] and [body] are shown in the notification.
  Future<void> schedule(DateTime endTime, String title, String body) async {
    if (!_initialized) await initialize();
    if (kIsWeb) return;

    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: 'Notification when the rest timer ends',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      timerNotificationId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the scheduled timer notification.
  Future<void> cancel() async {
    if (kIsWeb) return;
    await _plugin.cancel(timerNotificationId);
  }

  /// Request notification permission from the user. Call from the permission confirmation screen.
  /// Returns true if granted (or already granted), false if denied, null if not applicable (e.g. web).
  Future<bool?> requestPermission() async {
    if (kIsWeb) return null;
    if (!_initialized) await initialize();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true, badge: false);
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission();
    }
    return null;
  }
}
