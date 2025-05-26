import 'package:flutter/material.dart';
import 'marketer_sidebar.dart';

class MarketerClients extends StatelessWidget {
  const MarketerClients({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marketer Client", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer: MarketerSidebar(onMenuItemTap: (route) {
        Navigator.pushNamed(context, route);
      }),
      body: Center(
        child: Text("Marketer Client Here!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
