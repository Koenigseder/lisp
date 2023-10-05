import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lisp/models/firestore_task.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/utils/snackbar.dart';

import '../utils/no_glow_behavior.dart';
import '../widgets/to_do_widget.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key, required this.task}) : super(key: key);

  final FirestoreTask? task;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _toDoController = TextEditingController();

  late FocusNode _titleFocus, _descriptionFocus, _toDoFocus;

  final formKey = GlobalKey<FormState>();

  List<dynamic> _todos = [];
  List<int> changedTaskIds = [];

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.task?.title ?? "";
    _descController.text = widget.task?.description ?? "";
    _todos = List.from(widget.task?.todos ?? []);

    _titleController.addListener(() {
      setState(() {});
    });

    _descController.addListener(() {
      setState(() {});
    });

    _titleFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _toDoFocus = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();

    _titleController.dispose();
    _descController.dispose();
    _toDoController.dispose();

    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _toDoFocus.dispose();
  }

  Future<void> _updateTaskInFirestore() async {
    if (widget.task == null) {
      return;
    } else {
      if (_titleController.text.trim() == widget.task?.title &&
          _descController.text.trim() == widget.task?.description) {
        return;
      }

      await _firestoreService.updateTask(data: {
        "id": widget.task?.id ?? "0",
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "todos": _todos,
        "changelog": FieldValue.arrayUnion([
          {
            "change": "overall_update_task",
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            "by": FirebaseAuth.instance.currentUser!.uid,
          }
        ]),
      });
    }
  }

  Future<void> _createNewTodo(Map<String, dynamic> newToDo) async {
    _todos.add(newToDo);

    await _firestoreService.updateTask(data: {
      "id": widget.task?.id ?? "0",
      "todos": FieldValue.arrayUnion([
        newToDo,
      ]),
      "changelog": FieldValue.arrayUnion([
        {
          "change": "create_todo",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "by": FirebaseAuth.instance.currentUser!.uid,
        },
      ]),
    });
  }

  Future<void> _updateToDo(
      Map<String, dynamic> updatedToDo, bool statusUpdated) async {
    final int index =
        _todos.indexWhere((todo) => todo["id"] == updatedToDo["id"]);
    _todos[index] = updatedToDo;

    await _firestoreService.updateTask(data: {
      "id": widget.task?.id ?? "0",
      "todos": _todos,
      "changelog": FieldValue.arrayUnion([
        {
          "change": statusUpdated ? "update_todo_status" : "update_todo_title",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "by": FirebaseAuth.instance.currentUser!.uid,
        },
      ]),
    });
  }

  Future<void> _deleteToDo(Map<String, dynamic> toDoToDelete) async {
    final int index =
        _todos.indexWhere((todo) => todo["id"] == toDoToDelete["id"]);
    _todos.removeAt(index);

    await _firestoreService.updateTask(data: {
      "id": widget.task?.id ?? "0",
      "todos": FieldValue.arrayRemove([
        toDoToDelete,
      ]),
      "changelog": FieldValue.arrayUnion([
        {
          "change": "delete_todo",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "by": FirebaseAuth.instance.currentUser!.uid,
        },
      ]),
    });
  }

  void _addRemoveTaskIdToChangedList(int taskId, String type) {
    if (type == "remove" && changedTaskIds.contains(taskId)) {
      changedTaskIds.remove(taskId);
    } else if (type == "add" && !changedTaskIds.contains(taskId)) {
      changedTaskIds.add(taskId);
    }
  }

  Future<void> _showMissingTitleDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Missing title"),
        content: const Text("Please provide at least a title!"),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text("Discard changes"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context);
              _titleFocus.requestFocus();
            },
            icon: const Icon(Icons.text_fields),
            label: const Text("Add title"),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnsavedChangesDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unsaved changes"),
        content: const Text("Please save all your changes or throw them away!"),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text("Discard changes"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context);
              _titleFocus.requestFocus();
            },
            icon: const Icon(Icons.cancel),
            label: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (formKey.currentState!.validate() && changedTaskIds.isEmpty) {
          _updateTaskInFirestore();
          return true;
        }

        if (!formKey.currentState!.validate()) {
          _showMissingTitleDialog();
        } else if (changedTaskIds.isNotEmpty) {
          _showUnsavedChangesDialog();
        }

        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: StreamBuilder<FirestoreTask>(
            stream: _firestoreService.getSingleTask(widget.task?.id),
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

              _todos = snapshot.data?.todos ?? [];

              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24.0,
                        bottom: 6.0,
                        right: 24.0,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (formKey.currentState!.validate() &&
                                  changedTaskIds.isEmpty) {
                                _updateTaskInFirestore();
                                Navigator.pop(context);
                                return;
                              }

                              if (!formKey.currentState!.validate()) {
                                _showMissingTitleDialog();
                              } else if (changedTaskIds.isNotEmpty) {
                                _showUnsavedChangesDialog();
                              }
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
                          Expanded(
                            child: TextFormField(
                              focusNode: _titleFocus,
                              controller: _titleController,
                              onFieldSubmitted: (_) =>
                                  _descriptionFocus.requestFocus(),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (taskTitle) => taskTitle?.trim() == ""
                                  ? "Please enter a display name"
                                  : null,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: "Enter task title",
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF211551),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.task?.id != null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "ID: ${widget.task?.id}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: widget.task?.id ?? ""));
                                Snackbar.showSnackBar(
                                    "ID copied to clipboard", Colors.green);
                              },
                              child: const Icon(
                                Icons.copy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12.0,
                      ),
                      child: TextField(
                        focusNode: _descriptionFocus,
                        keyboardType: TextInputType.text,
                        maxLines: null,
                        controller: _descController,
                        onSubmitted: (_) => _toDoFocus.requestFocus(),
                        decoration: const InputDecoration(
                          hintText: "Enter description for the task...",
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 24.0),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: NoGlowBehaviour(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 20.0,
                          ),
                          itemCount: snapshot.data?.todos?.length,
                          itemBuilder: (context, index) {
                            return TodoWidget(
                              key: Key(snapshot.data!.todos![index]["id"]
                                  .toString()),
                              todo: snapshot.data?.todos?[index],
                              updateToDo: _updateToDo,
                              deleteToDo: _deleteToDo,
                              addRemoveTaskIdToChangedList:
                                  _addRemoveTaskIdToChangedList,
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 20.0,
                            height: 20.0,
                            margin: const EdgeInsets.only(right: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(7.0),
                              border: Border.all(
                                  color: const Color(0xFF86829D), width: 1.5),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 60.0),
                              child: TextField(
                                focusNode: _toDoFocus,
                                controller: _toDoController,
                                onSubmitted: (String value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _createNewTodo({
                                        "id": snapshot.data!.todos!.isEmpty
                                            ? 1
                                            : snapshot.data!.todos!.last["id"] +
                                                1,
                                        "title": value,
                                        "done": false,
                                      });
                                      _toDoController.text = "";
                                      _toDoFocus.requestFocus();
                                    });
                                  }
                                },
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: "Enter ToDo item...",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
