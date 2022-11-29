class FirestoreTask {
  FirestoreTask(
      {required this.id,
      required this.title,
      this.description,
      this.todos,
      this.changelog});

  String id;
  String title;
  String? description;
  List<dynamic>? todos;
  List<dynamic>? changelog;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "todos": todos,
      "changelog": changelog,
    };
  }

  static FirestoreTask fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FirestoreTask(
        id: "0",
        title: "Default task",
        description: "Default description",
        todos: [],
        changelog: [],
      );
    }

    return FirestoreTask(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      todos: json["todos"],
      changelog: json["changelog"],
    );
  }
}
