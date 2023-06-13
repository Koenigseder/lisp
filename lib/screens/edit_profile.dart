import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/services/storage_service.dart';

import '../models/firestore_user.dart';
import '../utils/snackbar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.initialUser});

  final FirestoreUser? initialUser;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  final _displayNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  PlatformFile? pickedFile;

  int profilePictureChangedSeed = -1;

  @override
  void initState() {
    super.initState();

    _displayNameController.addListener(() {
      setState(() {});
    });

    _displayNameController.text = widget.initialUser!.name;
  }

  @override
  void dispose() {
    super.dispose();

    _displayNameController.dispose();
  }

  Future selectFile() async {
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

    return false;
  }

  Future updateUser() async {
    try {
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
              Row(
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
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await updateUser();
                      if (mounted) Navigator.pop(context);
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
                    child: profilePictureChangedSeed < 0
                        ? Image.network(
                            "${_storageService.getProfilePictureURL(
                              FirebaseAuth.instance.currentUser!.uid,
                            )}&xy=$profilePictureChangedSeed",
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
              Container(
                // width: double.infinity,
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
                            )),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (displayName) => displayName?.trim() == ""
                            ? "Please enter a display name"
                            : null,
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
