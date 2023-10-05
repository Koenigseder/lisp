import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/snackbar.dart';

class AuthService {
  User user = FirebaseAuth.instance.currentUser!;

  Future<void> changeEmail(String newEmail, String reAuthenticationPassword) async {
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(
      email: user.email!,
      password: reAuthenticationPassword,
    ));
    await user.updateEmail(newEmail);
    await user.sendEmailVerification();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      ));
      await user.updatePassword(newPassword);

      Snackbar.showSnackBar("Password successfully updated!", Colors.green);
    } on Exception catch (e) {
      Snackbar.showSnackBar(e.toString(), Colors.red);
    }
  }
}
