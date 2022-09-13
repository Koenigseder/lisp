import 'package:flutter/material.dart';

class TodoWidget extends StatelessWidget {
  const TodoWidget(
      {Key? key,
      required this.toDoId,
      required this.text,
      required this.isDone,
      required this.updateToDoDone,
      required this.updateToDoTitle,
      required this.deleteToDo})
      : super(key: key);

  final int toDoId;
  final String text;
  final bool isDone;

  final Function updateToDoDone;
  final Function updateToDoTitle;
  final Function deleteToDo;

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
                color: isDone ? const Color(0xFF7349FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(7.0),
                border: isDone
                    ? null
                    : Border.all(color: const Color(0xFF86829D), width: 1.5)),
            child: InkWell(
              onTap: () {
                updateToDoDone(toDoId, isDone ? 1 : 0);
              },
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.check,
                color: isDone ? Colors.white : Colors.transparent,
                size: 20.0,
              ),
            ),
          ),
          Expanded(
              child: TextField(
            controller: TextEditingController()..text = text,
            onSubmitted: (String value) {
              if (value.isNotEmpty) {
                updateToDoTitle(toDoId, value);
              }
            },
            decoration: const InputDecoration(
                hintText: "Please enter a text...", border: InputBorder.none),
          )),
          InkWell(
            onTap: () {
              deleteToDo(toDoId);
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
