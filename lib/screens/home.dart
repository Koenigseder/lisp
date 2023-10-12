import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lisp/models/firestore_task.dart';
import 'package:lisp/models/firestore_user.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/services/push_service.dart';

import 'task.dart';
import '../utils/no_glow_behavior.dart';
import '../widgets/task_card_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  List<String> taskIds = [];

  List<int> countToDos(FirestoreTask task) {
    int toDos = task.todos?.length ?? 0;
    int toDosDone = task.todos?.where((element) => element["done"]).length ?? 0;

    return [toDos, toDosDone];
  }

  List<String> getTaskIds(List<dynamic>? tasks) {
    if (tasks == null) {
      taskIds = [];
      return [];
    }

    List<String> ids = tasks.map((e) => e["task_id"].toString()).toList();
    taskIds = ids;

    _firestoreService.deleteUnavailableTasks(ids);

    return ids;
  }

  Future _openContextDialog(String taskId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What to do want to do?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _openLeaveDialog(taskId);
              },
              icon: const Icon(Icons.directions_run),
              label: const Text("Leave this list"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _openDeleteDialog(taskId);
              },
              icon: const Icon(Icons.delete),
              label: const Text("Delete this list"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _openLeaveDialog(String taskId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave list"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to leave this list?",
              textAlign: TextAlign.center,
            ),
            Text(
              "With this action you will no longer have access to this list!\n"
              "You can rejoin the list with the ID.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.directions_run),
            label: const Text("Leave"),
            onPressed: () async {
              await _firestoreService.updateUser(data: {
                "tasks": FieldValue.arrayRemove([
                  {
                    "role": "ADMIN",
                    "task_id": taskId,
                  }
                ])
              });

              await unsubscribeFromTopic(taskId);

              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future _openDeleteDialog(String taskId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete list"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to delete this list?",
              textAlign: TextAlign.center,
            ),
            Text(
              "This will delete the entire list for every user!\n"
              "This action cannot be undone!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text("Delete"),
            onPressed: () async {
              await _firestoreService.deleteDoc(
                  collectionId: "tasks", docId: taskId);
              setState(() {
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future _openAddDecisionDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What to do want to do?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            taskIds.length < 10
                ? Container()
                : const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "You can only add 10 lists at the moment 😢",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ElevatedButton.icon(
              onPressed: taskIds.length < 10
                  ? () {
                      _openAddNewListDialog();
                    }
                  : null,
              icon: const Icon(Icons.list_rounded),
              label: const Text("Create a new list"),
            ),
            ElevatedButton.icon(
              onPressed: taskIds.length < 10
                  ? () {
                      _openAddListDialog();
                    }
                  : null,
              icon: const Icon(Icons.person_add),
              label: const Text("Join a list"),
            ),
          ],
        ),
      ),
    );
  }

  Future _openAddListDialog() {
    _idController.text = "";
    final formKey = GlobalKey<FormState>();
    bool taskExists = true;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join a new list"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the ID of the list you want to join:"),
              TextFormField(
                  controller: _idController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "List ID",
                  ),
                  validator: (value) {
                    if (value?.trim() == "") return "Please provide an ID";
                    if (!taskExists) {
                      return "Task could not be found with this ID";
                    }
                    return null;
                  })
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add"),
            onPressed: () async {
              taskExists = _idController.text.trim() != ""
                  ? await _firestoreService
                      .checkIfTaskExists(_idController.text.trim())
                  : false;
              if (taskExists) {
                await _firestoreService.updateUser(data: {
                  "tasks": FieldValue.arrayUnion([
                    {
                      "role": "ADMIN",
                      "task_id": _idController.text.trim(),
                    }
                  ])
                });
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                formKey.currentState!.validate();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future _openAddNewListDialog() {
    _titleController.text = "";
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create a new list"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter a new title:"),
              TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "List title",
                  ),
                  validator: (value) {
                    if (value?.trim() == "") return "Please provide an title";
                    return null;
                  })
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Create"),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                String taskId = await _firestoreService.createTask(
                    title: _titleController.text.trim(),
                    description: "",
                    todos: [],
                    creationEpochTimestamp:
                        DateTime.now().millisecondsSinceEpoch,
                    changelog: [
                      {
                        "change": "create_task",
                        "timestamp": DateTime.now().millisecondsSinceEpoch,
                        "by": FirebaseAuth.instance.currentUser!.uid,
                      },
                    ]);

                await _firestoreService.updateUser(data: {
                  "tasks": FieldValue.arrayUnion([
                    {
                      "role": "ADMIN",
                      "task_id": taskId,
                    }
                  ])
                });

                if (!mounted) return;

                FirestoreTask newTask = FirestoreTask(
                  id: taskId,
                  title: _titleController.text.trim(),
                  creationEpochTimestamp: DateTime.now().millisecondsSinceEpoch,
                );

                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskPage(task: newTask),
                  ),
                );
              } else {
                formKey.currentState!.validate();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
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
                if (kDebugMode) {
                  print(snapshot.error);
                }

                return const Text(
                    "Something went wrong! Try resetting the app... 😥");
              }
              if (!snapshot.hasData) {
                return Container();
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                color: const Color(0xFFF6F6F6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        top: 32.0,
                        bottom: 32.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Image(
                            image: AssetImage(
                              'assets/images/logo.png',
                            ),
                            width: 80.0,
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                "Welcome ${snapshot.data?.name}!",
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<FirestoreTask>>(
                        stream: _firestoreService
                            .getTasks(getTaskIds(snapshot.data?.tasks)),
                        key: Key("${Random().nextDouble()}"),
                        builder: (context, snapshot) {
                          Widget child = Container();
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) return child;
                          if ((snapshot.data ?? []).isNotEmpty) {
                            child = ScrollConfiguration(
                              behavior: NoGlowBehaviour(),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 60.0),
                                itemCount: snapshot.data?.length,
                                itemBuilder: (context, index) {
                                  FirestoreTask task = snapshot.data![index];
                                  List<int> toDoInformation = countToDos(task);
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskPage(
                                            task: task,
                                          ),
                                        ),
                                      ).then((value) {
                                        setState(() {});
                                      });
                                    },
                                    onLongPress: () {
                                      _openContextDialog(task.id);
                                    },
                                    child: TaskCardWidget(
                                      key: Key(task.id),
                                      title: task.title,
                                      description: task.description,
                                      toDos: toDoInformation[0],
                                      toDosDone: toDoInformation[1],
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            child = const Padding(
                              padding: EdgeInsets.only(bottom: 150.0),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image(
                                      width: 200.0,
                                      image:
                                          AssetImage("assets/images/task1.png"),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10.0),
                                      child: Image(
                                        width: 200.0,
                                        image: AssetImage(
                                            "assets/images/task2.png"),
                                      ),
                                    ),
                                    Text(
                                      "So far there are no lists",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                        height: 2.0,
                                      ),
                                    ),
                                    Text(
                                      "Start by creating or joining one in the right bottom corner",
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }
                          return child;
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: Offset.zero,
        child: FloatingActionButton(
          onPressed: () {
            _openAddDecisionDialog();
          },
          child: Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7349FE), Color(0xFF643FDB)],
                begin: Alignment(0.0, -1.0),
                end: Alignment(0.0, 1.0),
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 40.0,
            ),
          ),
        ),
      ),
    );
  }
}
