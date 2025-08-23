import 'package:flutter/material.dart';
import 'marketer_sidebar.dart';

class MarketerProfile extends StatelessWidget {
  const MarketerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marketer Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      // drawer: MarketerSidebar(onMenuItemTap: (route) {
      //   Navigator.pushNamed(context, route);
      // }),
      body: Center(
        child: Text("Marketer Profile Here!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
