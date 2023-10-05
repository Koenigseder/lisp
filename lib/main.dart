import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lisp/screens/auth.dart';
import 'package:lisp/screens/verify_email.dart';
import 'package:lisp/services/push_service.dart';
import 'package:lisp/utils/snackbar.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Notifications
  await firebaseMessagingRequestNotificationPermission();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage
      .listen((RemoteMessage msg) => firebaseMessagingForegroundHandler(msg));

  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

Map<int, Color> color = {
  50: const Color.fromRGBO(136, 14, 79, .1),
  100: const Color.fromRGBO(136, 14, 79, .2),
  200: const Color.fromRGBO(136, 14, 79, .3),
  300: const Color.fromRGBO(136, 14, 79, .4),
  400: const Color.fromRGBO(136, 14, 79, .5),
  500: const Color.fromRGBO(136, 14, 79, .6),
  600: const Color.fromRGBO(136, 14, 79, .7),
  700: const Color.fromRGBO(136, 14, 79, .8),
  800: const Color.fromRGBO(136, 14, 79, .9),
  900: const Color.fromRGBO(136, 14, 79, 1),
};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: Snackbar.messengerKey,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF643FDB, color),
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF643FDB),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AuthPage();
          }
          return const VerifyEmailPage();
        },
      ),
    );
  }
}
