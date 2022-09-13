import 'package:lisp/models/task.dart';
import 'package:lisp/models/todo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  Future<Database> database() async {
    return openDatabase(
      join(await getDatabasesPath(), 'todo.db'),
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, description TEXT)");
        await db.execute(
            "CREATE TABLE todo(id INTEGER PRIMARY KEY, taskId INTEGER, title TEXT, isDone INTEGER)");
      },
      version: 1,
    );
  }

  Future<int> createTask(Task task) async {
    int taskId = 0;
    Database db = await database();

    await db
        .insert('tasks', task.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace)
        .then((value) {
      taskId = value;
    });

    return taskId;
  }

  Future<void> updateTaskTitle(int id, String newTitle) async {
    Database db = await database();
    await db.rawUpdate("UPDATE tasks SET title = '$newTitle' WHERE id = '$id'");
  }

  Future<void> updateTaskDescription(int id, String newDescription) async {
    Database db = await database();
    await db.rawUpdate(
        "UPDATE tasks SET description = '$newDescription' WHERE id = '$id'");
  }

  Future<void> insertToDo(ToDo toDo) async {
    Database db = await database();

    await db.insert('todo', toDo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TaskWithToDos>> getTasks() async {
    Database db = await database();

    List<Map<String, dynamic>> taskMap = await db.rawQuery("""
      SELECT
        tasks.id,
	      tasks.title,
	      tasks.description,
	      COUNT(todo.id) AS countToDos,
	      COUNT(CASE WHEN todo.isDone = 1 THEN 1 END) AS countToDosDone
      FROM
	      tasks
      LEFT JOIN todo ON
	      tasks.id = todo.taskId
      GROUP BY
	      tasks.id;
      """);

    return List.generate(taskMap.length, (index) {
      return TaskWithToDos(
          id: taskMap[index]['id'],
          title: taskMap[index]['title'],
          description: taskMap[index]['description'],
          countToDos: taskMap[index]['countToDos'],
          countToDosDone: taskMap[index]['countToDosDone']);
    });
  }

  Future<List<ToDo>> getToDos(int taskId) async {
    Database db = await database();

    List<Map<String, dynamic>> toDoMap =
        await db.rawQuery("SELECT * FROM todo WHERE taskId = $taskId");

    return List.generate(toDoMap.length, (index) {
      return ToDo(
          id: toDoMap[index]['id'],
          taskId: toDoMap[index]['taskId'],
          title: toDoMap[index]['title'],
          isDone: toDoMap[index]['isDone']);
    });
  }

  Future<void> updateToDoDone(int id, int newIsDone) async {
    Database db = await database();
    await db
        .rawUpdate("UPDATE todo SET isDone = '$newIsDone' WHERE id = '$id'");
  }

  Future<void> updateToDoTitle(int id, String newTitle) async {
    Database db = await database();
    await db.rawUpdate("UPDATE todo SET title = '$newTitle' WHERE id = '$id'");
  }

  Future<void> deleteTask(int id) async {
    Database db = await database();
    await db.rawDelete("DELETE FROM tasks WHERE id = '$id'");
    await db.rawDelete("DELETE FROM todo WHERE taskId = '$id'");
  }

  Future<void> deleteToDo(int id) async {
    Database db = await database();
    await db.rawDelete("DELETE FROM todo WHERE id = '$id'");
  }
}
