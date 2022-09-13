import 'package:flutter/material.dart';
import 'package:lisp/models/task.dart';

import '../screens/taskpage.dart';
import '../utils/database_helper.dart';
import '../utils/no_glow_behavior.dart';
import 'task_card_widget.dart';

class TaskListWidget extends StatefulWidget {
  const TaskListWidget({Key? key}) : super(key: key);

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            color: const Color(0xFFF6F6F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 32.0, bottom: 32.0),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Image(
                        image: AssetImage(
                          'assets/images/logo.png',
                        ),
                        width: 80.0,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Welcome back to Lisp!",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _dbHelper.getTasks(),
                    builder:
                        (context, AsyncSnapshot<List<TaskWithToDos>> snapshot) {
                      Widget child = Container();
                      if (snapshot.hasData) {
                        if ((snapshot.data ?? []).isNotEmpty) {
                          child = ScrollConfiguration(
                            behavior: NoGlowBehaviour(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 60.0),
                              itemCount: snapshot.data?.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Taskpage(
                                                task: snapshot.data?[index])))
                                        .then((value) {
                                          setState(() {});
                                        });
                                    },
                                  child: TaskCardWidget(
                                    title: snapshot.data?[index].title,
                                    description:
                                    snapshot.data?[index].description,
                                    toDos: snapshot.data?[index].countToDos,
                                    toDosDone:
                                    snapshot.data?[index].countToDosDone,
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          child = Padding(
                            padding: const EdgeInsets.only(bottom: 150.0),
                            child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Image(
                                        width: 200.0,
                                        image: AssetImage("assets/images/task1.png")),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10.0),
                                      child: Image(
                                          width: 200.0,
                                          image:
                                          AssetImage("assets/images/task2.png")),
                                    ),
                                    Text(
                                      "So far there are no tasks",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0,
                                          height: 2.0),
                                    ),
                                    Text(
                                        "Start by creating one in the right bottom corner")
                                  ],
                                )),
                          );
                        }
                      }
                      return child;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Taskpage(task: null)))
              .then((value) {
            setState(() {});
          });
        },
        child: Container(
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7349FE), Color(0xFF643FDB)],
                  begin: Alignment(0.0, -1.0),
                  end: Alignment(0.0, 1.0)),
              borderRadius: BorderRadius.circular(20.0)),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 40.0,
          ),
        ),
      ),
    );
  }
}
