import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lisp/services/firestore_service.dart';

// Firestore
final _firestoreService = FirestoreService();

// Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel taskUpdatedChannel =
    AndroidNotificationChannel(
  "task_updated",
  "List updated",
  description: "Get updates when lists are updated.",
  importance: Importance.max,
);

Future<void> createChannels() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(taskUpdatedChannel);
}

Future<void> firebaseMessagingRequestNotificationPermission() async {
  await FirebaseMessaging.instance.requestPermission();

  final fcmToken = await FirebaseMessaging.instance.getToken();
  _firestoreService.updateUser(
    data: {
      "fcm": FieldValue.arrayUnion([
        fcmToken,
      ])
    },
  );

  if (kDebugMode) {
    print("FCM Token: $fcmToken");
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;

  if (notification == null) {
    await Firebase.initializeApp();
    if (message.data["by"] == FirebaseAuth.instance.currentUser!.uid) return;

    flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data["title"],
        message.data["body"],
        NotificationDetails(
          android: AndroidNotificationDetails(
            taskUpdatedChannel.id,
            taskUpdatedChannel.name,
            channelDescription: taskUpdatedChannel.description,
            icon: "@drawable/notification_icon",
          ),
        ));
  }

  if (kDebugMode) {
    print(message.data);
  }
}

void firebaseMessagingForegroundHandler(RemoteMessage message) {
  RemoteNotification? notification = message.notification;

  if (message.data["by"] == FirebaseAuth.instance.currentUser!.uid) return;

  flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification != null ? notification.title : message.data["title"],
      notification != null ? notification.body : message.data["body"],
      NotificationDetails(
        android: AndroidNotificationDetails(
          taskUpdatedChannel.id,
          taskUpdatedChannel.name,
          channelDescription: taskUpdatedChannel.description,
          icon: "@drawable/notification_icon",
        ),
      ));

  if (kDebugMode) {
    print(message.data);
  }
}

Future<void> subscribeToTopics(List<String> topics) async {
  final messagingInstance = FirebaseMessaging.instance;

  for (final topic in topics) {
    messagingInstance.subscribeToTopic(topic);

    if (kDebugMode) {
      print("Subscribed to $topic");
    }
  }
}

Future<void> unsubscribeFromTopic(String topic) async {
  final messagingInstance = FirebaseMessaging.instance;

  messagingInstance.unsubscribeFromTopic(topic);
}
