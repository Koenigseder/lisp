import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lisp/screens/home.dart';
import 'package:lisp/screens/settings.dart';
import 'package:lisp/services/storage_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final StorageService _storageService = StorageService();

  static const List<Widget> _widgetOptions = [
    HomePage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                  _storageService.getProfilePictureURL(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
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
