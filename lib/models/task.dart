class Task {
  Task({this.id, required this.title, this.description});

  final int? id;
  final String title;
  final String? description;

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }
}

class TaskWithToDos {
  TaskWithToDos(
      {this.id,
      required this.title,
      this.description,
      this.countToDos,
      this.countToDosDone});

  final int? id;
  final String title;
  final String? description;
  final int? countToDos;
  final int? countToDosDone;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'countToDos': countToDos,
      'countToDosDone': countToDosDone
    };
  }
}
