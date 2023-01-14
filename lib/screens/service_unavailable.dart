import 'package:flutter/material.dart';

class ServiceUnavailablePage extends StatefulWidget {
  const ServiceUnavailablePage({Key? key, required this.data}) : super(key: key);

  final Map<String, dynamic>? data;

  @override
  State<ServiceUnavailablePage> createState() => _ServiceUnavailablePageState();
}

class _ServiceUnavailablePageState extends State<ServiceUnavailablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Lisp is currently not available",
              style: TextStyle(
                fontSize: 24.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Reason: ${widget.data?["reason"] ?? ""}",
              ),
            ),
            Text(
              widget.data?["message"] ?? "",
            ),
          ],
        ),
      ),
    );
  }
}
