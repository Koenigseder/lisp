import 'dart:io';
import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lisp/services/auth_service.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/services/storage_service.dart';

import '../models/firestore_user.dart';
import '../utils/snackbar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage(
      {super.key, required this.initialUser, required this.updateState});

  final FirestoreUser? initialUser;
  final VoidCallback updateState;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final changePasswordFormKey = GlobalKey<FormState>();

  String profilePicturePath = "";
  PlatformFile? pickedFile;

  int profilePictureChangedSeed = -1;

  @override
  void initState() {
    super.initState();

    _displayNameController.addListener(() {
      setState(() {});
    });

    _emailController.addListener(() {
      setState(() {});
    });

    _passwordController.addListener(() {
      setState(() {});
    });

    _newPasswordController.addListener(() {
      setState(() {});
    });

    _storageService
        .getProfilePictureURL(FirebaseAuth.instance.currentUser!.uid)
        .then((value) {
      setState(() {
        profilePicturePath = value;
      });
    });

    _displayNameController.text = widget.initialUser!.name;
    _emailController.text = FirebaseAuth.instance.currentUser!.email!;
  }

  @override
  void dispose() {
    super.dispose();

    widget.updateState();

    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      pickedFile = result.files.first;
    });
  }

  bool checkIfUserChanged() {
    FirestoreUser currentUser = FirestoreUser(
      name: _displayNameController.text.trim(),
      tasks: widget.initialUser!.tasks,
    );

    if (widget.initialUser!.name != currentUser.name) {
      return true;
    }

    if (profilePictureChangedSeed >= 0) {
      return true;
    }

    if (FirebaseAuth.instance.currentUser!.email! !=
        _emailController.text.trim()) {
      return true;
    }

    return false;
  }

  Future<void> updateUser() async {
    try {
      final isValid = formKey.currentState!.validate();
      if (!isValid) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (_displayNameController.text.trim() != widget.initialUser?.name) {
        await _firestoreService
            .updateUser(data: {"name": _displayNameController.text.trim()});
        setState(() {
          widget.initialUser?.name = _displayNameController.text.trim();
        });
      }

      if (profilePictureChangedSeed >= 0) {
        await _storageService.uploadFile(
          "profilePictures/${FirebaseAuth.instance.currentUser!.uid}.jpg",
          File(pickedFile!.path!),
        );
      }

      if (FirebaseAuth.instance.currentUser!.email! !=
          _emailController.text.trim()) {
        bool methodAborted = await _showReAuthenticationAlert();

        if (!methodAborted) {
          await _authService.changeEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
      }

      Snackbar.showSnackBar("User successfully updated!", Colors.green);
    } on Exception catch (e) {
      Snackbar.showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showChangedValuesAlert() {
    showDialog(
      useRootNavigator: true,
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("You have unsaved changes"),
        content: const Text(
          "You edited some fields on this screen. Do you want to discard them?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              "Discard",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> _showPasswordChangeAlert() async {
    bool actionAborted = true;

    _passwordController.text = "";
    _newPasswordController.text = "";

    await showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("Change password"),
        content: Form(
          key: changePasswordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  labelText: "Current password",
                ),
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (password) => password != null && password.length < 6
                    ? "Enter a valid password!"
                    : null,
              ),
              TextFormField(
                controller: _newPasswordController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  labelText: "New password",
                ),
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (password) => password != null && password.length < 6
                    ? "Enter min. 6 characters!"
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              actionAborted = true;
              Navigator.pop(alertContext);
            },
            child: const Text(
              "Cancel",
            ),
          ),
          TextButton(
            onPressed: () {
              bool isValid = changePasswordFormKey.currentState!.validate();
              if (isValid) {
                actionAborted = false;
                Navigator.pop(alertContext);
              }
            },
            child: const Text(
              "Change password",
            ),
          ),
        ],
      ),
    );

    return actionAborted;
  }

  Future<bool> _showReAuthenticationAlert() async {
    bool actionAborted = true;

    _passwordController.text = "";

    await showDialog(
      useRootNavigator: true,
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("Please re-authenticate by entering your password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "WARNING: You have to verify the new mail address in order to continue using the app.",
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.visiblePassword,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              actionAborted = true;
              Navigator.pop(alertContext);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              actionAborted = false;
              Navigator.pop(alertContext);
            },
            child: const Text("Authenticate"),
          ),
        ],
      ),
    );

    return actionAborted;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkIfUserChanged()) {
          _showChangedValuesAlert();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (!checkIfUserChanged()) {
                          Navigator.pop(context);
                          return;
                        }
                        _showChangedValuesAlert();
                      },
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Icon(
                          Icons.keyboard_backspace,
                          size: 27.0,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "Edit profile",
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await updateUser();
                        if (mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Icon(
                          Icons.check,
                          size: 30.0,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  await selectFile();

                  setState(() {
                    profilePictureChangedSeed = Random().nextInt(100);
                  });
                },
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: (profilePictureChangedSeed < 0 || pickedFile == null)
                        ? Image.network(
                            "$profilePicturePath&xy=$profilePictureChangedSeed",
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
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          )
                        : Image.file(
                            File(pickedFile!.path!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container();
                            },
                          ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await selectFile();
                  setState(() {
                    profilePictureChangedSeed = Random().nextInt(100);
                  });
                },
                child: const Text("Change profile picture"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: "Display name",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (displayName) => displayName?.trim() == ""
                            ? "Please enter a display name"
                            : null,
                      ),
                      TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email address",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (email) => email != null &&
                                !EmailValidator.validate(email.trim())
                            ? "Enter a valid E-Mail!"
                            : null,
                      ),
                      TextButton(
                        onPressed: () async {
                          bool actionAborted = await _showPasswordChangeAlert();
                          if (actionAborted) return;

                          await _authService.changePassword(
                            _passwordController.text.trim(),
                            _newPasswordController.text.trim(),
                          );
                        },
                        child: const Text("Change password"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
