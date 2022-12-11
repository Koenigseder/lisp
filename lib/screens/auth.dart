import 'package:flutter/material.dart';
import 'package:lisp/screens/login.dart';
import 'package:lisp/screens/signup.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    void toggle() {
      setState(() {
        isLogin = !isLogin;
      });
    }

    return isLogin
        ? LoginPage(
            onClickedSignUp: toggle,
          )
        : SignUpPage(
            onClickedSignIn: toggle,
          );
  }
}
