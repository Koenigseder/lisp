import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lisp/models/firestore_task.dart';

import '../models/firestore_user.dart';

class FirestoreService {
  // Begin user methods

  Stream<FirestoreUser?> readUser() {
    final snapshots = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();

    return snapshots
        .map((snapshot) => FirestoreUser.fromJson(snapshot.data()!));
  }

  Future<void> createUser({required String name}) async {
    final docUser = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final firestoreUser = FirestoreUser(
      name: name,
      tasks: [
        {
          "role": "ADMIN",
          "task_id": "DUMMY", // Needed to display right dialogs
        }
      ],
    );

    final json = firestoreUser.toJson();

    await docUser.set(json);
  }

  Future<void> updateUser({required Map<String, dynamic> data}) async {
    final docUser = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    await docUser.update(data);

    // Update field: "<field_name>": "<new_value>"
    // Update nested field: "<field_name0>.<field_name1>": "<new_value>"
    // Delete field: "<field_name>": FieldValue.delete()
  }

  Future<void> deleteDoc(
      {required String collectionId, required String docId}) async {
    final docRef =
        FirebaseFirestore.instance.collection(collectionId).doc(docId);

    await docRef.delete();
  }

  Future<void> deleteUnavailableTasks(List<String> taskIds) async {
    for (String taskId in taskIds) {
      if (!await checkIfTaskExists(taskId)) {
        updateUser(data: {
          "tasks": FieldValue.arrayRemove([
            {
              "role": "ADMIN",
              "task_id": taskId,
            }
          ])
        });
      }
    }
  }

  // End user methods

  // Begin task methods

  Stream<List<FirestoreTask>> getTasks(List<String> tasks) {
    if (tasks.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("tasks")
        .where("id", whereIn: tasks)
        .orderBy("creation_epoch_timestamp", descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirestoreTask.fromJson(doc.data()))
            .toList());
  }

  Future<String> createTask({
    required String title,
    required int creationEpochTimestamp,
    String? description,
    List<dynamic>? todos,
    List<dynamic>? changelog,
  }) async {
    final docTask = FirebaseFirestore.instance.collection("tasks").doc();

    final firestoreTask = FirestoreTask(
      id: docTask.id,
      title: title,
      description: description,
      creationEpochTimestamp: creationEpochTimestamp,
      todos: todos,
      changelog: changelog,
    );

    final json = firestoreTask.toJson();

    await docTask.set(json);

    return docTask.id;
  }

  Future<void> updateTask({required Map<String, dynamic> data}) async {
    final docUser =
        FirebaseFirestore.instance.collection("tasks").doc(data["id"]);

    await docUser.update(data);

    // Update field: "<field_name>": "<new_value>"
    // Update nested field: "<field_name0>.<field_name1>": "<new_value>"
    // Delete field: "<field_name>": FieldValue.delete()
  }

  Future<bool> checkIfTaskExists(String taskId) async {
    bool docExists = false;

    final docRef = FirebaseFirestore.instance.collection("tasks").doc(taskId);

    await docRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        docExists = true;
      }
    });

    return docExists;
  }

  // End task methods

  // Start config methods

  Future<Map<String, dynamic>?> checkIfMaintenance() async {
    Map<String, dynamic>? maintenanceData;

    final docRef =
        FirebaseFirestore.instance.collection("config").doc("maintenance");

    await docRef.get().then((docSnapshot) {
      maintenanceData = docSnapshot.data();
    });

    return maintenanceData;
  }

// End config methods
}
