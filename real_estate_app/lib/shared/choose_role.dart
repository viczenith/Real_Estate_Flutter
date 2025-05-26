import 'package:flutter/material.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Your Role"), backgroundColor: Colors.blueAccent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Where do you want to go?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin-dashboard');
              },
              child: Text("Go to Admin Panel"),
            ),
            SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/client-dashboard');
              },
              child: Text("Go to Client Panel"),
            ),
            SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/marketer-dashboard');
              },
              child: Text("Go to Marketer Panel"),
            ),
          ],
        ),
      ),
    );
  }
}
