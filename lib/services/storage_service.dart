import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:random_avatar/random_avatar.dart';

class StorageService {
  final storage = FirebaseStorage.instance;

  String getProfilePictureURL(String uid) {
    return "https://firebasestorage.googleapis.com/v0/b/lisp-882b0.appspot.com/o/profilePictures%2F$uid.jpg?alt=media";
  }

  Future uploadFile(String path, File file) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
  }

  Future deleteFile(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.delete();
  }

  String getAvatarString(String avatarString) {
    return RandomAvatarString(avatarString);
  }
}
