import 'package:flutter/material.dart';

class TodoWidget extends StatefulWidget {
  TodoWidget({
    Key? key,
    required this.todo,
    required this.updateToDo,
    required this.deleteToDo,
  }) : super(key: key);

  Map<String, dynamic> todo;
  final Function updateToDo;
  final Function deleteToDo;

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
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
              controller: TextEditingController()..text = widget.todo["title"],
              onChanged: (String value) {
                widget.todo["title"] = value;
                widget.updateToDo(widget.todo, false);
              },
              decoration: const InputDecoration(
                  hintText: "Please enter a text...", border: InputBorder.none),
            ),
          ),
          InkWell(
            onTap: () {
              widget.deleteToDo(widget.todo["id"]);
            },
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          )
        ],
      ),
    );
  }
}
