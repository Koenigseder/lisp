import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lisp/models/firestore_user.dart';
import 'package:lisp/utils/firestore_service.dart';
import 'package:lisp/utils/snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String appName, packageName, version, buildNumber;

  final formKey = GlobalKey<FormState>();

  FirestoreUser? initialUser;

  final _firestoreService = FirestoreService();

  final _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _displayNameController.addListener(() {
      setState(() {});
    });

    _firestoreService.readUser().first.then((value) {
      setState(() {
        _displayNameController.text = value!.name;
        initialUser = value;
      });
    });

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  int getCurrentYear() {
    return DateTime.now().year;
  }

  Future updateUser() async {
    try {
      await _firestoreService
          .updateUser(data: {"name": _displayNameController.text.trim()});
      setState(() {
        initialUser?.name = _displayNameController.text.trim();
      });
      Snackbar.showSnackBar("User successfully updated!", Colors.green);
    } on Exception catch (e) {
      Snackbar.showSnackBar(e.toString(), Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: StreamBuilder<FirestoreUser?>(
            stream: _firestoreService.readUser(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text("Something went wrong!");
              }
              if (!snapshot.hasData) {
                return Container();
              }

              initialUser = snapshot.data;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                color: const Color(0xFFF6F6F6),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 24.0, bottom: 24.0),
                        child: Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: "Display name",
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (displayName) => displayName?.trim() == ""
                            ? "Please enter a display name"
                            : null,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showAboutDialog(
                            context: context,
                            applicationIcon: const Image(
                              image: AssetImage(
                                'assets/images/logo.png',
                              ),
                              alignment: Alignment.center,
                              width: 30.0,
                            ),
                            applicationName: appName,
                            applicationVersion: version,
                            applicationLegalese:
                                "© ${getCurrentYear()} Kevin Königseder",
                          );
                        },
                        icon: const Icon(Icons.info),
                        label: const Text("About app"),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: initialUser?.name != _displayNameController.text.trim() &&
                (formKey.currentState?.validate() ?? false)
            ? Offset.zero
            : const Offset(3, 0),
        child: FloatingActionButton(
          onPressed: updateUser,
          child: Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.save,
              color: Colors.white,
              size: 30.0,
            ),
          ),
        ),
      ),
    );
  }
}
