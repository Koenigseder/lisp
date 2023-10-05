import 'package:flutter/material.dart';
import 'package:lisp/utils/no_glow_behavior.dart';

class TaskSettingsPage extends StatefulWidget {
  const TaskSettingsPage({super.key});

  @override
  State<TaskSettingsPage> createState() => _TaskSettingsPageState();
}

class _TaskSettingsPageState extends State<TaskSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                bottom: 6.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Icon(
                        Icons.keyboard_backspace,
                        size: 27.0,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "List settings",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              "Members",
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: NoGlowBehaviour(),
                child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return const Text(
                      "Test"
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
