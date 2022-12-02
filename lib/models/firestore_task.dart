class FirestoreTask {
  FirestoreTask(
      {required this.id,
      required this.title,
      this.description,
      required this.creationEpochTimestamp,
      this.todos,
      this.changelog});

  String id;
  String title;
  String? description;
  int creationEpochTimestamp;
  List<dynamic>? todos;
  List<dynamic>? changelog;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "creation_epoch_timestamp": creationEpochTimestamp,
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
        creationEpochTimestamp: DateTime.now().millisecondsSinceEpoch,
        todos: [],
        changelog: [],
      );
    }

    return FirestoreTask(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      creationEpochTimestamp: json["creation_epoch_timestamp"],
      todos: json["todos"],
      changelog: json["changelog"],
    );
  }
}
