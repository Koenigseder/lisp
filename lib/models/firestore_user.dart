class FirestoreUser {
  FirestoreUser({required this.name, this.tasks});

  String name;
  List<dynamic>? tasks;

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "tasks": tasks,
    };
  }

  static FirestoreUser fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FirestoreUser(
        name: "Default user",
        tasks: [],
      );
    }

    return FirestoreUser(
      name: json["name"],
      tasks: json["tasks"],
    );
  }
}
