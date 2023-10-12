import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:random_avatar/random_avatar.dart';

class StorageService {
  final storage = FirebaseStorage.instance;

  Future<String> getProfilePictureURL(String uid) async {
    final ref = storage.ref().child("/profilePictures/$uid.jpg");
    return await ref.getDownloadURL();
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
