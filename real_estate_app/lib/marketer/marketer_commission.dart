import 'package:flutter/material.dart';
import 'marketer_sidebar.dart';

class MarketerCommission extends StatelessWidget {
  const MarketerCommission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marketer Commission", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer: MarketerSidebar(onMenuItemTap: (route) {
        Navigator.pushNamed(context, route);
      }),
      body: Center(
        child: Text("Marketer Commission Here!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
