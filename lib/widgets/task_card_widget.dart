import 'package:flutter/material.dart';

class TaskCardWidget extends StatelessWidget {
  const TaskCardWidget(
      {Key? key, this.title, this.description, this.toDos, this.toDosDone})
      : super(key: key);

  final String? title;
  final String? description;
  final int? toDos;
  final int? toDosDone;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title ?? "(Unnamed task)",
                      style: const TextStyle(
                          color: Color(0xFF211551),
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold)),
                ),
                Visibility(
                    visible: toDos! > 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        height: 40.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: CircularProgressIndicator(
                                value: toDosDone! / toDos!,
                                color: toDosDone! / toDos! < 0.5
                                    ? Colors.red
                                    : toDosDone! / toDos! == 1
                                        ? Colors.green
                                        : Colors.orangeAccent,
                                backgroundColor: toDosDone! / toDos! == 0
                                    ? const Color(0xFFFDA0A0)
                                    : Colors.white,
                              ),
                            ),
                            Center(
                              child: toDosDone! / toDos! != 1
                                  ? Text("$toDosDone / $toDos")
                                  : const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                            )
                          ],
                        ),
                      ),
                    ))
              ],
            ),
            Visibility(
              visible: description != null,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  description ?? "(No description provided)",
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF86829D), height: 1.5),
                ),
              ),
            ),
          ],
        ));
  }
}
