import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lisp/models/firestore_task.dart';
import 'package:lisp/utils/firestore_service.dart';
import 'package:lisp/utils/utils.dart';

import '../utils/no_glow_behavior.dart';
import '../widgets/to_do_widget.dart';

class Taskpage extends StatefulWidget {
  const Taskpage({Key? key, required this.task}) : super(key: key);

  final FirestoreTask? task;

  @override
  State<Taskpage> createState() => _TaskpageState();
}

class _TaskpageState extends State<Taskpage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _toDoController = TextEditingController();

  late FocusNode _titleFocus, _descriptionFocus, _toDoFocus;

  final formKey = GlobalKey<FormState>();

  List<dynamic> _todos = [];
  List<dynamic> _changelog = [];

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.task?.title ?? "";
    _descController.text = widget.task?.description ?? "";
    _todos = List.from(widget.task?.todos ?? []);
    _changelog = List.from(widget.task?.changelog ?? []);

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

  Future _updateTaskInFirestore() async {
    if (widget.task == null) {
      String taskId = await _firestoreService.createTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        todos: _todos,
      );
      await _firestoreService.updateUser(data: {
        "tasks": FieldValue.arrayUnion([
          {
            "role": "ADMIN",
            "task_id": taskId,
          }
        ])
      });
    } else {
      await _firestoreService.updateTask(data: {
        "id": widget.task?.id ?? "0",
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "todos": _todos,
        "changelog": _changelog,
      });
    }
  }

  void _updateToDo(Map<String, dynamic> newToDo, bool updateDone) async {
    final int index = _todos.indexWhere((todo) => todo["id"] == newToDo["id"]);
    _todos[index] = newToDo;

    if (updateDone) {
      await _firestoreService.updateTask(data: {
        "id": widget.task?.id ?? "0",
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "todos": _todos,
        "changelog": _changelog,
      });
    }
  }

  void _deleteToDo(int toDoId) {
    setState(() {
      final int index = _todos.indexWhere((todo) => todo["id"] == toDoId);
      _todos.removeAt(index);
    });
  }

  Future _showMissingTitleDialog() {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (formKey.currentState?.validate() ?? false) {
          _updateTaskInFirestore();
          return true;
        }
        _showMissingTitleDialog();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    bottom: 6.0,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (formKey.currentState?.validate() ?? false) {
                            _updateTaskInFirestore();
                            Navigator.pop(context);
                            return;
                          }
                          _showMissingTitleDialog();
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (taskTitle) => taskTitle?.trim() == ""
                              ? "Please enter a display name"
                              : null,
                          decoration: const InputDecoration(
                            hintText: "Enter task title",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 26.0,
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
                          child: const Icon(
                            Icons.copy,
                          ),
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: widget.task?.id ?? ""));
                            Utils.showSnackBar(
                                "ID copied to clipboard", Colors.green);
                          },
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
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
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        return TodoWidget(
                          todo: _todos[index],
                          updateToDo: _updateToDo,
                          deleteToDo: _deleteToDo,
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
                                  _todos.add({
                                    "id": _todos.isNotEmpty
                                        ? _todos.last["id"] + 1
                                        : 1,
                                    "title": value,
                                    "done": false,
                                  });
                                  _toDoController.text = "";
                                  _toDoFocus.requestFocus();
                                });
                              }
                            },
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
          ),
        ),
      ),
    );
  }
}
