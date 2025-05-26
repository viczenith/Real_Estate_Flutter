import 'package:flutter/material.dart';
import 'marketer_sidebar.dart';

class MarketerDashboard extends StatelessWidget {
  final String token; // Added token parameter
  const MarketerDashboard({required this.token, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer: MarketerSidebar(onMenuItemTap: (route) {
        Navigator.pushNamed(context, route);
      }),
      body: Center(
        child: Text("Marketer Dashboard Here!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
