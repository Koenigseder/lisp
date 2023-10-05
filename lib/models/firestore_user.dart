class FirestoreUser {
  FirestoreUser({required this.name, this.tasks, this.fcm});

  String name;
  List<dynamic>? tasks;
  List<dynamic>? fcm;

  Map<String, dynamic> toJson() {
    return {"name": name, "tasks": tasks, "fcm": fcm};
  }

  static FirestoreUser fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FirestoreUser(
        name: "Default user",
        tasks: [],
        fcm: [],
      );
    }

    return FirestoreUser(
      name: json["name"],
      tasks: json["tasks"],
      fcm: json["fcm"],
    );
  }
}
