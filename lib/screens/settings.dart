import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lisp/models/firestore_user.dart';
import 'package:lisp/screens/edit_profile.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/services/storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/snackbar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String appName, packageName, version, buildNumber;

  final formKey = GlobalKey<FormState>();

  FirestoreUser? initialUser;

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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

  void _showLogoutWarning() {
    showDialog(
      useRootNavigator: true,
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text(
          "Are you sure you want to logout from your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(alertContext);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
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
                return const Text(
                    "Something went wrong! Try resetting the app... 😥");
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40.0,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: Image.network(
                                _storageService.getProfilePictureURL(
                                  FirebaseAuth.instance.currentUser!.uid,
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: SvgPicture.string(
                                      _storageService.getAvatarString(
                                        FirebaseAuth.instance.currentUser!.uid,
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    initialUser!.name,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  Text(
                                    FirebaseAuth.instance.currentUser!.email!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 15.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      initialUser: initialUser,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 20.0,
                              ),
                              label: const Text(
                                "Edit profile",
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(125.0, 30.0),
                              ),
                            ),
                            const SizedBox(
                              width: 15.0,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  const ClipboardData(
                                    text:
                                        "https://play.google.com/store/apps/details?id=me.koenigseder.lisp",
                                  ),
                                );
                                Snackbar.showSnackBar(
                                    "App link copied to clipboard",
                                    Colors.green);
                              },
                              icon: const Icon(
                                Icons.share,
                                size: 20.0,
                              ),
                              label: const Text(
                                "Copy app link",
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(125.0, 30.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        color: Colors.black,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showLogoutWarning(),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10.0,
                        ),
                        child: Text(
                          "© ${getCurrentYear()} Kevin Königseder\nVersion: $version",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
