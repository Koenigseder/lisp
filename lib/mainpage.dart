import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lisp/screens/home.dart';
import 'package:lisp/screens/settings.dart';
import 'package:lisp/services/firestore_service.dart';
import 'package:lisp/services/push_service.dart';
import 'package:lisp/services/storage_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final StorageService _storageService = StorageService();

  String profilePicturePath = "";

  static const List<Widget> _widgetOptions = [
    HomePage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateProfilePicturePath() {
    _storageService
        .getProfilePictureURL(FirebaseAuth.instance.currentUser!.uid)
        .then((value) {
      setState(() {
        profilePicturePath = value;
      });
    });
  }

  Future<void> getTaskIds(Stream<dynamic> user) async {
    await for (final props in user) {
    List<String> tasks = [];
      for (final task in props.tasks) {
        tasks.add(task["task_id"]);
      }

      subscribeToTopics(tasks);
    }
  }

  @override
  void initState() {
    super.initState();

    updateProfilePicturePath();

    final firestore = FirestoreService();
    getTaskIds(firestore.readUser());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: Colors.purple,
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12.0,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.network(
                  profilePicturePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: SvgPicture.string(
                        _storageService.getAvatarString(
                          FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
            label: "Settings",
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
