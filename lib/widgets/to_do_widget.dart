import 'dart:async';

import 'package:flutter/material.dart';

class TodoWidget extends StatefulWidget {
  const TodoWidget({
    Key? key,
    required this.todo,
    required this.updateToDo,
    required this.deleteToDo,
    required this.addRemoveTaskIdToChangedList,
  }) : super(key: key);

  final Map<String, dynamic> todo;
  final Function updateToDo;
  final Function deleteToDo;
  final Function addRemoveTaskIdToChangedList;

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  final TextEditingController _titleController = TextEditingController();

  bool textFieldValueChanged = false;

  Timer _scheduleTimer(int milliseconds, VoidCallback handleFunction) {
    return Timer(Duration(milliseconds: milliseconds), handleFunction);
  }

  void _updateToDo() {
    if (_titleController.text.isNotEmpty) {
      if (_titleController.text != widget.todo["title"]) {
        widget.todo["title"] = _titleController.text;
        widget.updateToDo(widget.todo, false);
      }

      setState(() {
        widget.addRemoveTaskIdToChangedList(
            widget.todo["id"], "remove");
        textFieldValueChanged = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.todo["title"];
  }

  @override
  void dispose() {
    super.dispose();

    _titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 25.0,
            height: 25.0,
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
                color: widget.todo["done"]
                    ? const Color(0xFF7349FE)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7.0),
                border: widget.todo["done"]
                    ? null
                    : Border.all(color: const Color(0xFF86829D), width: 1.5)),
            child: InkWell(
              onTap: () {
                setState(() {
                  widget.todo["done"] = !widget.todo["done"];
                  widget.updateToDo(widget.todo, true);
                });
              },
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.check,
                color: widget.todo["done"] ? Colors.white : Colors.transparent,
                size: 20.0,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: Key(widget.todo["id"].toString()),
              controller: _titleController,
              onEditingComplete: () {
                _updateToDo();
              },
              onChanged: (String value) {
                if (!textFieldValueChanged) {
                  setState(() {
                    widget.addRemoveTaskIdToChangedList(
                        widget.todo["id"], "add");
                    textFieldValueChanged = true;
                  });
                }
                _scheduleTimer(3000, _updateToDo);
              },
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: "Please enter a text...", border: InputBorder.none),
            ),
          ),
          InkWell(
            onTap: () {
              if (!textFieldValueChanged) {
                widget.deleteToDo(widget.todo);
              } else if (_titleController.text.isNotEmpty) {
                widget.todo["title"] = _titleController.text;
                widget.updateToDo(widget.todo, false);
                widget.addRemoveTaskIdToChangedList(
                    widget.todo["id"], "remove");
                textFieldValueChanged = false;
              }
            },
            customBorder: const CircleBorder(),
            child: Icon(
              !textFieldValueChanged ? Icons.delete : Icons.save,
              color: !textFieldValueChanged ? Colors.red : Colors.green,
            ),
          )
        ],
      ),
    );
  }
}
