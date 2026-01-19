import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

// Conditional import for Web JS interop
import 'notification_stub.dart'
    if (dart.library.js) 'dart:js' as js;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Callback for handling notification taps
  Function(int taskId)? _onNotificationTap;

  bool get isInitialized => _isInitialized;
  
  // Set the callback for notification taps
  void setNotificationTapCallback(Function(int taskId) callback) {
    _onNotificationTap = callback;
    debugPrint('Notification tap callback registered');
  }

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }
    
    debugPrint('=== Initializing NotificationService ===');
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    debugPrint('Timezone set to: ${timeZoneInfo.identifier}');

    // 2. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS & macOS Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Linux Settings
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open application');

    // 5. Windows Settings (REQUIRED for Windows)
    // appUserModelId is strictly required for notifications to work on newer Windows versions
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
            appName: 'Taskify',
            appUserModelId: 'com.example.taskify_app',
            guid: 'df241d70-a801-49fa-94ae-9280d88942df',
        );

    // 6. Combined Settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
      windows: initializationSettingsWindows,
    );

    // 7. Initialize Plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('🔔 Notification tapped with payload: ${response.payload}');
        
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final taskId = int.parse(response.payload!);
            debugPrint('📱 Opening task ID: $taskId');
            
            // Call the registered callback to open the task
            if (_onNotificationTap != null) {
              _onNotificationTap!(taskId);
            } else {
              debugPrint('⚠️ No notification tap callback registered');
            }
          } catch (e) {
            debugPrint('❌ Error parsing task ID from payload: $e');
          }
        }
      },
    );
    _isInitialized = true;
    debugPrint('✅ NotificationService initialized successfully');
  }

  Future<bool> requestPermissions() async {
    debugPrint('=== Requesting notification permissions ===');
    
    if (kIsWeb) {
      final permission = await js.context.callMethod('eval', [
        'Notification.requestPermission()'
      ]);
      return permission == 'granted';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlatformChannelSpecifics =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidPlatformChannelSpecifics?.requestNotificationsPermission();
      final bool? exactGranted = await androidPlatformChannelSpecifics?.requestExactAlarmsPermission();
      
      debugPrint('Android notification permission granted: $granted');
      debugPrint('Android exact alarm permission granted: $exactGranted');
      
      return (granted ?? false) && (exactGranted ?? true);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
    }
    return true; // Desktop handled during init or implicitly
  }

  Future<void> scheduleTaskReminder(Task task) async {
    debugPrint('=== scheduleTaskReminder called for task ${task.id}: "${task.title}" ===');
    
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized, skipping scheduleTaskReminder');
      return;
    }

    if (task.dueBelow == null) {
      debugPrint('Task ${task.id} has no due date, skipping notification');
      return;
    }
    
    final now = DateTime.now();
    debugPrint('Task ${task.id} due date: ${task.dueBelow}');
    debugPrint('Current time: $now');

    // Check if the due date is in the past
    if (task.dueBelow!.isBefore(now)) {
      debugPrint('Task ${task.id} due date is in the past, skipping notification');
      return;
    }

    // Calculate notification times
    final dueTime = task.dueBelow!;
    final twentyFourHoursBefore = dueTime.subtract(const Duration(hours: 24));
    final oneHourBefore = dueTime.subtract(const Duration(hours: 1));
    
    int scheduledCount = 0;

    // NOTIFICATION 1: 24 hours before (if applicable)
    if (twentyFourHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: task.id,
        title: '⏰ Task Due Tomorrow: ${task.title}',
        body: task.description != null && task.description!.isNotEmpty
            ? '${task.description}\n\nYou have 1 day remaining to complete this task.'
            : 'You have 1 day remaining to complete this task.',
        scheduledTime: twentyFourHoursBefore,
        payload: task.id.toString(),
      );
      scheduledCount++;
      debugPrint('✅ Scheduled 24h reminder for task ${task.id} at $twentyFourHoursBefore');
    } else {
      debugPrint('⏭️ Skipped 24h reminder (too close to deadline)');
    }

    // NOTIFICATION 2: 1 hour before (if applicable)
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: task.id + 100000,
        title: '⚠️ Task Due Soon: ${task.title}',
        body: task.description != null && task.description!.isNotEmpty
            ? '${task.description}\n\nUrgent: Only 1 hour left to complete this task!'
            : 'Urgent: Only 1 hour left to complete this task!',
        scheduledTime: oneHourBefore,
        payload: task.id.toString(),
      );
      scheduledCount++;
      debugPrint('✅ Scheduled 1h reminder for task ${task.id} at $oneHourBefore');
    } else {
      debugPrint('⏭️ Skipped 1h reminder (too close to deadline)');
    }

    // NOTIFICATION 3: At deadline (always schedule if not past)
    await _scheduleNotification(
      id: task.id + 200000,
      title: '🔴 Task Deadline Reached: ${task.title}',
      body: task.description != null && task.description!.isNotEmpty
          ? '${task.description}\n\nTime\'s up! This task is now overdue.'
          : 'Time\'s up! This task is now overdue.',
      scheduledTime: dueTime,
      payload: task.id.toString(),
    );
    scheduledCount++;
    debugPrint('✅ Scheduled deadline reminder for task ${task.id} at $dueTime');
    
    debugPrint('📊 Total notifications scheduled for task ${task.id}: $scheduledCount/3');
  }

  // Helper method to schedule individual notifications
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Notifications for task deadlines',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification ID $id: $e');
      rethrow;
    }
    
    if (kIsWeb) {
      // For Web, schedule delayed notification if app is open
      final delay = scheduledTime.difference(DateTime.now());
      if (!delay.isNegative) {
        Future.delayed(delay, () {
          showInstantNotification(title, body);
        });
      }
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_isInitialized) return;

    // Cancel all 3 notifications for this task
    await _notificationsPlugin.cancel(taskId);          // 24h before notification
    await _notificationsPlugin.cancel(taskId + 100000); // 1h before notification
    await _notificationsPlugin.cancel(taskId + 200000); // Deadline notification
    
    debugPrint('🗑️ Cancelled all notifications for task $taskId (24h, 1h, deadline)');
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) {
      js.context.callMethod('eval', [
        'new Notification("$title", { body: "$body" })'
      ]);
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'instant_notifications_channel',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }
}
