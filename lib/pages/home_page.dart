import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:silab/pages/admin/admin_page.dart';
import 'package:silab/pages/user/user_page.dart';
import 'package:silab/services/auth/auth_service.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? mToken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotifications;
  late AndroidNotificationChannel androidNotificationChannel;

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        mToken = value;
      });
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void loadFCM() async {
    if (!kIsWeb) {
      androidNotificationChannel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications',
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotifications = FlutterLocalNotificationsPlugin();

      await flutterLocalNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((message) {
      print('Message : ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidNotificationChannel.id,
              androidNotificationChannel.name,
              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
  }

  Future<AuthUser> getUserRole() async {
    final currentUser = AuthService.firebase().currentUser!;

    final role = await FirebaseCloudStorage().getUser(
      userId: currentUser.id,
      user: currentUser,
    );

    return role;
  }

  @override
  void initState() {
    super.initState();
    getToken();

    requestPermission();
    loadFCM();
    listenFCM();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Home Page : ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.requireData;

          if (user.role == null || user.role != 'admin') {
            return const UserPage();
          } else {
            return const AdminPage();
          }
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
