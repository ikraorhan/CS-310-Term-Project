import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> init() async {
    debugPrint('Initializing notification service...');

    // If already initialized, don't do it again
    if (_isInitialized) {
      debugPrint('Notification service already initialized, skipping');
      return;
    }

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    // Platform-specific initialization
    if (Platform.isIOS) {
      await _initializeIOS();
    } else {
      await _initializeAndroid();
    }

    _isInitialized = true;
    debugPrint('Notification service initialization complete');
  }

  // iOS-specific initialization
  Future<void> _initializeIOS() async {
    debugPrint('Initializing iOS notifications...');

    // iOS settings with foreground presentation options
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          // Request permissions during initialization for better compatibility
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          // Configure how notifications appear in foreground
          notificationCategories: [
            DarwinNotificationCategory(
              'taskCategory',
              actions: [
                DarwinNotificationAction.plain(
                  'MARK_AS_DONE',
                  'Mark as Done',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        );

    // Initialize with iOS settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    // Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('iOS notification response received: ${response.payload}');
      },
    );

    // We don't immediately request permissions as they're already requested in initialization
  }

  // Android-specific initialization
  Future<void> _initializeAndroid() async {
    debugPrint('Initializing Android notifications...');

    // Reset plugin to ensure fresh start
    await flutterLocalNotificationsPlugin.cancelAll();

    // Initialize settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'Android notification response received: ${response.payload}',
        );
      },
    );

    // Set up Android channels
    await _setupAndroidChannels();

    // Request permissions
    await requestPermissions();
  }

  // Set up Android notification channels
  Future<void> _setupAndroidChannels() async {
    const taskChannel = AndroidNotificationChannel(
      'task_channel',
      'Task Notifications',
      description: 'Notifications for task reminders',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(taskChannel);

    debugPrint('Android notification channel created');
  }

  // Special method to request iOS permissions explicitly
  Future<bool> _requestiOSPermissions() async {
    debugPrint('Requesting iOS notification permissions explicitly...');

    try {
      final iOSPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iOSPlugin == null) {
        debugPrint('iOS plugin not available');
        return false;
      }

      // Request all permissions
      final bool? alertPermission = await iOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical:
            false, // Changed from true to false as critical alerts require special entitlement
        provisional: false, // Not using provisional notifications
      );

      debugPrint('iOS permission request result: $alertPermission');
      return alertPermission ?? false;
    } catch (e) {
      debugPrint('Error requesting iOS permissions: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    try {
      debugPrint('Requesting notification permissions...');

      if (Platform.isIOS) {
        await _requestiOSPermissions();
      } else if (Platform.isAndroid) {
        debugPrint('Requesting Android permissions');

        // For Android
        final android =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (android != null) {
          final result = await android.areNotificationsEnabled();
          debugPrint('Android notifications enabled: $result');

          if (result == false) {
            await android.requestNotificationsPermission();
            debugPrint('Android permission requested');
          }
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  // iOS-specific notification method for maximum compatibility
  Future<void> showIOSNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('Showing iOS notification with ID: $id');

    if (!_isInitialized) {
      await init();
    }

    // Request permissions again to ensure they're granted
    final permissionGranted = await _requestiOSPermissions();
    if (!permissionGranted) {
      debugPrint('iOS notification permission not granted');
      throw Exception(
        'Notification permission not granted. Please enable notifications in iOS Settings.',
      );
    }

    // Create iOS-specific notification details
    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'taskCategory',
      // Remove interruptionLevel: InterruptionLevel.active, as it might be causing issues
    );

    try {
      // Show the notification using a dedicated iOS structure
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(iOS: iOSDetails),
        payload: 'ios_notification_$id',
      );
      debugPrint('iOS notification show call completed for ID: $id');
    } catch (e) {
      debugPrint('Error showing iOS notification: $e');
      rethrow;
    }
  }

  // Test immediate notification
  Future<void> showBasicTestNotification() async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      if (!_isInitialized) {
        await init();
      }

      if (Platform.isIOS) {
        // Use the iOS-specific method for iOS
        await showIOSNotification(
          id: id,
          title: 'iOS Test Notification',
          body: 'This is a test notification on iOS at ${DateTime.now()}',
        );
        return;
      }

      // Basic notification for Android
      debugPrint('Showing test notification on Android with ID $id');
      await flutterLocalNotificationsPlugin.show(
        id,
        'Test Notification',
        'This is a basic test notification at ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      debugPrint('Basic test notification sent successfully');
    } catch (e) {
      debugPrint('Error showing basic test notification: $e');
      rethrow;
    }
  }

  // Show an immediate notification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      debugPrint(
        'Showing immediate notification on ${Platform.operatingSystem}',
      );

      if (Platform.isIOS) {
        // Use the dedicated iOS method
        await showIOSNotification(id: id, title: title, body: body);
      } else {
        // Android notification
        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_channel',
              'Task Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: payload,
        );
      }

      debugPrint('Immediate notification shown with ID: $id');
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
      rethrow;
    }
  }

  // Request the exact alarm permission on Android
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    debugPrint('Attempting to request exact alarm permission on Android');

    try {
      // Try the direct way first if available
      final androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        try {
          // Try to request the permission directly
          await androidPlugin.requestExactAlarmsPermission();
          debugPrint('Successfully requested exact alarms permission');
        } catch (e) {
          debugPrint('Failed direct alarm permission request: $e');

          // Fallback to the force-trigger approach
          await _forceExactAlarmPermissionDialog();
        }
      } else {
        // No plugin available, try the force-trigger approach
        await _forceExactAlarmPermissionDialog();
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }
  }

  // Forces the exact alarm permission dialog by attempting to schedule
  Future<void> _forceExactAlarmPermissionDialog() async {
    debugPrint('Using forced approach to exact alarm permission');

    try {
      // Try to schedule a notification for the next minute
      final now = DateTime.now();
      final targetTime = now.add(const Duration(minutes: 1));

      // Use a simple notification configuration
      await flutterLocalNotificationsPlugin.zonedSchedule(
        -999,
        'Permission Test',
        'Testing permission functionality',
        tz.TZDateTime.from(targetTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            importance: Importance.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'permission_test',
      );

      // Immediately cancel the test notification
      await flutterLocalNotificationsPlugin.cancel(-999);
      debugPrint('Forced permission dialog trigger completed');
    } catch (e) {
      debugPrint('Forced permission dialog trigger error: $e');

      // Check if the error is specifically about exact alarms
      if (e.toString().contains('exact_alarms_not_permitted')) {
        debugPrint('Direct permission opening needed');

        // Launch system settings - this will be handled in the UI level
        throw Exception('exact_alarms_not_permitted_open_settings');
      } else {
        rethrow;
      }
    }
  }

  // Schedule a task notification
  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      // Re-request permissions on iOS for scheduled notifications
      if (Platform.isIOS) {
        await _requestiOSPermissions();
      }

      debugPrint('Scheduling notification for ${scheduledDate.toString()}');

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      if (Platform.isIOS) {
        // iOS-specific approach
        final iOSDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          // No interruptionLevel here as it might cause issues
        );

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzDateTime,
            NotificationDetails(iOS: iOSDetails),
            // Use appropriate parameters for iOS
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );

          debugPrint(
            'iOS notification scheduled for $scheduledDate with ID: $id',
          );
        } catch (e) {
          debugPrint('Error scheduling iOS notification: $e');
          rethrow;
        }
      } else {
        // Android approach
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzDateTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_channel',
                'Task Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (e) {
          if (e.toString().contains('exact_alarms_not_permitted')) {
            await requestExactAlarmPermission();
            throw Exception(
              'Please enable exact alarms permission in settings',
            );
          } else {
            rethrow;
          }
        }
      }

      debugPrint('Notification scheduled for $scheduledDate with ID: $id');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Cancelled notification with ID: $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}
