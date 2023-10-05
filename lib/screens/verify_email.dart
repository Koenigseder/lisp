import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lisp/mainpage.dart';
import 'package:lisp/screens/service_unavailable.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/utils/snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late int buildNumber;

  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  Map<String, dynamic>? maintenanceData;
  final _firestoreService = FirestoreService();

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } on FirebaseAuthException catch (e) {
      Snackbar.showSnackBar(e.message, Colors.red);
    }
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) timer?.cancel();
  }

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      buildNumber = int.parse(packageInfo.buildNumber);
    });

    _firestoreService.checkIfMaintenance().then((value) => setState(() {
          maintenanceData = value;
        }));

    FirebaseAuth.instance.currentUser!.reload();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if ((maintenanceData?["active"] ?? false) &&
        buildNumber < maintenanceData?["valid_build_number"]) {
      return ServiceUnavailablePage(
        data: maintenanceData,
      );
    }

    return isEmailVerified
        ? const MainPage()
        : Scaffold(
            appBar: AppBar(
              title: const Text("Verify E-Mail"),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "A verification email has been sent to your email.",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 24.0,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: const Icon(Icons.email),
                    label: const Text(
                      "Resend E-Mail",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                  ),
                  const SizedBox(
                    height: 4.0,
                  ),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),
          );
  }
}
