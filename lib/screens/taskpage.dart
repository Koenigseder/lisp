import 'package:flutter/material.dart';
import 'package:lisp/utils/database_helper.dart';
import 'package:lisp/models/task.dart';
import 'package:lisp/models/todo.dart';

import '../utils/no_glow_behavior.dart';
import '../widgets/to_do_widget.dart';

class Taskpage extends StatefulWidget {
  const Taskpage({Key? key, required this.task}) : super(key: key);

  final TaskWithToDos? task;

  @override
  State<Taskpage> createState() => _TaskpageState();
}

class _TaskpageState extends State<Taskpage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  int _taskId = 0;
  String _taskTitle = "";
  String _taskDescription = "";

  late FocusNode _titleFocus, _descriptionFocus, _toDoFocus;

  bool _contentVisible = false;

  @override
  void initState() {
    if (widget.task != null) {
      // Set visibility to true
      _contentVisible = true;

      _taskId = widget.task?.id ?? 0;
      _taskTitle = widget.task?.title ?? "";
      _taskDescription = widget.task?.description ?? "";
    }

    _titleFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _toDoFocus = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _toDoFocus.dispose();

    super.dispose();
  }

  void _updateToDoDone(int toDoId, int isDone) async {
    if (isDone == 0) {
      await _dbHelper.updateToDoDone(toDoId, 1);
    } else {
      await _dbHelper.updateToDoDone(toDoId, 0);
    }
    setState(() {});
  }

  void _updateToDoTitle(int toDoId, String newTitle) async {
    await _dbHelper.updateToDoTitle(toDoId, newTitle);
    setState(() {});
  }

  void _deleteToDo(int toDoId) async {
    if (toDoId != 0) {
      await _dbHelper.deleteToDo(toDoId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 6.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
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
                      child: TextField(
                        focusNode: _titleFocus,
                        onSubmitted: (value) async {
                          // Check if the field is not empty
                          if (value != "") {
                            // Check if the task is null
                            if (widget.task == null) {
                                Task newTask = Task(title: value);
                                _taskId = await _dbHelper.createTask(newTask);
                                setState(() {
                                   _contentVisible = true;
                                   _taskTitle = value;
                                });
                            } else {
                              await _dbHelper.updateTaskTitle(_taskId, value);
                            }
                            _descriptionFocus.requestFocus();
                          }
                        },
                    controller: TextEditingController()..text = _taskTitle,
                    decoration: const InputDecoration(
                      hintText: "Enter task title",
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF211551),
                        overflow: TextOverflow.ellipsis),
                  ))
                ],
              ),
            ),
            Visibility(
              visible: _contentVisible,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  focusNode: _descriptionFocus,
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  onSubmitted: (value) async {
                    if (value != "") {
                      if (_taskId != 0) {
                        await _dbHelper.updateTaskDescription(_taskId, value);
                        _taskDescription = value;
                      }
                    }
                    _toDoFocus.requestFocus();
                  },
                  controller: TextEditingController()..text = _taskDescription,
                  decoration: const InputDecoration(
                      hintText: "Enter description for the task...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.0)),
                ),
              ),
            ),
            Visibility(
              visible: _contentVisible,
              child: Expanded(
                child: FutureBuilder(
                  future: _dbHelper.getToDos(_taskId),
                  builder: (context, AsyncSnapshot<List<ToDo>> snapshot) {
                    Widget child = Container();
                    if (snapshot.hasData) {
                      if ((snapshot.data ?? []).isNotEmpty) {
                        child = ScrollConfiguration(
                          behavior: NoGlowBehaviour(),
                          child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              itemCount: snapshot.data?.length,
                              itemBuilder: (context, index) {
                                return TodoWidget(
                                  toDoId: snapshot.data?[index].id ?? 0,
                                  text: snapshot.data?[index].title ?? "",
                                  isDone: snapshot.data?[index].isDone == 0
                                      ? false
                                      : true,
                                  updateToDoDone: _updateToDoDone,
                                  updateToDoTitle: _updateToDoTitle,
                                  deleteToDo: _deleteToDo,
                                );
                              }),
                        );
                      }
                    }
                    return child;
                  },
                ),
              ),
            ),
            Visibility(
              visible: _contentVisible,
              child: Padding(
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
                              color: const Color(0xFF86829D), width: 1.5)),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(right: 60.0),
                      child: TextField(
                        focusNode: _toDoFocus,
                        controller: TextEditingController()..text = "",
                        onSubmitted: (value) async {
                          // Check if the field is not empty
                          if (value != "") {
                            // Check if the task is null
                            if (_taskId != 0) {
                              ToDo newToDo = ToDo(
                                  taskId: _taskId, title: value, isDone: 0);
                              await _dbHelper.insertToDo(newToDo);
                              setState(() {});
                              _toDoFocus.requestFocus();
                            }
                          }
                        },
                        decoration: const InputDecoration(
                            hintText: "Enter ToDo item...",
                            border: InputBorder.none),
                      ),
                    )),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _taskId != 0 ? Offset.zero : const Offset(3, 0),
        child: FloatingActionButton(
          onPressed: () async {
            if (_taskId != 0) {
              _dbHelper.deleteTask(_taskId);
              Navigator.pop(context);
            }
          },
          child: Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: const Color(0xFFFE3577),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.delete_forever,
              color: Colors.white,
              size: 40.0,
            ),
          ),
        ),
      ),
    );
  }
}
